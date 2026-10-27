import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:family_hub/core/audit/audit_event.dart';
import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/core/firebase/audit_writer.dart';
import 'package:family_hub/core/firebase/base_mapper.dart';
import 'package:family_hub/core/firebase/firestore_guard.dart';
import 'package:family_hub/core/firebase/firestore_paths.dart';
import 'package:family_hub/core/firebase/tx_runner.dart';
import 'package:family_hub/features/bazar/advances/data/advance_mappers.dart';
import 'package:family_hub/features/bazar/advances/domain/advance_repository.dart';
import 'package:family_hub/features/bazar/advances/domain/member_advance.dart';
import 'package:family_hub/features/bazar/advances/domain/settlement.dart';
import 'package:family_hub/features/bazar/advances/domain/settlement_plan.dart';
import 'package:family_hub/features/bazar/fund/data/fund_mappers.dart';

/// Firestore implementation of the advance/settlement port.
///
/// `commitSettlement` is a money-integrity write (rule 26): it probes the
/// server, reads the advance, and stages the settlement, the `stl_` ledger row,
/// the advance update and the log entry in ONE batch.
class FirestoreAdvanceRepository implements AdvanceRepository {
  FirestoreAdvanceRepository({TxRunner? tx, FirebaseFirestore? firestore})
    : _tx = tx ?? FirestoreTxRunner(),
      _firestore = firestore;

  final TxRunner _tx;
  final FirebaseFirestore? _firestore;

  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  @override
  Future<Result<SettlementPlan>> commitSettlement(
    String familyId, {
    required String advanceId,
    required Result<SettlementPlan> Function(MemberAdvance? current) build,
    required AuditEvent event,
  }) => guardWrite(
    probe: serverProbeFor(_db, event.actorId),
    () async {
      final snapshot = await _db
          .doc(FirestorePaths.memberAdvanceDoc(familyId, advanceId))
          .get(const GetOptions(source: Source.server));
      final data = snapshot.data();
      final current = snapshot.exists && data != null
          ? AdvanceMappers.advanceFromMap(advanceId, data)
          : null;
      // A failure from `build` (overpayment, voided, missing) writes nothing.
      final plan = build(current);
      final failure = plan.failureOrNull;
      if (failure != null) return Failure<SettlementPlan>(failure);
      final settlement = plan.valueOrNull!;

      await _tx.runBatch((batch) {
        batch.set(
          FirestorePaths.settlementDoc(familyId, settlement.settlement.id),
          AdvanceMappers.settlementToMap(
            settlement.settlement,
            BaseDocumentMetadata(
              createdAt: event.at,
              createdBy: event.actorId,
              updatedAt: event.at,
              updatedBy: event.actorId,
            ),
          ),
        );
        final row = settlement.reimbursement;
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
        // Only the settlement progress changes on the advance.
        batch.update(
          FirestorePaths.memberAdvanceDoc(familyId, advanceId),
          AdvanceMappers.advanceChangeMap(
            settlement.advanceAfter,
            actorUid: event.actorId,
            now: event.at,
          ),
        );
        AuditWriter.write(batch, familyId, event);
      });
      return Success<SettlementPlan>(settlement);
    },
  );

  @override
  Stream<List<MemberAdvance>> watchOpenAdvances(
    String familyId, {
    String? memberId,
  }) {
    var query = _db.collection(FirestorePaths.memberAdvances(familyId)).where(
      'status',
      whereIn: <String>[AdvanceStatus.pending.name, AdvanceStatus.partial.name],
    );
    if (memberId != null) {
      query = query.where('memberId', isEqualTo: memberId);
    }
    return query
        .orderBy('dateKey', descending: true)
        .limit(100)
        .snapshots()
        .map(
          (snapshot) => <MemberAdvance>[
            for (final document in snapshot.docs)
              AdvanceMappers.advanceFromMap(document.id, document.data()),
          ],
        );
  }

  @override
  Future<Result<MemberAdvance?>> getAdvance(
    String familyId,
    String expenseId,
  ) => guardFirestore(() async {
    final snapshot = await _db
        .doc(FirestorePaths.memberAdvanceDoc(familyId, expenseId))
        .get();
    if (!snapshot.exists) return null;
    return AdvanceMappers.advanceFromMap(expenseId, snapshot.data()!);
  });

  @override
  Stream<List<Settlement>> watchSettlements(
    String familyId, {
    String? advanceId,
  }) {
    var query = _db
        .collection(FirestorePaths.settlements(familyId))
        .where('advanceId', isEqualTo: advanceId ?? '')
        .orderBy('dateKey', descending: true)
        .limit(50);
    if (advanceId == null) {
      query = _db
          .collection(FirestorePaths.settlements(familyId))
          .orderBy('dateKey', descending: true)
          .limit(50);
    }
    return query.snapshots().map(
      (snapshot) => <Settlement>[
        for (final document in snapshot.docs)
          AdvanceMappers.settlementFromMap(document.id, document.data()),
      ],
    );
  }
}
