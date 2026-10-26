import 'package:family_hub/core/audit/audit_event.dart';
import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/features/bazar/contributions/domain/contribution.dart';
import 'package:family_hub/features/bazar/contributions/domain/contribution_write_plans.dart';

/// Port for contributions and their monthly plans.
///
/// Every active member may read every contribution and plan (D-P2-5), so no
/// `memberId` filter is required; [memberId] only narrows the "my
/// contributions" view.  Every write also writes its audit entry in the same
/// batch (CLAUDE.md rule 3).
abstract interface class ContributionRepository {
  Stream<List<ContributionPlan>> watchPlans(
    String familyId,
    MonthKey month, {
    String? memberId,
  });

  Stream<List<Contribution>> watchContributions(
    String familyId,
    MonthKey month, {
    String? memberId,
  });

  Future<Result<List<ContributionPlan>>> getPlans(
    String familyId,
    MonthKey month,
  );

  /// `null` when it does not exist.  [fresh] asks the server (a decision must
  /// not rest on a stale cached copy); offline that fails with `Network`.
  Future<Result<Contribution?>> getContribution(
    String familyId,
    String id, {
    bool fresh = false,
  });

  /// Writes (or replaces) plans.  An everyday write: it queues offline.
  Future<Result<void>> savePlans(
    String familyId,
    List<ContributionPlan> plans,
    AuditEvent event,
  );

  /// A new contribution (and, for a manager, its ledger row) in ONE batch.
  /// Queues offline.
  Future<Result<void>> commitContribution(
    String familyId,
    ContributionWritePlan plan,
    AuditEvent event,
  );

  /// Replaces a contribution with NO ledger change (a member's edit, cancel or
  /// change request).  Queues offline.
  Future<Result<void>> saveContribution(
    String familyId,
    Contribution contribution,
    AuditEvent event,
  );

  /// A manager's decision (approve, reject, approve/reject change).  Needs the
  /// server so two managers cannot decide from stale offline state.
  Future<Result<void>> commitDecision(
    String familyId,
    ContributionDecisionPlan plan,
    AuditEvent event,
  );

  /// Voids an approved contribution.  Needs the server.
  Future<Result<void>> commitVoid(
    String familyId,
    ContributionVoidPlan plan,
    AuditEvent event,
  );

  /// Writes the `opening` row and `settings/bazar.fundStartMonth` in ONE
  /// batch.  Needs the server.
  Future<Result<void>> commitOpeningBalance(
    String familyId,
    OpeningBalancePlan plan,
    AuditEvent event,
  );
}
