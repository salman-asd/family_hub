import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/features/notifications/presentation/reminder_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PermissionBanner extends ConsumerWidget {
  const PermissionBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final status = ref.watch(reminderPlatformDiagnosticsProvider);
    return Card(
      child: status.when(
        loading: () => ListTile(
          leading: const Icon(Icons.notifications_outlined),
          title: Text(l10n.notificationPermissionChecking),
        ),
        error: (_, _) => ListTile(
          leading: const Icon(Icons.error_outline),
          title: Text(l10n.notificationPermissionUnavailable),
          trailing: IconButton(
            tooltip: l10n.actionRetry,
            onPressed: () =>
                ref.invalidate(reminderPlatformDiagnosticsProvider),
            icon: const Icon(Icons.refresh),
          ),
        ),
        data: (diagnostics) {
          final permissions = diagnostics.permissions;
          final message = !permissions.granted
              ? l10n.notificationPermissionDenied
              : !permissions.exactAlarmsAllowed
              ? l10n.notificationExactAlarmMissing
              : l10n.notificationPermissionGranted;
          final action = !permissions.granted
              ? l10n.notificationAllow
              : !permissions.exactAlarmsAllowed
              ? l10n.notificationAllowExactAlarms
              : null;
          return ListTile(
            leading: Icon(
              !permissions.granted || !permissions.exactAlarmsAllowed
                  ? Icons.notifications_off_outlined
                  : Icons.notifications_active_outlined,
            ),
            title: Text(message),
            trailing: action == null
                ? null
                : TextButton(
                    onPressed: () async {
                      final scheduler = ref.read(reminderSchedulerProvider);
                      if (!permissions.granted) {
                        await scheduler.requestNotifications();
                      } else {
                        await scheduler.requestExactAlarms();
                      }
                      ref.invalidate(reminderPlatformDiagnosticsProvider);
                    },
                    child: Text(action),
                  ),
          );
        },
      ),
    );
  }
}
