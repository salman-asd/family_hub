/// The closed set of audit/activity event types (H5).
///
/// Mirror of `eventTypes()` in `firebase/firestore.rules`; the two lists are
/// compared by `test/core/audit/audit_event_type_test.dart`, so a new type here
/// that is missing from the rules (or the other way round) fails the build.
///
/// These are machine values.  A screen localizes them by type + params; an
/// event never carries display text (CLAUDE.md rule 18).
abstract final class AuditEventType {
  static const String familyCreated = 'family.created';
  static const String familyUpdated = 'family.updated';
  static const String memberRequested = 'member.requested';
  static const String memberApproved = 'member.approved';
  static const String memberRejected = 'member.rejected';
  static const String memberDisabled = 'member.disabled';
  static const String memberRoleChanged = 'member.role_changed';
  static const String memberAdminTransferred = 'member.admin_transferred';
  static const String memberLeft = 'member.left';
  static const String memberCancelled = 'member.cancelled';
  static const String invitationCreated = 'invitation.created';
  static const String invitationRevoked = 'invitation.revoked';

  /// Every type, in the same order as the rules list.
  static const List<String> all = <String>[
    familyCreated,
    memberRequested,
    memberApproved,
    memberRejected,
    memberDisabled,
    memberRoleChanged,
    memberAdminTransferred,
    memberLeft,
    memberCancelled,
    invitationCreated,
    invitationRevoked,
    familyUpdated,
  ];
}
