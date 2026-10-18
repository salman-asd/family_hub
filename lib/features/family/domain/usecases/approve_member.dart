import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/features/family/domain/member.dart';
import 'package:family_hub/features/family/domain/member_role.dart';
import 'package:family_hub/features/family/domain/membership.dart';
import 'package:family_hub/features/family/domain/usecases/member_change_runner.dart';

/// Approves a pending request, or re-enables a disabled member.
///
/// Admins and moderators may do both.
class ApproveMember {
  const ApproveMember(this._runner);

  final MemberChangeRunner _runner;

  Future<Result<Member>> call({
    required String actorUid,
    required String familyId,
    required String targetUid,
  }) =>
      _runner.run(
        actorUid: actorUid,
        familyId: familyId,
        targetUid: targetUid,
        allowed: {MemberRole.admin, MemberRole.moderator},
        eventType: 'member.approved',
        decide: (target, all) {
          if (target.status == MembershipStatus.active) {
            return const Failure<Member>(Conflict(code: 'already_active'));
          }
          return Success<Member>(target.copyWith(status: MembershipStatus.active));
        },
      );
}
