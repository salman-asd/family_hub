import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/core/permissions/permissions.dart';
import 'package:family_hub/core/utils/clock.dart';
import 'package:family_hub/features/family/domain/member.dart';
import 'package:family_hub/features/family/domain/membership.dart';
import 'package:family_hub/features/family/domain/usecases/member_change_runner.dart';

/// Rejects a pending request (soft delete: `removedAt` is set; the person
/// returns to the family choice screen and may try another code).
///
/// `Permission.approveMembers`: deciding a request is one permission, so an
/// admin and a moderator can both reject one.
class RejectMember {
  const RejectMember(this._runner, this._clock);

  final MemberChangeRunner _runner;
  final Clock _clock;

  Future<Result<Member>> call({
    required String actorUid,
    required String familyId,
    required String targetUid,
  }) =>
      _runner.run(
        actorUid: actorUid,
        familyId: familyId,
        targetUid: targetUid,
        permission: Permission.approveMembers,
        eventType: 'member.rejected',
        decide: (target, all) {
          if (target.status != MembershipStatus.pending) {
            return const Failure<Member>(Conflict(code: 'not_pending'));
          }
          return Success<Member>(target.copyWith(removedAt: _clock.nowUtc()));
        },
      );
}
