import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/features/auth/domain/auth_repository.dart';
import 'package:family_hub/features/family/domain/family_repository.dart';
import 'package:family_hub/features/family/domain/member.dart';
import 'package:family_hub/features/family/domain/membership.dart';
import 'package:family_hub/features/family/domain/usecases/cancel_join_request.dart';
import 'package:family_hub/features/family/domain/usecases/leave_family.dart';
import 'package:family_hub/features/settings/domain/account_repository.dart';

/// Deletes the signed-in user's account (H9, decision D2).
///
/// Order, chosen so that a failure half-way can always be resumed by calling
/// the use case again:
///
/// 1. re-authenticate with the password (the backend demands a recent login);
/// 2. refuse with `Conflict('last_admin_has_members')` when the user is the
///    ONLY admin of a family that still has other members: they must transfer
///    admin first;
/// 3. leave the family (active member) or withdraw the request (pending),
///    which keeps their history attributed to their name;
/// 4. mark `users/{uid}` deleted (soft delete, PII not needed for history is
///    cleared);
/// 5. delete the Firebase Auth user.
///
/// If step 5 fails after step 4, `AccountRepository.watchMarkedDeleted` is true
/// and the Security screen offers "Finish deleting"; running this use case again
/// skips the steps that already happened.  A solo admin with nobody else in the
/// family skips step 3 (the family stays dormant, its history intact).
class DeleteAccount {
  const DeleteAccount({
    required this._auth,
    required this._accounts,
    required this._families,
    required this._leaveFamily,
    required this._cancelJoinRequest,
  });

  final AuthRepository _auth;
  final AccountRepository _accounts;
  final FamilyRepository _families;
  final LeaveFamily _leaveFamily;
  final CancelJoinRequest _cancelJoinRequest;

  /// [familyId] is the family the user currently belongs to, if any.
  Future<Result<void>> call({
    required String uid,
    required String password,
    String? familyId,
  }) async {
    if (password.isEmpty) {
      return const Failure<void>(Validation('password', 'required'));
    }

    // 1. Re-authenticate.
    final reauth = await _auth.reauthenticate(password: password);
    final reauthFailure = reauth.failureOrNull;
    if (reauthFailure != null) return Failure<void>(reauthFailure);

    // 2 + 3. Membership.
    if (familyId != null) {
      final stepped = await _detachFromFamily(uid, familyId);
      if (stepped != null) return Failure<void>(stepped);
    }

    // 4. Soft-delete the profile.
    final marked = await _accounts.markDeleted(uid);
    final markFailure = marked.failureOrNull;
    if (markFailure != null) return Failure<void>(markFailure);

    // 5. Delete the Auth user.
    return _auth.deleteAuthUser();
  }

  /// Returns a failure, or `null` when the user is detached (or never was).
  Future<AppFailure?> _detachFromFamily(String uid, String familyId) async {
    final found = await _families.getMember(familyId, uid);
    final findFailure = found.failureOrNull;
    if (findFailure != null) return findFailure;
    final me = found.valueOrNull;
    // Already left / removed / never joined: nothing to do (resume path).
    if (me == null || me.isRemoved) return null;

    if (me.status == MembershipStatus.pending) {
      final cancelled = await _cancelJoinRequest(
        actorUid: uid,
        familyId: familyId,
      );
      return cancelled.failureOrNull;
    }
    if (!me.isActive) return null;

    if (me.isActiveAdmin) {
      final listed = await _families.getMembers(familyId);
      final listFailure = listed.failureOrNull;
      if (listFailure != null) return listFailure;
      final all = listed.valueOrNull ?? const <Member>[];
      final otherAdmins = all.where((m) => m.uid != uid && m.isActiveAdmin);
      if (otherAdmins.isEmpty) {
        final others = all.where(
          (m) => m.uid != uid && m.status != MembershipStatus.disabled,
        );
        if (others.isNotEmpty) {
          return const Conflict(code: 'last_admin_has_members');
        }
        // Solo admin of an otherwise empty family: it stays dormant.
        return null;
      }
    }

    final left = await _leaveFamily(actorUid: uid, familyId: familyId);
    return left.failureOrNull;
  }
}
