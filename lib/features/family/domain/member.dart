import 'package:family_hub/core/permissions/permissions.dart';
import 'package:family_hub/features/family/domain/member_role.dart';
import 'package:family_hub/features/family/domain/membership.dart';

/// A person's membership document in a family (`families/{id}/members/{uid}`).
///
/// Name fields are denormalised from the profile so the members list never has
/// to read other people's user documents.
class Member {
  const Member({
    required this.uid,
    required this.role,
    required this.status,
    required this.fullName,
    required this.relationship,
    this.nickname,
    this.spouseId,
    this.avatarKey,
    this.inviteCode,
    this.removedAt,
  });

  final String uid;
  final MemberRole role;

  /// `pending`, `active` or `disabled` (never `none`).
  final MembershipStatus status;
  final String fullName;
  final String relationship;
  final String? nickname;
  final String? spouseId;
  final String? avatarKey;

  /// Code used to join; checked by the security rules.
  final String? inviteCode;

  /// Set when an admin rejected the request (soft delete).
  final DateTime? removedAt;

  bool get isRemoved => removedAt != null;
  bool get isActive => status == MembershipStatus.active && !isRemoved;
  bool get isActiveAdmin => isActive && role == MemberRole.admin;

  /// This member as the permission policy sees them (Step 10).
  PermissionActor get permissionActor => PermissionActor(
        uid: uid,
        role: role,
        isActive: isActive,
      );

  /// Short name for lists.
  String get displayName =>
      (nickname != null && nickname!.trim().isNotEmpty) ? nickname! : fullName;

  Member copyWith({
    MemberRole? role,
    MembershipStatus? status,
    String? fullName,
    String? relationship,
    String? nickname,
    String? spouseId,
    String? avatarKey,
    DateTime? removedAt,
  }) =>
      Member(
        uid: uid,
        role: role ?? this.role,
        status: status ?? this.status,
        fullName: fullName ?? this.fullName,
        relationship: relationship ?? this.relationship,
        nickname: nickname ?? this.nickname,
        spouseId: spouseId ?? this.spouseId,
        avatarKey: avatarKey ?? this.avatarKey,
        inviteCode: inviteCode,
        removedAt: removedAt ?? this.removedAt,
      );

  @override
  bool operator ==(Object other) =>
      other is Member &&
      other.uid == uid &&
      other.role == role &&
      other.status == status &&
      other.fullName == fullName &&
      other.relationship == relationship &&
      other.nickname == nickname &&
      other.spouseId == spouseId &&
      other.avatarKey == avatarKey &&
      other.inviteCode == inviteCode &&
      other.removedAt == removedAt;

  @override
  int get hashCode => Object.hash(uid, role, status, fullName, relationship,
      nickname, spouseId, avatarKey, inviteCode, removedAt);

  @override
  String toString() => 'Member($uid, $role, $status)';
}
