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
/// Carries the role as DATA only: what a role may do is decided by
/// `PermissionPolicy` (via `canProvider`), never by testing the role (H7).
class Membership {
  const Membership({
    required this.status,
    this.familyId,
    this.role,
    this.leftAt,
  });

  /// No family at all.
  static const Membership none = Membership(status: MembershipStatus.none);

  final MembershipStatus status;

  /// The family the membership belongs to; `null` when [status] is `none`.
  final String? familyId;

  /// Role in the family; `null` when unknown (no membership, or a test double).
  final MemberRole? role;

  /// When the person left (H10).  A membership that has `leftAt` is reported as
  /// `none` by the mapper, so this is only set on the member document's view;
  /// it lets simple checks avoid loading the full `Member`.
  final DateTime? leftAt;

  /// True when the person has left the family.
  bool get hasLeft => leftAt != null;

  @override
  bool operator ==(Object other) =>
      other is Membership &&
      other.status == status &&
      other.familyId == familyId &&
      other.role == role &&
      other.leftAt == leftAt;

  @override
  int get hashCode => Object.hash(status, familyId, role, leftAt);

  @override
  String toString() => 'Membership($status, family: $familyId, role: $role)';
}
