import 'package:family_hub/features/notifications/domain/inbox_item.dart';
import 'package:family_hub/features/notifications/domain/inbox_port.dart';
import 'package:family_hub/features/notifications/domain/virtual_inbox.dart';

/// Merges and orders inbox rows while respecting the enabled family modules.
List<InboxItem> buildVisibleInboxItems({
  required List<InboxItem> stored,
  required List<InboxItem> virtual,
  required bool choresEnabled,
  required bool bazarEnabled,
}) {
  final items = <InboxItem>[...stored, ...virtual];
  items.removeWhere((item) {
    if (item.type == VirtualInboxType.budgetAlert ||
        item.type == VirtualInboxType.pendingContributionRequests ||
        item.type == VirtualInboxType.contributionDue) {
      return !bazarEnabled;
    }
    if (item.type == VirtualInboxType.awaitingVerification ||
        item.type == InboxType.choreAssigned ||
        item.type == InboxType.swapRequest ||
        item.type == InboxType.swapResult ||
        item.type == InboxType.needsCover ||
        item.type == InboxType.choreReopened ||
        item.type == InboxType.commentAttention ||
        item.type == InboxType.verificationNeeded ||
        item.type == InboxType.absenceDecision) {
      return !choresEnabled;
    }
    return false;
  });
  items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return List<InboxItem>.unmodifiable(items);
}
