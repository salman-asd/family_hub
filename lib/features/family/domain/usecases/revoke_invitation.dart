import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/core/permissions/permissions.dart';
import 'package:family_hub/core/utils/clock.dart';
import 'package:family_hub/core/utils/id_generator.dart';
import 'package:family_hub/core/audit/audit_event.dart';
import 'package:family_hub/features/family/domain/family_repository.dart';
import 'package:family_hub/features/family/domain/invitation.dart';
import 'package:family_hub/features/family/domain/permission_access.dart';

/// Revokes an ACTIVE invitation (`Permission.inviteMembers`: admin, moderator).
///
/// Used, expired and already-revoked codes cannot be revoked
/// (`Conflict(code: 'not_active')`).  Both copies of the code are updated in
/// the same batch.
class RevokeInvitation {
  const RevokeInvitation({
    required FamilyRepository families,
    required Clock clock,
    required IdGenerator newId,
  })  : _families = families,
        _clock = clock,
        _newId = newId;

  final FamilyRepository _families;
  final Clock _clock;
  final IdGenerator _newId;

  Future<Result<Invitation>> call({
    required String actorUid,
    required String familyId,
    required String code,
  }) async {
    final actor = await requirePermission(
      _families,
      familyId: familyId,
      actorUid: actorUid,
      permission: Permission.inviteMembers,
    );
    final denied = actor.failureOrNull;
    if (denied != null) return Failure<Invitation>(denied);

    final found = await _families.findInvitation(code);
    final findFailure = found.failureOrNull;
    if (findFailure != null) return Failure<Invitation>(findFailure);
    final invitation = found.valueOrNull;
    if (invitation == null || invitation.familyId != familyId) {
      return const Failure<Invitation>(NotFound(entity: 'invitation'));
    }

    final now = _clock.nowUtc();
    if (invitation.status != InvitationStatus.active ||
        invitation.isExpiredAt(now)) {
      return const Failure<Invitation>(Conflict(code: 'not_active'));
    }

    final revoked = invitation.markRevoked();
    final saved = await _families.revokeInvitation(
      revoked,
      AuditEvent(
        id: _newId(),
        type: 'invitation.revoked',
        actorId: actorUid,
        summary: 'Invitation $code revoked',
        refType: 'invitation',
        refId: code,
        at: now,
      ),
    );
    final failure = saved.failureOrNull;
    return failure != null
        ? Failure<Invitation>(failure)
        : Success<Invitation>(revoked);
  }
}
