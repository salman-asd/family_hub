import 'package:family_hub/features/family/domain/relationship.dart';

/// The signed-in user's profile (`users/{uid}`).
class UserProfile {
  const UserProfile({
    required this.uid,
    required this.fullName,
    required this.relationship,
    this.nickname,
    this.gender,
    this.spouseId,
    this.avatarKey,
  });

  final String uid;
  final String fullName;
  final RelationshipId relationship;
  final String? nickname;
  final Gender? gender;

  /// uid of the spouse (another family member); may stay empty.
  final String? spouseId;

  /// Preset avatar key like `p3`; `null` means initials on a stable colour.
  final String? avatarKey;

  @override
  bool operator ==(Object other) =>
      other is UserProfile &&
      other.uid == uid &&
      other.fullName == fullName &&
      other.relationship == relationship &&
      other.nickname == nickname &&
      other.gender == gender &&
      other.spouseId == spouseId &&
      other.avatarKey == avatarKey;

  @override
  int get hashCode => Object.hash(
        uid,
        fullName,
        relationship,
        nickname,
        gender,
        spouseId,
        avatarKey,
      );
}
