import 'package:family_hub/core/audit/audit_event_type.dart';
import 'package:family_hub/core/localization/generated/app_localizations.dart';

/// The Phase 3 chore activity sentences (road map 3.9).
///
/// Kept apart from `activity_text.dart` so neither file passes the 300-line
/// limit. `ActivityText.activityText` delegates every type it does not know to
/// [activityChoresText]; a `null` result means "not a chore type".
extension ActivityTextChores on AppLocalizations {
  /// The sentence for a chore [type], or `null` when [type] is not a chore
  /// event.
  String? activityChoresText(String type, Map<String, String> params) {
    String p(String key) => params[key] ?? '';
    return switch (type) {
      AuditEventType.choresSettingsUpdated => activityChoresSettingsUpdated,
      AuditEventType.choresRotationPolicyUpdated =>
        activityChoresRotationPolicyUpdated,
      AuditEventType.choresTemplateCreated => activityChoresTemplateCreated(
        p('name'),
      ),
      AuditEventType.choresTemplateUpdated => activityChoresTemplateUpdated(
        p('name'),
      ),
      AuditEventType.choresTemplatePaused => activityChoresTemplatePaused(
        p('name'),
      ),
      AuditEventType.choresTemplateResumed => activityChoresTemplateResumed(
        p('name'),
      ),
      AuditEventType.choresTemplateArchived => activityChoresTemplateArchived(
        p('name'),
      ),
      AuditEventType.choresTemplateDuplicated =>
        activityChoresTemplateDuplicated(p('name')),
      AuditEventType.choresStarterPackApplied =>
        activityChoresStarterPackApplied(p('templates'), p('groups')),
      AuditEventType.choresDutyGroupCreated => activityChoresDutyGroupCreated(
        p('name'),
      ),
      AuditEventType.choresDutyGroupUpdated => activityChoresDutyGroupUpdated(
        p('name'),
      ),
      AuditEventType.choresRotationChanged => activityChoresRotationChanged(
        p('name'),
      ),
      AuditEventType.choresOccurrencesGenerated =>
        activityChoresOccurrencesGenerated(p('from'), p('to'), p('count')),
      AuditEventType.choresOccurrencesReplanned =>
        activityChoresOccurrencesReplanned(p('name'), p('from')),
      AuditEventType.choresOccurrenceCompleted =>
        activityChoresOccurrenceCompleted(p('member'), p('name'), p('date')),
      AuditEventType.choresOccurrenceUncompleted =>
        activityChoresOccurrenceUncompleted(p('member'), p('name'), p('date')),
      AuditEventType.choresOccurrenceVerified =>
        activityChoresOccurrenceVerified(p('member'), p('name'), p('date')),
      AuditEventType.choresOccurrenceReopened =>
        activityChoresOccurrenceReopened(p('member'), p('name'), p('date')),
      AuditEventType.choresOccurrenceException =>
        activityChoresOccurrenceException(p('member'), p('name'), p('date')),
      AuditEventType.choresOccurrenceSkipped => activityChoresOccurrenceSkipped(
        p('member'),
        p('name'),
        p('date'),
      ),
      AuditEventType.choresOccurrenceUnskipped =>
        activityChoresOccurrenceUnskipped(p('member'), p('name'), p('date')),
      AuditEventType.choresOccurrenceReassigned =>
        activityChoresOccurrenceReassigned(p('member'), p('name'), p('date')),
      AuditEventType.choresCommentAdded => activityChoresCommentAdded(
        p('member'),
        p('name'),
        p('date'),
      ),
      AuditEventType.choresCommentHidden => activityChoresCommentHidden(
        p('member'),
        p('name'),
        p('date'),
      ),
      AuditEventType.choresAvailabilityAdded => activityChoresAvailabilityAdded(
        p('member'),
        p('from'),
        p('to'),
      ),
      AuditEventType.choresAvailabilityCancelled =>
        activityChoresAvailabilityCancelled(p('member'), p('from'), p('to')),
      AuditEventType.choresAvailabilityDecided =>
        activityChoresAvailabilityDecided(p('member'), p('from'), p('to')),
      AuditEventType.choresSwapRequested => activityChoresSwapRequested(
        p('member'),
        p('to'),
        p('name'),
        p('date'),
      ),
      AuditEventType.choresSwapAccepted => activityChoresSwapAccepted(
        p('to'),
        p('name'),
        p('date'),
      ),
      AuditEventType.choresSwapDeclined => activityChoresSwapDeclined(
        p('to'),
        p('name'),
        p('date'),
      ),
      AuditEventType.choresSwapCancelled => activityChoresSwapCancelled(
        p('member'),
        p('name'),
        p('date'),
      ),
      AuditEventType.choresSwapExpired => activityChoresSwapExpired(
        p('name'),
        p('date'),
      ),
      AuditEventType.choresCoverAssigned => activityChoresCoverAssigned(
        p('to'),
        p('name'),
        p('date'),
      ),
      _ => null,
    };
  }
}
