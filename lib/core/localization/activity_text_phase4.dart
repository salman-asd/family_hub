import 'package:family_hub/core/audit/audit_event_type.dart';
import 'package:family_hub/core/localization/generated/app_localizations.dart';

/// The Phase 4 activity sentences (road map 3.9, P4-02).
///
/// Kept apart from `activity_text.dart` so that file stays under the 300-line
/// limit. `ActivityText.activityText` hands every type it does not know to
/// [activityPhase4Text]; a `null` result means "not a Phase 4 type".
///
/// Params: only `engagement.privacy_updated` has one, `visibility`, which is
/// the stored value (`private` or `levels`). The other four have no params.
extension ActivityTextPhase4 on AppLocalizations {
  /// The sentence for a Phase 4 [type], or `null` when [type] is not one.
  String? activityPhase4Text(String type, Map<String, String> params) {
    return switch (type) {
      AuditEventType.familyNotificationDefaultsUpdated =>
        activityNotificationDefaultsUpdated,
      AuditEventType.familyNotificationDeliveryUpdated =>
        activityNotificationDeliveryUpdated,
      AuditEventType.familyDashboardPolicyUpdated =>
        activityDashboardPolicyUpdated,
      AuditEventType.engagementSettingsUpdated =>
        activityEngagementSettingsUpdated,
      AuditEventType.engagementPrivacyUpdated =>
        activityEngagementPrivacyUpdated(
          _visibilityName(params['visibility'] ?? ''),
        ),
      _ => null,
    };
  }

  /// `statsVisibility` values from road map 3.2; an unknown value is shown as
  /// stored so a newer app version never breaks the feed.
  String _visibilityName(String stored) => switch (stored) {
    'private' => engagementVisibilityPrivate,
    'levels' => engagementVisibilityLevels,
    _ => stored,
  };
}
