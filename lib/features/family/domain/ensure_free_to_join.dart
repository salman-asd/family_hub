import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/features/family/domain/family_repository.dart';
import 'package:family_hub/features/family/domain/membership.dart';

/// One family per user (CLAUDE.md rule 17).
///
/// Succeeds with `Membership.none` when [uid] may create or join a family:
/// they have no family, or they left / were rejected / cancelled.  Fails with
/// `Conflict(code: 'already_in_family')` while they are pending, active, or
/// disabled by an admin (a disabled member must be re-enabled or released
/// first).
///
/// [allowFamilyId] is the retry exception: when the existing membership is in
/// THAT family, the caller is repeating its own earlier request, so the helper
/// returns that membership and lets the caller finish idempotently.
Future<Result<Membership>> ensureFreeToJoinAnyFamily(
  FamilyRepository families,
  String uid, {
  String? allowFamilyId,
}) async {
  final pointer = await families.getUserFamilyPointer(uid);
  final failure = pointer.failureOrNull;
  if (failure != null) return Failure<Membership>(failure);
  final current = pointer.valueOrNull ?? Membership.none;
  if (current.status == MembershipStatus.none) {
    return const Success<Membership>(Membership.none);
  }
  if (allowFamilyId != null && current.familyId == allowFamilyId) {
    return Success<Membership>(current);
  }
  return const Failure<Membership>(Conflict(code: 'already_in_family'));
}
