import 'package:family_hub/core/audit/audit_event_type.dart';
import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/core/permissions/permissions.dart';
import 'package:family_hub/core/utils/clock.dart';
import 'package:family_hub/core/utils/id_generator.dart';
import 'package:family_hub/features/bazar/contributions/domain/contribution_guards.dart';
import 'package:family_hub/features/bazar/contributions/domain/contribution_repository.dart';
import 'package:family_hub/features/bazar/fund/domain/fund_repository.dart';
import 'package:family_hub/features/family/domain/family_repository.dart';
import 'package:family_hub/features/family/domain/permission_access.dart';

/// The owner withdraws THEIR OWN pending request.
///
/// A soft void (`voidedAt/By`): the document stays for history and no ledger
/// row is written, because a pending request never had one.
class CancelContributionRequest {
  const CancelContributionRequest({
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

  Future<Result<void>> call({
    required String actorUid,
    required String familyId,
    required String contributionId,
    String? eventId,
  }) async {
    final permitted = await requirePermission(
      _families,
      familyId: familyId,
      actorUid: actorUid,
      permission: Permission.requestContribution,
    );
    final denied = permitted.failureOrNull;
    if (denied != null) return Failure<void>(denied);

    final loaded = await _contributions.getContribution(
      familyId,
      contributionId,
    );
    final loadFailure = loaded.failureOrNull;
    if (loadFailure != null) return Failure<void>(loadFailure);
    final current = loaded.valueOrNull;
    if (current == null) {
      return const Failure<void>(NotFound(entity: 'contribution'));
    }
    if (!isOwner(current, actorUid)) {
      return const Failure<void>(PermissionDenied());
    }
    if (!current.isPending) {
      return const Failure<void>(Conflict(code: 'contribution_not_pending'));
    }
    final locked = await monthLockFailure(_funds, familyId, [
      current.monthKey,
    ]);
    if (locked != null) return Failure<void>(locked);

    final now = _clock.nowUtc();
    final updated = current.copyWith(voidedAt: now, voidedBy: actorUid);
    return _contributions.saveContribution(
      familyId,
      updated,
      contributionEvent(
        id: eventId ?? _newId(),
        type: AuditEventType.bazarContributionRequestCancelled,
        actorId: actorUid,
        contribution: updated,
        at: now,
      ),
    );
  }
}
