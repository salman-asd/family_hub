import 'package:family_hub/core/notifications/domain/notification_type.dart';
import 'package:family_hub/core/notifications/domain/planned_notification.dart';
import 'package:family_hub/features/notifications/presentation/reminder_sync_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_reminder_scheduler.dart';

/// P4-25 item 3, second half: two phones of one member planning reminders.
///
/// Nothing here is shared: the plan is a pure function of the family data, and
/// each phone drives its own scheduler and its own `lastPlanHash`. So the risk
/// is not a lost update but a phone reaching across - cancelling, replacing or
/// silencing alarms it does not own. These tests pin that each phone's diff is
/// against its own pending set only.
void main() {
  test(
    'both phones of the same plan end with the same pending alarms',
    () async {
      final left = FakeReminderScheduler();
      final right = FakeReminderScheduler();
      final controllers = <ReminderSyncController>[
        _controller(left),
        _controller(right),
      ];
      final plan = <PlannedNotification>[
        _notification(id: 1),
        _notification(id: 2, category: NotificationCategory.bazar),
      ];

      for (final controller in controllers) {
        await controller.syncNow(plan);
      }

      expect(await right.pending(), await left.pending());
      expect(left.cancelledIds, isEmpty);
      expect(right.cancelledIds, isEmpty);
    },
  );

  test('a phone that re-plans leaves the other phone untouched', () async {
    final left = FakeReminderScheduler();
    final right = FakeReminderScheduler();
    final leftController = _controller(left);
    final rightController = _controller(right);
    final plan = <PlannedNotification>[_notification(id: 1)];

    await rightController.syncNow(plan);
    await leftController.syncNow(plan);
    await leftController.syncNow(<PlannedNotification>[
      _notification(id: 1, title: 'Moved'),
    ]);

    expect(left.cancelledIds, <int>[1]);
    expect(right.cancelledIds, isEmpty);
    expect((await right.pending()).single.title, 'Reminder');
  });

  test('signing out on one phone clears only that phone', () async {
    final left = FakeReminderScheduler();
    final right = FakeReminderScheduler();
    final plan = <PlannedNotification>[
      _notification(id: 1),
      _notification(id: 2, category: NotificationCategory.bazar),
    ];

    await _controller(left).syncNow(plan);
    final rightController = _controller(right);
    await rightController.syncNow(plan);
    await _controller(left).stop();

    expect(await left.pending(), isEmpty);
    expect(await right.pending(), hasLength(2));
  });
}

ReminderSyncController _controller(FakeReminderScheduler scheduler) {
  final controller = ReminderSyncController(
    scheduler: scheduler,
    onError: (_, _) {},
    onSynced: (_) {},
    debounceDuration: Duration.zero,
  );
  addTearDown(controller.dispose);
  return controller;
}

PlannedNotification _notification({
  required int id,
  String title = 'Reminder',
  NotificationCategory category = NotificationCategory.chores,
}) => PlannedNotification(
  id: id,
  kind: category == NotificationCategory.bazar
      ? PlannedNotificationKind.contributionDue
      : PlannedNotificationKind.due,
  scheduledAt: DateTime.utc(2026, 11, 6, 12),
  title: title,
  body: 'Body',
  payload: category == NotificationCategory.bazar
      ? '/bazar/fund'
      : '/chores/today',
  refId: '$id',
  channelId: category == NotificationCategory.bazar
      ? NotificationChannelId.bazar
      : NotificationChannelId.choresDue,
);
