import 'package:family_hub/core/errors/result.dart';

/// Port for the signed-in user's own account document (`users/{uid}`), H9.
abstract interface class AccountRepository {
  /// Soft-deletes the account (CLAUDE.md rule 5): sets `deletedAt` /
  /// `deletedBy` and clears the profile fields that history does not need
  /// (nickname, gender, spouse, avatar).  The display name stays on the member
  /// documents so past expenses and chores remain explainable (decision D2).
  ///
  /// Idempotent: calling it again changes nothing that matters.
  Future<Result<void>> markDeleted(String uid);

  /// True once [markDeleted] has run for [uid].  Used to resume a deletion
  /// whose last step (deleting the Auth user) failed.
  Stream<bool> watchMarkedDeleted(String uid);
}
