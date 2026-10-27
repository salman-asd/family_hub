import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:family_hub/core/audit/audit_event.dart';
import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/core/firebase/audit_writer.dart';
import 'package:family_hub/core/firebase/base_mapper.dart';
import 'package:family_hub/core/firebase/firestore_guard.dart';
import 'package:family_hub/core/firebase/firestore_paths.dart';
import 'package:family_hub/core/firebase/query_limits.dart';
import 'package:family_hub/core/firebase/tx_runner.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/core/utils/money.dart';
import 'package:family_hub/features/bazar/fund/data/fund_mappers.dart';
import 'package:family_hub/features/bazar/fund/data/month_closing_mappers.dart';
import 'package:family_hub/features/bazar/fund/domain/fund_repository.dart';
import 'package:family_hub/features/bazar/fund/domain/fund_transaction.dart';
import 'package:family_hub/features/bazar/fund/domain/month_closing.dart';
import 'package:family_hub/features/bazar/fund/domain/month_plans.dart';

/// Firestore implementation of the fund ledger port.
///
/// Reads are live queries over the ledger window.  The two writes (close and
/// reopen, P2-21) are ONE batch each and need the server (rule 26): the
/// closing balance comes from a server read taken just before the batch, so a
/// queued offline would close a month from an unknown balance.
class FirestoreFundRepository
    implements FundRepository, ExistingOpeningLedger {
  FirestoreFundRepository({this._tx, this._firestore});

  final TxRunner? _tx;
  final FirebaseFirestore? _firestore;

  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  TxRunner get _runner => _tx ?? FirestoreTxRunner();

  @override
  Stream<List<FundTransaction>> watchTransactionsFrom(
    String familyId,
    MonthKey from,
  ) => _db
      .collection(FirestorePaths.fundTransactions(familyId))
      .where('monthKey', isGreaterThanOrEqualTo: from.toString())
      .orderBy('monthKey')
      .orderBy('dateKey', descending: true)
      .limit(kMaxListenerDocs)
      .snapshots()
      .map(_toTransactions);

  @override
  Future<Result<List<FundTransaction>>> getMonthTransactions(
    String familyId,
    MonthKey month,
  ) => guardFirestore(() async {
    final snapshot = await _db
        .collection(FirestorePaths.fundTransactions(familyId))
        .where('monthKey', isEqualTo: month.toString())
        .orderBy('dateKey', descending: true)
        .limit(kMaxListenerDocs)
        .get();
    return _toTransactions(snapshot);
  });

  @override
  Future<Result<List<FundTransaction>>> getTransactionsForRef(
    String familyId,
    String refId,
  ) => guardFirestore(() async {
    final snapshot = await _db
        .collection(FirestorePaths.fundTransactions(familyId))
        .where('refId', isEqualTo: refId)
        .limit(20)
        .get();
    final rows = _toTransactions(snapshot)
      ..sort((a, b) {
        final byDate = a.dateKey.compareTo(b.dateKey);
        return byDate != 0 ? byDate : a.id.compareTo(b.id);
      });
    return rows;
  });

  @override
  Stream<List<MonthClosing>> watchClosings(String familyId) => _db
      .collection(FirestorePaths.monthClosings(familyId))
      .orderBy('monthKey', descending: true)
      .limit(24)
      .snapshots()
      .map(
        (snapshot) => <MonthClosing>[
          for (final document in snapshot.docs)
            MonthClosingMappers.closingFromMap(document.id, document.data()),
        ],
      );

  @override
  Future<Result<MonthClosing?>> getClosing(String familyId, MonthKey month) =>
      guardFirestore(() async {
        final id = month.toString();
        final snapshot = await _db
            .doc(FirestorePaths.monthClosingDoc(familyId, id))
            .get();
        if (!snapshot.exists) return null;
        return MonthClosingMappers.closingFromMap(id, snapshot.data()!);
      });

  @override
  Future<Result<Money?>> getOpeningAmount(
    String familyId,
    MonthKey month,
  ) => guardFirestore<Money?>(() async {
    // An exact-id read of `open_<yyyy-MM>`, the row `CloseMonth` may correct.
    final snapshot = await _db
        .doc(FirestorePaths.fundTransactionDoc(familyId, 'open_$month'))
        .get(const GetOptions(source: Source.server));
    final data = snapshot.data();
    if (!snapshot.exists || data == null) return null;
    final amount = data['amountPaisa'];
    return amount is num ? Money.paisa(amount.toInt()) : null;
  });

  @override
  Future<Result<List<FundTransaction>>> getTransactionsFromServer(
    String familyId,
    MonthKey from,
  ) => guardFirestore(() async {
    final snapshot = await _db
        .collection(FirestorePaths.fundTransactions(familyId))
        .where('monthKey', isGreaterThanOrEqualTo: from.toString())
        .orderBy('monthKey')
        .orderBy('dateKey')
        .limit(kMaxListenerDocs)
        .get(const GetOptions(source: Source.server));
    return _toTransactions(snapshot);
  });

  @override
  Future<Result<void>> commitClose(
    String familyId,
    MonthClosePlan plan,
    AuditEvent event,
  ) => guardWrite(
    probe: serverProbeFor(_db, event.actorId),
    () => _runner.runBatch((batch) {
      _stageClosing(batch, familyId, plan.closing, event);
      for (final row in <FundTransaction?>[
        plan.nextOpening,
        plan.nextAdjustment,
      ]) {
        if (row == null) continue;
        batch.set(
          FirestorePaths.fundTransactionDoc(familyId, row.id),
          FundMappers.fundTxToMap(
            row,
            BaseDocumentMetadata(
              createdAt: row.createdAt,
              createdBy: row.createdBy,
              updatedAt: event.at,
              updatedBy: event.actorId,
            ),
          ),
        );
      }
      AuditWriter.write(batch, familyId, event);
    }),
  );

  @override
  Future<Result<void>> commitReopen(
    String familyId,
    MonthReopenPlan plan,
    AuditEvent event,
  ) => guardWrite(
    probe: serverProbeFor(_db, event.actorId),
    () => _runner.runBatch((batch) {
      _stageClosing(batch, familyId, plan.reopened, event);
      AuditWriter.write(batch, familyId, event);
    }),
  );

  /// The closing document keeps its original author when it was closed before.
  void _stageClosing(
    BatchContext batch,
    String familyId,
    MonthClosing closing,
    AuditEvent event,
  ) {
    batch.set(
      FirestorePaths.monthClosingDoc(familyId, closing.monthKey.toString()),
      MonthClosingMappers.closingToMap(
        closing,
        BaseDocumentMetadata(
          createdAt: closing.closedAt ?? event.at,
          createdBy: closing.closedBy ?? event.actorId,
          updatedAt: event.at,
          updatedBy: event.actorId,
        ),
      ),
      merge: true,
    );
  }

  List<FundTransaction> _toTransactions(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) => <FundTransaction>[
    for (final document in snapshot.docs)
      FundMappers.fundTxFromMap(document.id, document.data()),
  ];
}
