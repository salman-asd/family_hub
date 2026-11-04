import 'package:family_hub/core/audit/audit_event_type.dart';

/// Turns the member uids inside a chore audit entry into display names (P3-29).
///
/// Chore events store UIDS in their params (roadmap 3.9), never names, so a
/// renamed member reads correctly. The feed calls this before
/// `activityText`. Dates and other params pass through unchanged; a uid with no
/// known name (a removed member) is left as stored rather than blanked.
Map<String, String> resolveChoreActivityNames(
  String type,
  Map<String, String> params,
  String? Function(String uid) nameOf,
) {
  if (!type.startsWith('chores.')) return params;
  // `from` / `to` are people only on swap and cover events; elsewhere they are
  // dates (availability, generation) and must stay as they are.
  final peopleInFromTo =
      type == AuditEventType.choresSwapRequested ||
      type == AuditEventType.choresSwapAccepted ||
      type == AuditEventType.choresSwapDeclined ||
      type == AuditEventType.choresSwapCancelled ||
      type == AuditEventType.choresSwapExpired ||
      type == AuditEventType.choresCoverAssigned;
  final keys = <String>{'member', if (peopleInFromTo) ...['from', 'to']};
  return <String, String>{
    for (final entry in params.entries)
      entry.key: keys.contains(entry.key)
          ? (nameOf(entry.value) ?? entry.value)
          : entry.value,
  };
}
