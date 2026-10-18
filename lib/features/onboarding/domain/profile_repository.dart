/// Read port for the signed-in user's profile document.
///
/// The Firestore implementation listens to `users/{uid}`.
abstract interface class ProfileRepository {
  /// Emits whether the profile document exists, immediately and on change.
  Stream<bool> watchHasProfile(String uid);
}
