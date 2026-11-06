import 'package:family_hub/app/routing/app_routes.dart';
import 'package:family_hub/core/audit/audit_event_type.dart';
import 'package:family_hub/core/audit/audit_ref_type.dart';
import 'package:family_hub/features/activity/domain/activity_entry.dart';

enum _ActivityTargetKind { expense, occurrence, member }

/// Navigation target for an activity row. Unknown reference types and missing
/// ids intentionally have no target; destination screens handle deleted rows.
final class ActivityTarget {
  const ActivityTarget(this.location);

  final String location;

  static const Map<String, _ActivityTargetKind?> _referenceDecisions =
      <String, _ActivityTargetKind?>{
        AuditRefType.family: null,
        AuditRefType.member: _ActivityTargetKind.member,
        AuditRefType.invitation: null,
        AuditRefType.category: null,
        AuditRefType.item: null,
        AuditRefType.expense: _ActivityTargetKind.expense,
        AuditRefType.trip: null,
        AuditRefType.budget: null,
        AuditRefType.contribution: null,
        AuditRefType.contributionPlan: null,
        AuditRefType.settlement: null,
        AuditRefType.month: null,
        AuditRefType.importBatch: null,
        AuditRefType.choreSettings: null,
        AuditRefType.choreTemplate: null,
        AuditRefType.dutyGroup: null,
        AuditRefType.occurrence: _ActivityTargetKind.occurrence,
        AuditRefType.comment: null,
        AuditRefType.availability: null,
        AuditRefType.swapRequest: null,
        AuditRefType.notificationSettings: null,
        AuditRefType.dashboardSettings: null,
        AuditRefType.engagementSettings: null,
      };

  /// Whether this known reference type has an explicit navigation decision.
  static bool hasDecisionFor(String refType) =>
      _referenceDecisions.containsKey(refType);

  static ActivityTarget? from(ActivityEntry entry) {
    if (entry.refId.trim().isEmpty) return null;
    if (entry.type == AuditEventType.bazarExpenseDeleted) return null;
    final kind = _referenceDecisions[entry.refType];
    if (kind == null) return null;
    final path = switch (kind) {
      _ActivityTargetKind.expense => AppRoutes.bazarExpense(entry.refId),
      _ActivityTargetKind.occurrence => AppRoutes.choresOccurrence(entry.refId),
      _ActivityTargetKind.member => AppRoutes.memberProfile(entry.refId),
    };
    return ActivityTarget(path);
  }
}
