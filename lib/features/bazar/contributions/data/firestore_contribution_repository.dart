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
import 'package:family_hub/features/bazar/contributions/data/contribution_mappers.dart';
import 'package:family_hub/features/bazar/contributions/data/contribution_write_stager.dart';
import 'package:family_hub/features/bazar/contributions/domain/contribution.dart';
import 'package:family_hub/features/bazar/contributions/domain/contribution_repository.dart';
import 'package:family_hub/features/bazar/contributions/domain/contribution_write_plans.dart';
import 'package:family_hub/features/bazar/fund/domain/fund_transaction.dart';
import 'package:family_hub/features/bazar/settings/data/bazar_settings_mappers.dart';
import 'package:family_hub/features/bazar/settings/domain/bazar_settings.dart';

/// Firestore implementation of [ContributionRepository].
///
/// Every write is ONE `runBatch` with its audit entry (`AuditWriter`).
/// Everyday writes (plans, a recorded or requested contribution, a member's
/// edit/cancel/change request) have no server probe, so they queue offline;
/// decisions, voids and the opening balance probe the server first (rule 26).
/// A changed contribution is written as the WHOLE document (`set`), so a
/// removed `pendingChange` really disappears; the rules compare it with the
/// stored one field by field.
class FirestoreContributionRepository implements ContributionRepository {
  FirestoreContributionRepository({
    required this._tx,
    this._firestore,
  });

  final TxRunner _tx;
  final FirebaseFirestore? _firestore;

  static const ContributionWriteStager _stager = ContributionWriteStager();

  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  @override
  Stream<List<ContributionPlan>> watchPlans(
    String familyId,
    MonthKey month, {
    String? memberId,
  }) => _monthQuery(
    FirestorePaths.contributionPlans(familyId),
    month,
    memberId,
  ).snapshots().map((s) => _plans(s));

  @override
  Stream<List<Contribution>> watchContributions(
    String familyId,
    MonthKey month, {
    String? memberId,
  }) => _monthQuery(
    FirestorePaths.contributions(familyId),
    month,
    memberId,
  ).snapshots().map((s) => _contributions(s));

  @override
  Future<Result<List<ContributionPlan>>> getPlans(
    String familyId,
    MonthKey month,
  ) => guardFirestore(() async {
    final snapshot = await _monthQuery(
      FirestorePaths.contributionPlans(familyId),
      month,
      null,
    ).get();
    return _plans(snapshot);
  });

  @override
  Future<Result<Contribution?>> getContribution(
    String familyId,
    String id, {
    bool fresh = false,
  }) => guardFirestore<Contribution?>(() async {
    final snapshot = await _db
        .doc(FirestorePaths.contributionDoc(familyId, id))
        .get(fresh ? const GetOptions(source: Source.server) : null);
    final data = snapshot.data();
    if (!snapshot.exists || data == null) return null;
    return ContributionMappers.fromMap(id, data);
  });

  @override
  Future<Result<void>> savePlans(
    String familyId,
    List<ContributionPlan> plans,
    AuditEvent event,
  ) => guardWrite(
    () => _tx.runBatch((batch) {
      for (final plan in plans) {
        batch.set(
          FirestorePaths.contributionPlanDoc(familyId, plan.id),
          ContributionMappers.planToMap(
            plan,
            BaseDocumentMetadata(
              createdAt: event.at,
              createdBy: event.actorId,
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
  Future<Result<void>> commitContribution(
    String familyId,
    ContributionWritePlan plan,
    AuditEvent event,
  ) => guardWrite(
    () => _tx.runBatch((batch) {
      _stager.contribution(batch, familyId, plan.contribution, event);
      _stager.fundRows(batch, familyId, <FundTransaction?>[plan.fundTx], event);
      AuditWriter.write(batch, familyId, event);
    }),
  );

  @override
  Future<Result<void>> saveContribution(
    String familyId,
    Contribution contribution,
    AuditEvent event,
  ) => guardWrite(
    () => _tx.runBatch((batch) {
      _stager.contribution(batch, familyId, contribution, event);
      AuditWriter.write(batch, familyId, event);
    }),
  );

  @override
  Future<Result<void>> commitDecision(
    String familyId,
    ContributionDecisionPlan plan,
    AuditEvent event,
  ) => guardWrite(
    probe: serverProbeFor(_db, event.actorId),
    () => _tx.runBatch((batch) {
      _stager.contribution(batch, familyId, plan.updated, event);
      _stager.fundRows(batch, familyId, <FundTransaction?>[
        plan.fundTx,
        ...plan.adjustments,
      ], event);
      AuditWriter.write(batch, familyId, event);
    }),
  );

  @override
  Future<Result<void>> commitVoid(
    String familyId,
    ContributionVoidPlan plan,
    AuditEvent event,
  ) => guardWrite(
    probe: serverProbeFor(_db, event.actorId),
    () => _tx.runBatch((batch) {
      _stager.contribution(batch, familyId, plan.voided, event);
      _stager.fundRows(batch, familyId, <FundTransaction?>[
        plan.adjustment,
      ], event);
      AuditWriter.write(batch, familyId, event);
    }),
  );

  @override
  Future<Result<void>> commitOpeningBalance(
    String familyId,
    OpeningBalancePlan plan,
    AuditEvent event,
  ) => guardWrite(
    probe: serverProbeFor(_db, event.actorId),
    () async {
      final settingsPath = FirestorePaths.bazarSettingsDoc(familyId);
      final existing = await _db.doc(settingsPath).get();
      await _tx.runBatch((batch) {
        _stager.fundRows(batch, familyId, <FundTransaction?>[
          plan.opening,
        ], event);
        if (existing.exists) {
          // Only the start month changes; every other setting is kept.
          batch.set(settingsPath, <String, dynamic>{
            'fundStartMonth': plan.startMonth.toString(),
            BaseMapper.keyUpdatedAt: BaseMapper.dateTimeToTimestamp(event.at),
            BaseMapper.keyUpdatedBy: event.actorId,
          }, merge: true);
        } else {
          batch.set(
            settingsPath,
            BazarSettingsMappers.toMap(
              BazarSettings.defaults.copyWith(fundStartMonth: plan.startMonth),
              BaseDocumentMetadata(
                createdAt: event.at,
                createdBy: event.actorId,
                updatedAt: event.at,
                updatedBy: event.actorId,
              ),
            ),
          );
        }
        AuditWriter.write(batch, familyId, event);
      });
    },
  );

  Query<Map<String, dynamic>> _monthQuery(
    String path,
    MonthKey month,
    String? memberId,
  ) {
    final bounded = _db
        .collection(path)
        .where('monthKey', isEqualTo: month.toString())
        .limit(kMaxListenerDocs);
    return memberId == null
        ? bounded
        : bounded.where('memberId', isEqualTo: memberId);
  }

  List<ContributionPlan> _plans(QuerySnapshot<Map<String, dynamic>> snapshot) {
    final plans = <ContributionPlan>[
      for (final document in snapshot.docs)
        ?ContributionMappers.planFromMap(document.data()),
    ]..sort((a, b) => a.memberId.compareTo(b.memberId));
    return plans;
  }

  List<Contribution> _contributions(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    final rows = <Contribution>[
      for (final document in snapshot.docs)
        ?ContributionMappers.fromMap(document.id, document.data()),
    ]..sort((a, b) {
        final byDate = b.dateKey.compareTo(a.dateKey);
        return byDate != 0 ? byDate : b.id.compareTo(a.id);
      });
    return rows;
  }
}
