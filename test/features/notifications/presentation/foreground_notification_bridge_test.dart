import 'package:family_hub/core/notifications/domain/planned_notification.dart';
import 'package:family_hub/features/notifications/presentation/foreground_notification_bridge.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../support/fake_reminder_scheduler.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'normal and push delivery share persisted inbox-id deduplication',
    () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final scheduler = FakeReminderScheduler();
      final bridge = ForegroundNotificationBridge(
        scheduler: scheduler,
        preferences: preferences,
        viewerId: 'member-1',
      );
      final notification = PlannedNotification(
        id: 21,
        kind: PlannedNotificationKind.nudge,
        scheduledAt: DateTime.utc(2026, 11, 12),
        title: 'Family Hub',
        body: 'A new notification',
        payload: '/inbox',
        refId: 'inbox-1',
        channelId: NotificationChannelId.pushEvents,
      );

      expect(await bridge.showOnce('inbox-1', notification), isTrue);
      final resumedBridge = ForegroundNotificationBridge(
        scheduler: scheduler,
        preferences: preferences,
        viewerId: 'member-1',
      );
      expect(await resumedBridge.showOnce('inbox-1', notification), isFalse);
      expect(scheduler.showNowCalls, 1);
    },
  );

  test('notification ids are scoped to the viewer', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final scheduler = FakeReminderScheduler();
    final notification = PlannedNotification(
      id: 21,
      kind: PlannedNotificationKind.nudge,
      scheduledAt: DateTime.utc(2026, 11, 12),
      title: 'Family Hub',
      body: 'A new notification',
      payload: '/inbox',
      refId: 'inbox-1',
      channelId: NotificationChannelId.family,
    );

    final first = ForegroundNotificationBridge(
      scheduler: scheduler,
      preferences: preferences,
      viewerId: 'member-1',
    );
    final second = ForegroundNotificationBridge(
      scheduler: scheduler,
      preferences: preferences,
      viewerId: 'member-2',
    );

    expect(await first.showOnce('inbox-1', notification), isTrue);
    expect(await second.showOnce('inbox-1', notification), isTrue);
    expect(scheduler.showNowCalls, 2);
  });
}
