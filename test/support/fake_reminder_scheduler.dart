import 'package:family_hub/core/notifications/domain/notification_type.dart';
import 'package:family_hub/core/notifications/domain/planned_notification.dart';
import 'package:family_hub/core/notifications/domain/reminder_scheduler.dart';

final class FakeReminderScheduler implements ReminderScheduler {
  final Map<int, PlannedNotification> _pending = <int, PlannedNotification>{};
  final List<PlannedNotification> scheduled = <PlannedNotification>[];
  final List<int> cancelledIds = <int>[];
  final List<NotificationCategory?> cancelledAll = <NotificationCategory?>[];
  int pendingCalls = 0;
  int requestNotificationsCalls = 0;
  int requestExactAlarmsCalls = 0;
  int showNowCalls = 0;
  int batterySettingsCalls = 0;
  int exactAlarmSettingsCalls = 0;
  bool failOnPending = false;
  Future<void> Function()? beforePending;
  NotificationPermissionState permissionState =
      const NotificationPermissionState(
        granted: true,
        exactAlarmsAllowed: true,
      );
  bool notificationsRequestResult = true;
  bool exactAlarmsRequestResult = true;

  @override
  Future<List<PlannedNotification>> pending() async {
    pendingCalls++;
    await beforePending?.call();
    if (failOnPending) throw StateError('pending failed');
    return List<PlannedNotification>.unmodifiable(_pending.values);
  }

  @override
  Future<void> schedule(PlannedNotification notification) async {
    scheduled.add(notification);
    _pending[notification.id] = notification;
  }

  @override
  Future<void> cancel(List<int> ids) async {
    cancelledIds.addAll(ids);
    for (final id in ids) {
      _pending.remove(id);
    }
  }

  @override
  Future<void> cancelAll({NotificationCategory? category}) async {
    cancelledAll.add(category);
    if (category == null) {
      _pending.clear();
      return;
    }
    final channels = switch (category) {
      NotificationCategory.chores => <NotificationChannelId>{
        NotificationChannelId.choresDue,
        NotificationChannelId.choresOverdue,
        NotificationChannelId.dailySummary,
      },
      NotificationCategory.bazar => <NotificationChannelId>{
        NotificationChannelId.bazar,
      },
      NotificationCategory.family => <NotificationChannelId>{
        NotificationChannelId.family,
      },
    };
    _pending.removeWhere(
      (_, notification) => channels.contains(notification.channelId),
    );
  }

  @override
  Future<NotificationPermissionState> permissions() async => permissionState;

  @override
  Future<void> showNow(PlannedNotification notification) async {
    showNowCalls++;
  }

  @override
  Future<bool> requestNotifications() async {
    requestNotificationsCalls++;
    return notificationsRequestResult;
  }

  @override
  Future<bool> requestExactAlarms() async {
    requestExactAlarmsCalls++;
    return exactAlarmsRequestResult;
  }

  @override
  Future<ReminderPlatformDiagnostics> diagnostics() async =>
      ReminderPlatformDiagnostics(
        permissions: permissionState,
        pendingCount: _pending.length,
      );

  @override
  Future<void> openBatterySettings() async {
    batterySettingsCalls++;
  }

  @override
  Future<void> openExactAlarmSettings() async {
    exactAlarmSettingsCalls++;
  }
}
