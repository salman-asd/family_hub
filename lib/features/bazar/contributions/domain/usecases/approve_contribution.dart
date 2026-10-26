import 'package:family_hub/core/audit/audit_event_type.dart';
import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/core/permissions/permissions.dart';
import 'package:family_hub/core/utils/clock.dart';
import 'package:family_hub/core/utils/id_generator.dart';
import 'package:family_hub/features/bazar/contributions/domain/contribution.dart';
import 'package:family_hub/features/bazar/contributions/domain/contribution_guards.dart';
import 'package:family_hub/features/bazar/contributions/domain/contribution_repository.dart';
import 'package:family_hub/features/bazar/contributions/domain/contribution_write_plans.dart';
import 'package:family_hub/features/bazar/fund/domain/fund_repository.dart';
import 'package:family_hub/features/family/domain/family_repository.dart';
import 'package:family_hub/features/family/domain/permission_access.dart';
import 'package:family_hub/features/bazar/fund/domain/fund_transaction.dart';

/// A manager approves a pending request.
///
/// ONE batch: the contribution becomes `approved` with `fundTxId: con_<id>`
/// and the `con_<id>` ledger row is written once.  It needs the server (the
/// repository probes, and the contribution is read fresh), so two managers
/// cannot both approve from stale offline state; a second approval fails with
/// `Conflict('contribution_not_pending')`.
class ApproveContribution {
  const ApproveContribution({
    required this._contributions,
    required this._funds,
    required this._families,
    required this._clock,
    required this._newId,
  });

  final ContributionRepository _contributions;
  final FundRepository _funds;
  final FamilyRepository _families;
  final Clock _clock;
  final IdGenerator _newId;

  Future<Result<Contribution>> call({
    required String actorUid,
    required String familyId,
    required String contributionId,
    String? eventId,
  }) async {
    final permitted = await requirePermission(
      _families,
      familyId: familyId,
      actorUid: actorUid,
      permission: Permission.recordContribution,
    );
    final denied = permitted.failureOrNull;
    if (denied != null) return Failure<Contribution>(denied);

    final loaded = await _contributions.getContribution(
      familyId,
      contributionId,
      fresh: true,
    );
    final loadFailure = loaded.failureOrNull;
    if (loadFailure != null) return Failure<Contribution>(loadFailure);
    final current = loaded.valueOrNull;
    if (current == null) {
      return const Failure<Contribution>(NotFound(entity: 'contribution'));
    }
    if (!current.isPending) {
      return const Failure<Contribution>(
        Conflict(code: 'contribution_not_pending'),
      );
    }
    final locked = await monthLockFailure(_funds, familyId, [
      current.monthKey,
    ]);
    if (locked != null) return Failure<Contribution>(locked);

    final now = _clock.nowUtc();
    final updated = current.copyWith(
      status: ContributionApproval.approved,
      fundTxId: 'con_${current.id}',
      decidedBy: actorUid,
      decidedAt: now,
    );
    final saved = await _contributions.commitDecision(
      familyId,
      ContributionDecisionPlan(
        updated: updated,
        fundTx: FundTransaction.forContribution(
          contributionId: current.id,
          amount: current.amount,
          dateKey: current.dateKey,
          createdBy: actorUid,
          createdAt: now,
          note: current.note,
        ),
      ),
      contributionEvent(
        id: eventId ?? _newId(),
        type: AuditEventType.bazarContributionApproved,
        actorId: actorUid,
        contribution: updated,
        at: now,
      ),
    );
    final failure = saved.failureOrNull;
    return failure != null
        ? Failure<Contribution>(failure)
        : Success<Contribution>(updated);
  }
}
