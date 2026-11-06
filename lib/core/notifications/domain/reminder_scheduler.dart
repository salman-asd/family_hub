import 'package:family_hub/core/notifications/domain/notification_type.dart';
import 'package:family_hub/core/notifications/domain/planned_notification.dart';

final class NotificationPermissionState {
  const NotificationPermissionState({
    required this.granted,
    required this.exactAlarmsAllowed,
  });

  final bool granted;
  final bool exactAlarmsAllowed;
}

final class ReminderPlatformDiagnostics {
  const ReminderPlatformDiagnostics({
    required this.permissions,
    this.pendingCount,
    this.nextFireAt,
    this.lastError,
    this.androidSdkVersion,
  });

  final NotificationPermissionState permissions;
  final int? pendingCount;
  final DateTime? nextFireAt;
  final String? lastError;
  final int? androidSdkVersion;
}

abstract interface class ReminderScheduler {
  Future<List<PlannedNotification>> pending();

  Future<void> schedule(PlannedNotification notification);

  Future<void> cancel(List<int> ids);

  Future<void> cancelAll({NotificationCategory? category});

  Future<NotificationPermissionState> permissions();

  Future<void> showNow(PlannedNotification notification);

  Future<bool> requestNotifications();

  Future<bool> requestExactAlarms();

  Future<ReminderPlatformDiagnostics> diagnostics();

  Future<void> openBatterySettings();

  Future<void> openExactAlarmSettings();
}
