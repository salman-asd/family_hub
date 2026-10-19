import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/core/permissions/permissions.dart';
import 'package:family_hub/core/utils/clock.dart';
import 'package:family_hub/core/utils/id_generator.dart';
import 'package:family_hub/features/family/domain/family_event.dart';
import 'package:family_hub/features/family/domain/family_repository.dart';
import 'package:family_hub/features/family/domain/member.dart';
import 'package:family_hub/features/family/domain/member_role.dart';
import 'package:family_hub/features/family/domain/permission_access.dart';

/// Hands the admin role to another active member; the previous admin becomes a
/// regular member.  Both changes are saved in ONE batch, so the family is never
/// without an admin.  `Permission.changeRoles`: admins only.
class TransferAdmin {
  const TransferAdmin({
    required FamilyRepository families,
    required Clock clock,
    required IdGenerator newId,
  })  : _families = families,
        _clock = clock,
        _newId = newId;

  final FamilyRepository _families;
  final Clock _clock;
  final IdGenerator _newId;

  Future<Result<Member>> call({
    required String actorUid,
    required String familyId,
    required String targetUid,
  }) async {
    if (targetUid == actorUid) {
      return const Failure<Member>(Conflict(code: 'same_member'));
    }
    final actor = await requirePermission(
      _families,
      familyId: familyId,
      actorUid: actorUid,
      permission: Permission.changeRoles,
    );
    final denied = actor.failureOrNull;
    if (denied != null) return Failure<Member>(denied);

    final target = await _families.getMember(familyId, targetUid);
    final failure = target.failureOrNull;
    if (failure != null) return Failure<Member>(failure);
    final next = target.valueOrNull;
    if (next == null || next.isRemoved) {
      return const Failure<Member>(NotFound(entity: 'member'));
    }
    if (!next.isActive) {
      return const Failure<Member>(Conflict(code: 'not_active'));
    }

    // H6: the new `adminIds` is computed from the whole roster and written in
    // the same batch; a family never exceeds three admins (D4).
    final listed = await _families.getMembers(familyId);
    final listFailure = listed.failureOrNull;
    if (listFailure != null) return Failure<Member>(listFailure);
    final all = listed.valueOrNull ?? const <Member>[];

    final newAdmin = next.copyWith(role: MemberRole.admin);
    final oldAdmin = actor.valueOrNull!.copyWith(role: MemberRole.member);
    final adminIds =
        activeAdminIds(rosterWith(rosterWith(all, newAdmin), oldAdmin));
    if (adminIds.length > maxActiveAdmins) {
      return const Failure<Member>(Conflict(code: 'too_many_admins'));
    }
    final writeAdminIds =
        sameAdminSet(activeAdminIds(all), adminIds) ? null : adminIds;

    final saved = await _families.saveMembers(
      familyId,
      [newAdmin, oldAdmin],
      FamilyEvent(
        id: _newId(),
        type: 'member.admin_transferred',
        actorId: actorUid,
        summary: 'Admin role moved to ${newAdmin.fullName}',
        refType: 'member',
        refId: targetUid,
        at: _clock.nowUtc(),
      ),
      adminIds: writeAdminIds,
    );
    final saveFailure = saved.failureOrNull;
    return saveFailure != null
        ? Failure<Member>(saveFailure)
        : Success<Member>(newAdmin);
  }
}
