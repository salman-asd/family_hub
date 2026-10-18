import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/core/permissions/permissions.dart';
import 'package:family_hub/core/utils/clock.dart';
import 'package:family_hub/core/utils/id_generator.dart';
import 'package:family_hub/features/family/domain/family_event.dart';
import 'package:family_hub/features/family/domain/family_repository.dart';
import 'package:family_hub/features/family/domain/invitation.dart';
import 'package:family_hub/features/family/domain/invite_code_generator.dart';
import 'package:family_hub/features/family/domain/member_role.dart';
import 'package:family_hub/features/family/domain/permission_access.dart';

/// Creates a single-use invitation: 8 unambiguous characters, valid for 7 days,
/// role `member`.  `Permission.inviteMembers`: admins and moderators.
class CreateInvitation {
  const CreateInvitation({
    required FamilyRepository families,
    required InviteCodeGenerator codes,
    required Clock clock,
    required IdGenerator newId,
  })  : _families = families,
        _codes = codes,
        _clock = clock,
        _newId = newId;

  static const Duration validity = Duration(days: 7);
  static const int maxAttempts = 5;

  final FamilyRepository _families;
  final InviteCodeGenerator _codes;
  final Clock _clock;
  final IdGenerator _newId;

  Future<Result<Invitation>> call({
    required String actorUid,
    required String familyId,
  }) async {
    final actor = await requirePermission(
      _families,
      familyId: familyId,
      actorUid: actorUid,
      permission: Permission.inviteMembers,
    );
    final denied = actor.failureOrNull;
    if (denied != null) return Failure<Invitation>(denied);

    // A collision is astronomically unlikely, but a duplicate would overwrite
    // someone's invitation, so check.
    String? code;
    for (var i = 0; i < maxAttempts && code == null; i++) {
      final candidate = _codes.next();
      final existing = await _families.findInvitation(candidate);
      final failure = existing.failureOrNull;
      if (failure != null) return Failure<Invitation>(failure);
      if (existing.valueOrNull == null) code = candidate;
    }
    if (code == null) {
      return const Failure<Invitation>(Conflict(code: 'code_collision'));
    }

    final now = _clock.nowUtc();
    final invitation = Invitation(
      code: code,
      familyId: familyId,
      role: MemberRole.member,
      expiresAt: now.add(validity),
      createdBy: actorUid,
      createdAt: now,
    );
    final saved = await _families.saveInvitation(
      invitation,
      FamilyEvent(
        id: _newId(),
        type: 'invitation.created',
        actorId: actorUid,
        summary: 'Invitation $code created',
        refType: 'invitation',
        refId: code,
        at: now,
      ),
    );
    final failure = saved.failureOrNull;
    return failure != null
        ? Failure<Invitation>(failure)
        : Success<Invitation>(invitation);
  }
}
