import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/core/permissions/permissions.dart';
import 'package:family_hub/features/family/domain/family_repository.dart';
import 'package:family_hub/features/family/domain/member.dart';

/// Loads the acting member, then asks [PermissionPolicy] whether they may act.
///
/// This is the `requirePermission` helper of Step 10: every mutating use case
/// calls it FIRST, before reading inputs or touching the repository.  It
/// replaces the Step 9 `requireActor` (which took a raw set of roles), so the
/// rule lives in exactly one matrix instead of in each use case.
///
/// Returns `PermissionDenied` for a missing, rejected, pending or disabled
/// actor, and for an active actor the matrix does not allow.  A repository
/// failure is passed through unchanged.
Future<Result<Member>> requirePermission(
  FamilyRepository repository, {
  required String familyId,
  required String actorUid,
  required Permission permission,
  String? ownerId,
  PermissionSettings settings = PermissionSettings.defaults,
  PermissionTemplate? template,
}) async {
  final result = await repository.getMember(familyId, actorUid);
  final failure = result.failureOrNull;
  if (failure != null) return Failure<Member>(failure);

  final actor = result.valueOrNull;
  if (actor == null || actor.isRemoved) {
    return const Failure<Member>(PermissionDenied());
  }
  if (!PermissionPolicy.can(
    actor.permissionActor,
    permission,
    ownerId: ownerId,
    settings: settings,
    template: template,
  )) {
    return const Failure<Member>(PermissionDenied());
  }
  return Success<Member>(actor);
}

/// True when applying [updated] to [members] leaves no active admin.
///
/// Firestore rules cannot enumerate a subcollection, so the last-admin guard
/// cannot be expressed there; it is enforced here and in the use cases that
/// change a role, disable a member or remove one (Step 9/10).
bool leavesNoActiveAdmin(List<Member> members, Member updated) {
  final after = [
    for (final m in members) m.uid == updated.uid ? updated : m,
  ];
  return !after.any((m) => m.isActiveAdmin);
}
