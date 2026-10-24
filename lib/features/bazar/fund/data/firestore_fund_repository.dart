import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/core/firebase/firestore_guard.dart';
import 'package:family_hub/core/firebase/firestore_paths.dart';
import 'package:family_hub/core/firebase/query_limits.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/features/bazar/fund/data/fund_mappers.dart';
import 'package:family_hub/features/bazar/fund/data/month_closing_mappers.dart';
import 'package:family_hub/features/bazar/fund/domain/fund_repository.dart';
import 'package:family_hub/features/bazar/fund/domain/fund_transaction.dart';
import 'package:family_hub/features/bazar/fund/domain/month_closing.dart';

/// Read-only Firestore implementation of the fund ledger port.
///
/// The contribution/opening/close/reopen write methods arrive with P2-19…P2-21.
class FirestoreFundRepository implements FundRepository {
  FirestoreFundRepository([this._firestore]);

  final FirebaseFirestore? _firestore;

  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

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

  List<FundTransaction> _toTransactions(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) => <FundTransaction>[
    for (final document in snapshot.docs)
      FundMappers.fundTxFromMap(document.id, document.data()),
  ];
}
