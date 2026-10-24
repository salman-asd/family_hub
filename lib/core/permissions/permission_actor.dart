import 'package:family_hub/core/permissions/role.dart';

/// The acting member, reduced to exactly what [PermissionPolicy] needs.
///
/// `core/` must never import a feature, so the policy cannot take the family
/// feature's `Member`.  `Member.permissionActor` builds this view instead, which
/// also keeps the policy trivially unit-testable (no Firestore, no clock).
final class PermissionActor {
  const PermissionActor({
    required this.uid,
    required this.role,
    required this.isActive,
  });

  /// The user id the action is attributed to.
  final String uid;

  final Role role;

  /// False for pending members, disabled members and rejected (soft-deleted)
  /// ones.  A member who is not active may never act.
  final bool isActive;

  bool get isAdmin => isActive && role == Role.admin;
  bool get isModerator => isActive && role == Role.moderator;

  /// Admin or moderator.
  bool get isManager => isAdmin || isModerator;

  @override
  bool operator ==(Object other) =>
      other is PermissionActor &&
      other.uid == uid &&
      other.role == role &&
      other.isActive == isActive;

  @override
  int get hashCode => Object.hash(uid, role, isActive);

  @override
  String toString() => 'PermissionActor($uid, ${role.name}, active: $isActive)';
}
