import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/features/onboarding/domain/user_profile.dart';

/// Read/write port for `users/{uid}`.  (The router's existence check lives in
/// `ProfileRepository`; the Firestore class implements both.)
abstract interface class UserProfileRepository {
  Future<Result<UserProfile?>> getProfile(String uid);
  Stream<UserProfile?> watchProfile(String uid);

  /// Saves the profile.  When [familyId] is given the denormalised member
  /// document is updated in the same batch.
  Future<Result<void>> saveProfile(UserProfile profile, {String? familyId});
}
