import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/features/onboarding/domain/user_profile.dart';
import 'package:family_hub/features/onboarding/domain/user_profile_repository.dart';

/// Validates and saves the user's own profile.
class SaveProfile {
  const SaveProfile(this._repository);

  final UserProfileRepository _repository;

  Future<Result<void>> call({
    required String actorUid,
    required UserProfile profile,
    String? familyId,
  }) async {
    if (profile.uid != actorUid) {
      return const Failure<void>(PermissionDenied());
    }
    final name = profile.fullName.trim();
    if (name.isEmpty) {
      return const Failure<void>(Validation('fullName', 'required'));
    }
    if (profile.spouseId == profile.uid) {
      return const Failure<void>(Validation('spouseId', 'invalid'));
    }
    final nickname = profile.nickname?.trim();
    return _repository.saveProfile(
      UserProfile(
        uid: profile.uid,
        fullName: name,
        relationship: profile.relationship,
        nickname: (nickname == null || nickname.isEmpty) ? null : nickname,
        gender: profile.gender,
        spouseId: profile.spouseId,
        avatarKey: profile.avatarKey,
      ),
      familyId: familyId,
    );
  }
}
