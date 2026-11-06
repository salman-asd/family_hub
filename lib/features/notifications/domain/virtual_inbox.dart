import 'package:family_hub/features/notifications/domain/inbox_item.dart';

/// Types for local-only inbox entries. These values are never written to
/// `notificationInbox`; persisted rows remain constrained by [InboxType.all].
abstract final class VirtualInboxType {
  static const String budgetAlert = 'virtual_budget_alert';
  static const String pendingJoinRequests = 'virtual_pending_join_requests';
  static const String pendingContributionRequests =
      'virtual_pending_contribution_requests';
  static const String contributionDue = 'virtual_contribution_due';
  static const String awaitingVerification = 'virtual_awaiting_verification';
}

/// Creates stable, month-scoped inbox entries from causes already loaded by
/// the feature providers. A cause disappearing removes its virtual row.
abstract final class VirtualInbox {
  static List<InboxItem> build({
    required String monthKey,
    required String viewerId,
    required DateTime now,
    required Set<String> acknowledgedIds,
    int? budgetPercent,
    int pendingJoinRequests = 0,
    int pendingContributionRequests = 0,
    bool contributionDue = false,
    int awaitingVerification = 0,
  }) {
    final items = <InboxItem>[];

    void add({
      required String id,
      required String type,
      required String refType,
      required String refId,
      Map<String, String> params = const <String, String>{},
    }) {
      items.add(
        InboxItem(
          id: id,
          toMemberId: viewerId,
          type: type,
          refType: refType,
          refId: refId,
          createdAt: now,
          params: params,
          readAt: acknowledgedIds.contains(id) ? now : null,
        ),
      );
    }

    if (budgetPercent != null && budgetPercent > 0) {
      add(
        id: 'v:budget:$monthKey',
        type: VirtualInboxType.budgetAlert,
        refType: 'budget',
        refId: monthKey,
        params: <String, String>{'percent': '$budgetPercent'},
      );
    }
    if (pendingJoinRequests > 0) {
      add(
        id: 'v:join:$monthKey',
        type: VirtualInboxType.pendingJoinRequests,
        refType: 'member',
        refId: monthKey,
        params: <String, String>{'count': '$pendingJoinRequests'},
      );
    }
    if (pendingContributionRequests > 0) {
      add(
        id: 'v:contribution-requests:$monthKey',
        type: VirtualInboxType.pendingContributionRequests,
        refType: 'contribution',
        refId: monthKey,
        params: <String, String>{'count': '$pendingContributionRequests'},
      );
    }
    if (contributionDue) {
      add(
        id: 'v:contribution-due:$monthKey:$viewerId',
        type: VirtualInboxType.contributionDue,
        refType: 'contributionPlan',
        refId: '${monthKey}_$viewerId',
      );
    }
    if (awaitingVerification > 0) {
      add(
        id: 'v:verification:$monthKey',
        type: VirtualInboxType.awaitingVerification,
        refType: 'occurrence',
        refId: monthKey,
        params: <String, String>{'count': '$awaitingVerification'},
      );
    }
    return List<InboxItem>.unmodifiable(items);
  }
}
