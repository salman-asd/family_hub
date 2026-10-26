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

/// A manager declines a member's change request.  Only `pendingChange` is
/// cleared (the contribution and the ledger stay as they were); the optional
/// reason goes into the audit entry.  Needs the server.
class RejectContributionChange {
  const RejectContributionChange({
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
    String? reason,
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

    final cleanReason = (reason ?? '').trim();
    if (cleanReason.runes.length > kMaxRejectReason) {
      return const Failure<Contribution>(Validation('reason', 'too_long'));
    }

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
    if (!current.isApproved || current.pendingChange == null) {
      return const Failure<Contribution>(Conflict(code: 'no_pending_change'));
    }
    final locked = await monthLockFailure(_funds, familyId, [
      current.monthKey,
    ]);
    if (locked != null) return Failure<Contribution>(locked);

    final now = _clock.nowUtc();
    final updated = current.copyWith(clearPendingChange: true);
    final saved = await _contributions.commitDecision(
      familyId,
      ContributionDecisionPlan(updated: updated),
      contributionEvent(
        id: eventId ?? _newId(),
        type: AuditEventType.bazarContributionChangeRejected,
        actorId: actorUid,
        contribution: updated,
        at: now,
        extra: <String, String>{if (cleanReason.isNotEmpty) 'reason': cleanReason},
      ),
    );
    final failure = saved.failureOrNull;
    return failure != null
        ? Failure<Contribution>(failure)
        : Success<Contribution>(updated);
  }
}
