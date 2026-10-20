import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/core/utils/clock.dart';
import 'package:family_hub/core/utils/id_generator.dart';
import 'package:family_hub/features/family/domain/ensure_free_to_join.dart';
import 'package:family_hub/core/audit/audit_event.dart';
import 'package:family_hub/features/family/domain/family_repository.dart';
import 'package:family_hub/features/family/domain/invitation.dart';
import 'package:family_hub/features/family/domain/invite_code_generator.dart';
import 'package:family_hub/features/family/domain/member.dart';
import 'package:family_hub/features/family/domain/membership.dart';
import 'package:family_hub/features/onboarding/domain/user_profile_repository.dart';

/// Validates an invitation code and creates the caller's `pending` membership.
///
/// Failure codes (as `Conflict.code` / `Validation.code`):
/// `invalid` (malformed), `code_used`, `code_revoked`, `code_expired`,
/// `already_member`; unknown codes are `NotFound`.  The member only becomes
/// active when an admin or moderator approves.
class JoinWithCode {
  const JoinWithCode({
    required FamilyRepository families,
    required UserProfileRepository profiles,
    required Clock clock,
    required IdGenerator newId,
  })  : _families = families,
        _profiles = profiles,
        _clock = clock,
        _newId = newId;

  final FamilyRepository _families;
  final UserProfileRepository _profiles;
  final Clock _clock;
  final IdGenerator _newId;

  Future<Result<Member>> call({
    required String actorUid,
    required String rawCode,
    String? eventId,
  }) async {
    final code = InviteCodeGenerator.normalize(rawCode);
    if (!InviteCodeGenerator.isWellFormed(code)) {
      return const Failure<Member>(Validation('code', 'invalid'));
    }

    final found = await _families.findInvitation(code);
    final findFailure = found.failureOrNull;
    if (findFailure != null) return Failure<Member>(findFailure);
    final invitation = found.valueOrNull;
    if (invitation == null) {
      return const Failure<Member>(NotFound(entity: 'invitation'));
    }

    final now = _clock.nowUtc();
    switch (invitation.status) {
      case InvitationStatus.used:
        // A repeat of my own request (the first write was only queued, or the
        // reply was lost): answer with the membership that already exists.
        if (invitation.usedBy == actorUid) {
          final mine = await _families.getMember(invitation.familyId, actorUid);
          final existingMember = mine.valueOrNull;
          if (existingMember != null && !existingMember.isRemoved) {
            return Success<Member>(existingMember);
          }
        }
        return const Failure<Member>(Conflict(code: 'code_used'));
      case InvitationStatus.revoked:
        return const Failure<Member>(Conflict(code: 'code_revoked'));
      case InvitationStatus.active:
        break;
    }
    if (invitation.isExpiredAt(now)) {
      return const Failure<Member>(Conflict(code: 'code_expired'));
    }

    // One family per user (rule 17).
    final free = await ensureFreeToJoinAnyFamily(
      _families,
      actorUid,
      allowFamilyId: invitation.familyId,
    );
    final freeFailure = free.failureOrNull;
    if (freeFailure != null) return Failure<Member>(freeFailure);

    final profileResult = await _profiles.getProfile(actorUid);
    final profileFailure = profileResult.failureOrNull;
    if (profileFailure != null) return Failure<Member>(profileFailure);
    final profile = profileResult.valueOrNull;
    if (profile == null) {
      return const Failure<Member>(Validation('profile', 'required'));
    }

    final existing = await _families.getMember(invitation.familyId, actorUid);
    final existingFailure = existing.failureOrNull;
    if (existingFailure != null) return Failure<Member>(existingFailure);
    final current = existing.valueOrNull;
    if (current != null && !current.isRemoved) {
      return const Failure<Member>(Conflict(code: 'already_member'));
    }

    final member = Member(
      uid: actorUid,
      role: invitation.role,
      status: MembershipStatus.pending,
      fullName: profile.fullName,
      nickname: profile.nickname,
      relationship: profile.relationship.name,
      spouseId: profile.spouseId,
      avatarKey: profile.avatarKey,
      inviteCode: code,
    );
    final saved = await _families.requestToJoin(
      invitation: invitation,
      member: member,
      event: AuditEvent(
        id: eventId ?? _newId(),
        type: 'member.requested',
        actorId: actorUid,
        summary: '${profile.fullName} asked to join',
        refType: 'member',
        refId: actorUid,
        at: now,
      ),
    );
    final failure = saved.failureOrNull;
    return failure != null ? Failure<Member>(failure) : Success<Member>(member);
  }
}
