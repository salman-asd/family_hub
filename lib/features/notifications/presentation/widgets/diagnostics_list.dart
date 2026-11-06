import 'package:family_hub/core/localization/l10n_ext.dart';

import 'package:family_hub/core/notifications/presentation/push_providers.dart';
import 'package:family_hub/features/family/presentation/family_providers.dart';
import 'package:family_hub/features/notifications/presentation/reminder_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DiagnosticsList extends ConsumerWidget {
  const DiagnosticsList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final local = ref.watch(reminderPlatformDiagnosticsProvider);
    final reminders = ref.watch(reminderDiagnosticsProvider);
    final push = ref.watch(pushDiagnosticsProvider);
    final timezone = ref.watch(familyTimezoneProvider);
    final formatters = ref.watch(appFormattersProvider);
    final rows = <Widget>[
      local.when(
        loading: () =>
            ListTile(title: Text(l10n.notificationDiagnosticsLoading)),
        error: (_, _) => ListTile(
          title: Text(l10n.notificationPermissionUnavailable),
          trailing: IconButton(
            tooltip: l10n.actionRetry,
            onPressed: () =>
                ref.invalidate(reminderPlatformDiagnosticsProvider),
            icon: const Icon(Icons.refresh),
          ),
        ),
        data: (value) => Column(
          children: [
            ListTile(
              leading: Icon(
                value.permissions.granted
                    ? Icons.notifications_active_outlined
                    : Icons.notifications_off_outlined,
              ),
              title: Text(l10n.notificationPermissionLabel),
              subtitle: Text(
                value.permissions.granted
                    ? l10n.notificationPermissionGranted
                    : l10n.notificationPermissionDenied,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.alarm_outlined),
              title: Text(l10n.notificationExactAlarmLabel),
              subtitle: Text(
                value.permissions.exactAlarmsAllowed
                    ? l10n.notificationPermissionGranted
                    : l10n.notificationExactAlarmMissing,
              ),
              trailing: !value.permissions.exactAlarmsAllowed
                  ? IconButton(
                      tooltip: l10n.notificationAllowExactAlarms,
                      onPressed: () async {
                        await ref
                            .read(reminderSchedulerProvider)
                            .openExactAlarmSettings();
                        ref.invalidate(reminderPlatformDiagnosticsProvider);
                      },
                      icon: const Icon(Icons.open_in_new),
                    )
                  : null,
            ),
            ListTile(
              leading: const Icon(Icons.battery_saver_outlined),
              title: Text(l10n.notificationBatteryLabel),
              trailing: IconButton(
                tooltip: l10n.notificationOpenSettings,
                onPressed: () =>
                    ref.read(reminderSchedulerProvider).openBatterySettings(),
                icon: const Icon(Icons.open_in_new),
              ),
            ),
            ListTile(
              title: Text(l10n.notificationPendingCount),
              subtitle: Text(
                formatters.number(value.pendingCount ?? reminders.pendingCount),
              ),
            ),
            if (value.nextFireAt != null)
              ListTile(
                title: Text(l10n.notificationNextScheduled),
                subtitle: Text(
                  '${formatters.fullDate(value.nextFireAt!.toLocal())} '
                  '${formatters.timeOfDay(value.nextFireAt!.toLocal().hour * 60 + value.nextFireAt!.toLocal().minute)}',
                ),
              ),
            if (value.androidSdkVersion != null)
              ListTile(
                title: Text(l10n.notificationAndroidVersion),
                subtitle: Text(formatters.number(value.androidSdkVersion!)),
              ),
          ],
        ),
      ),
      push.when(
        loading: () =>
            ListTile(title: Text(l10n.notificationDiagnosticsLoading)),
        error: (_, _) =>
            ListTile(title: Text(l10n.notificationPushUnavailable)),
        data: (value) => Column(
          children: [
            ListTile(
              leading: const Icon(Icons.cloud_outlined),
              title: Text(l10n.notificationPushToken),
              subtitle: Text(
                value.tokenRegistered
                    ? l10n.notificationPushTokenPresent
                    : l10n.notificationPushTokenMissing,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.mark_email_read_outlined),
              title: Text(l10n.notificationLastPushReceived),
              subtitle: Text(
                value.lastReceivedMessage == null
                    ? l10n.notificationNever
                    : '${formatters.fullDate(value.lastReceivedMessage!.toLocal())} '
                          '${formatters.timeOfDay(value.lastReceivedMessage!.toLocal().hour * 60 + value.lastReceivedMessage!.toLocal().minute)}',
              ),
            ),
            if (value.lastError != null)
              ListTile(
                leading: const Icon(Icons.error_outline),
                title: Text(l10n.notificationLastError),
                subtitle: Text(value.lastError!),
              ),
          ],
        ),
      ),
      ListTile(
        leading: const Icon(Icons.schedule_outlined),
        title: Text(l10n.notificationTimezone),
        subtitle: Text(timezone),
      ),
      if (reminders.lastError != null)
        ListTile(
          leading: const Icon(Icons.error_outline),
          title: Text(l10n.notificationReminderError),
          subtitle: Text(reminders.lastError!),
        ),
    ];
    return Column(children: rows);
  }
}
