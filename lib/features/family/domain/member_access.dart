import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/features/family/domain/family_repository.dart';
import 'package:family_hub/features/family/domain/member.dart';
import 'package:family_hub/features/family/domain/member_role.dart';

/// Loads the acting member and checks they are active with an allowed role.
///
/// TODO(step-10): replaced by `PermissionPolicy.can(...)`.  Until then the rule
/// is: admins do everything; moderators may invite, approve and reject.
Future<Result<Member>> requireActor(
  FamilyRepository repository, {
  required String familyId,
  required String actorUid,
  required Set<MemberRole> allowed,
}) async {
  final result = await repository.getMember(familyId, actorUid);
  final failure = result.failureOrNull;
  if (failure != null) return Failure<Member>(failure);
  final actor = result.valueOrNull;
  if (actor == null || actor.isRemoved) {
    return const Failure<Member>(PermissionDenied());
  }
  if (!actor.isActive || !allowed.contains(actor.role)) {
    return const Failure<Member>(PermissionDenied());
  }
  return Success<Member>(actor);
}

/// True when applying [updated] to [members] leaves no active admin.
bool leavesNoActiveAdmin(List<Member> members, Member updated) {
  final after = [
    for (final m in members) m.uid == updated.uid ? updated : m,
  ];
  return !after.any((m) => m.isActiveAdmin);
}
