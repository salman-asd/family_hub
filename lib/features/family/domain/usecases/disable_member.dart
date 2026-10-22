import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/core/permissions/permissions.dart';
import 'package:family_hub/features/family/domain/member.dart';
import 'package:family_hub/features/family/domain/membership.dart';
import 'package:family_hub/features/family/domain/permission_access.dart';
import 'package:family_hub/features/family/domain/usecases/member_change_runner.dart';

/// Disables an active member (`Permission.removeMembers`: admin only).  The only
/// active admin cannot be disabled: that returns `Conflict(code: 'last_admin')`.
class DisableMember {
  const DisableMember(this._runner);

  final MemberChangeRunner _runner;

  Future<Result<Member>> call({
    required String actorUid,
    required String familyId,
    required String targetUid,
  }) => _runner.run(
    actorUid: actorUid,
    familyId: familyId,
    targetUid: targetUid,
    permission: Permission.removeMembers,
    eventType: 'member.disabled',
    decide: (target, all) {
      final updated = target.copyWith(status: MembershipStatus.disabled);
      if (leavesNoActiveAdmin(all, updated)) {
        return const Failure<Member>(Conflict(code: 'last_admin'));
      }
      return Success<Member>(updated);
    },
  );
}
