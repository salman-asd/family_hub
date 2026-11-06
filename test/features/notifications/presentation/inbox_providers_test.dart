import 'package:family_hub/features/notifications/domain/inbox_item.dart';
import 'package:family_hub/features/notifications/domain/inbox_port.dart';
import 'package:family_hub/features/notifications/domain/inbox_visibility.dart';
import 'package:family_hub/features/notifications/domain/virtual_inbox.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  InboxItem item(String id, String type, int day) => InboxItem(
    id: id,
    toMemberId: 'member-1',
    type: type,
    refType: 'member',
    refId: 'member-1',
    createdAt: DateTime.utc(2026, 11, day),
  );

  test(
    'hides disabled-module rows and keeps family rows in newest-first order',
    () {
      final visible = buildVisibleInboxItems(
        stored: <InboxItem>[
          item('old', InboxType.memberApproved, 2),
          item('chore', InboxType.choreAssigned, 3),
        ],
        virtual: <InboxItem>[
          item('budget', VirtualInboxType.budgetAlert, 4),
          item('joins', VirtualInboxType.pendingJoinRequests, 5),
          item('verify', VirtualInboxType.awaitingVerification, 6),
        ],
        choresEnabled: false,
        bazarEnabled: false,
      );

      expect(visible.map((row) => row.id), <String>['joins', 'old']);
    },
  );

  test('merges and orders stored and virtual entries newest first', () {
    final visible = buildVisibleInboxItems(
      stored: <InboxItem>[item('stored', InboxType.memberApproved, 3)],
      virtual: <InboxItem>[item('virtual', VirtualInboxType.budgetAlert, 5)],
      choresEnabled: true,
      bazarEnabled: true,
    );

    expect(visible.map((row) => row.id), <String>['virtual', 'stored']);
  });
}
