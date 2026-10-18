import 'package:family_hub/features/family/domain/member_role.dart';

/// A user's standing in a family (roadmap 2.3).
enum MembershipStatus {
  /// No membership document: the user has not created or joined a family.
  none,

  /// Joined with a code; waiting for an admin to approve.
  pending,

  /// Approved member.
  active,

  /// Disabled by an admin.
  disabled,
}

/// The current user's membership, as far as routing cares.
///
/// Roles (admin / moderator / member) arrive with Step 9/10; the router only
/// needs the status and which family to read module flags from.
class Membership {
  const Membership({required this.status, this.familyId, this.role});

  /// No family at all.
  static const Membership none = Membership(status: MembershipStatus.none);

  final MembershipStatus status;

  /// The family the membership belongs to; `null` when [status] is `none`.
  final String? familyId;

  /// Role in the family; `null` when unknown (no membership, or a test double).
  final MemberRole? role;

  bool get isAdmin => role == MemberRole.admin;
  bool get isModerator => role == MemberRole.moderator;

  /// Admin or moderator.
  bool get canManageMembers => isAdmin || isModerator;

  @override
  bool operator ==(Object other) =>
      other is Membership &&
      other.status == status &&
      other.familyId == familyId &&
      other.role == role;

  @override
  int get hashCode => Object.hash(status, familyId, role);

  @override
  String toString() => 'Membership($status, family: $familyId, role: $role)';
}
