import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/core/utils/clock.dart';
import 'package:family_hub/core/utils/id_generator.dart';
import 'package:family_hub/core/audit/audit_event.dart';
import 'package:family_hub/features/family/domain/family_repository.dart';
import 'package:family_hub/features/family/domain/member.dart';
import 'package:family_hub/features/family/domain/membership.dart';
import 'package:family_hub/features/family/domain/permission_access.dart';

/// An active member leaves the family (self only).
///
/// Sets `status = disabled` plus `leftAt` and `removedAt`, so history is kept
/// and the person is free to create or join a family again.  The only active
/// admin cannot leave: `Conflict(code: 'last_admin')` (transfer admin first).
class LeaveFamily {
  const LeaveFamily({
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
  }) async {
    final found = await _families.getMember(familyId, actorUid);
    final findFailure = found.failureOrNull;
    if (findFailure != null) return Failure<Member>(findFailure);
    final me = found.valueOrNull;
    if (me == null || !me.isActive) {
      return const Failure<Member>(PermissionDenied());
    }

    final listed = await _families.getMembers(familyId);
    final listFailure = listed.failureOrNull;
    if (listFailure != null) return Failure<Member>(listFailure);
    final all = listed.valueOrNull ?? const <Member>[];

    final now = _clock.nowUtc();
    final updated = me.copyWith(
      status: MembershipStatus.disabled,
      leftAt: now,
      removedAt: now,
    );
    if (me.isActiveAdmin && leavesNoActiveAdmin(all, updated)) {
      return const Failure<Member>(Conflict(code: 'last_admin'));
    }

    // H6: an admin leaving changes the active-admin set, so the family document
    // must be rewritten in the same batch (a plain member leaving does not).
    final adminIds = activeAdminIds(rosterWith(all, updated));
    final writeAdminIds =
        sameAdminSet(activeAdminIds(all), adminIds) ? null : adminIds;

    final saved = await _families.saveMembers(
      familyId,
      [updated],
      AuditEvent(
        id: _newId(),
        type: 'member.left',
        actorId: actorUid,
        summary: '${me.fullName} left the family',
        refType: 'member',
        refId: actorUid,
        at: now,
      ),
      adminIds: writeAdminIds,
    );
    final failure = saved.failureOrNull;
    return failure != null
        ? Failure<Member>(failure)
        : Success<Member>(updated);
  }
}
