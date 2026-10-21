import 'package:family_hub/core/audit/audit_event_type.dart';
import 'package:family_hub/core/localization/generated/app_localizations.dart';
import 'package:family_hub/core/localization/role_labels.dart';
import 'package:family_hub/core/permissions/role.dart';

/// Localizes an activity / audit entry from its machine `type` + `params`
/// (H10, CLAUDE.md rule 18): an event never stores display text, so the same
/// entry reads correctly in Bangla and in English.
///
/// A missing param renders as an empty string and an unknown type as a neutral
/// sentence, so an entry written by a newer app version never breaks a screen.
extension ActivityText on AppLocalizations {
  String activityText(String type, Map<String, String> params) {
    String p(String key) => params[key] ?? '';
    return switch (type) {
      AuditEventType.familyCreated => activityFamilyCreated(p('familyName')),
      AuditEventType.familyUpdated => activityFamilyUpdated,
      AuditEventType.memberRequested => activityMemberRequested(p('memberName')),
      AuditEventType.memberApproved => activityMemberApproved(p('memberName')),
      AuditEventType.memberRejected => activityMemberRejected(p('memberName')),
      AuditEventType.memberDisabled => activityMemberDisabled(p('memberName')),
      AuditEventType.memberRoleChanged => activityMemberRoleChanged(
          p('memberName'),
          _roleName(p('newRole')),
        ),
      AuditEventType.memberAdminTransferred =>
        activityAdminTransferred(p('memberName')),
      AuditEventType.memberLeft => activityMemberLeft(p('memberName')),
      AuditEventType.memberCancelled => activityMemberCancelled(p('memberName')),
      AuditEventType.invitationCreated => activityInvitationCreated(p('code')),
      AuditEventType.invitationRevoked => activityInvitationRevoked(p('code')),
      _ => activityUnknown,
    };
  }

  String _roleName(String stored) {
    for (final r in Role.values) {
      if (r.name == stored) return roleLabel(r);
    }
    return stored;
  }
}
