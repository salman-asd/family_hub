import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/features/family/domain/member.dart';
import 'package:family_hub/features/family/domain/member_access.dart';
import 'package:family_hub/features/family/domain/member_role.dart';
import 'package:family_hub/features/family/domain/usecases/member_change_runner.dart';

/// Changes a member's role (admin only).  Demoting the only active admin
/// returns `Conflict(code: 'last_admin')`.
class ChangeRole {
  const ChangeRole(this._runner);

  final MemberChangeRunner _runner;

  Future<Result<Member>> call({
    required String actorUid,
    required String familyId,
    required String targetUid,
    required MemberRole newRole,
  }) =>
      _runner.run(
        actorUid: actorUid,
        familyId: familyId,
        targetUid: targetUid,
        allowed: {MemberRole.admin},
        eventType: 'member.role_changed',
        decide: (target, all) {
          if (target.role == newRole) {
            return const Failure<Member>(Conflict(code: 'same_role'));
          }
          final updated = target.copyWith(role: newRole);
          if (leavesNoActiveAdmin(all, updated)) {
            return const Failure<Member>(Conflict(code: 'last_admin'));
          }
          return Success<Member>(updated);
        },
      );
}
