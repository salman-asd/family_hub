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

/// A manager voids an APPROVED contribution (a pending one is cancelled or
/// rejected instead).
///
/// ONE batch: `voidedAt/By` on the contribution (a stale change request is
/// dropped) plus an `adj_<eventId>` ledger row of `-amount` dated like the
/// contribution.  The original `con_<id>` row is never edited, so the history
/// stays explainable.  Needs the server.
class VoidContribution {
  const VoidContribution({
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
    if (current.isVoided) {
      return const Failure<Contribution>(Conflict(code: 'already_voided'));
    }
    if (!current.isApproved) {
      return const Failure<Contribution>(
        Conflict(code: 'contribution_not_approved'),
      );
    }
    final locked = await monthLockFailure(_funds, familyId, [
      current.monthKey,
    ]);
    if (locked != null) return Failure<Contribution>(locked);

    final now = _clock.nowUtc();
    final voidEventId = eventId ?? _newId();
    final updated = current.copyWith(
      voidedAt: now,
      voidedBy: actorUid,
      clearPendingChange: true,
    );
    final saved = await _contributions.commitVoid(
      familyId,
      ContributionVoidPlan(
        voided: updated,
        adjustment: FundTransaction.adjustment(
          eventId: voidEventId,
          amount: -current.amount,
          dateKey: current.dateKey,
          refType: FundRefType.contribution,
          refId: current.id,
          createdBy: actorUid,
          createdAt: now,
        ),
      ),
      contributionEvent(
        id: voidEventId,
        type: AuditEventType.bazarContributionVoided,
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
