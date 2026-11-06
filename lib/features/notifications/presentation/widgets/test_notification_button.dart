import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/core/notifications/domain/notification_id_factory.dart';
import 'package:family_hub/core/notifications/domain/planned_notification.dart';
import 'package:family_hub/core/utils/clock_provider.dart';
import 'package:family_hub/features/family/presentation/family_providers.dart';
import 'package:family_hub/features/notifications/presentation/reminder_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TestNotificationButton extends ConsumerWidget {
  const TestNotificationButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return FilledButton.tonalIcon(
      key: const Key('notification_test'),
      onPressed: () async {
        final uid = ref.read(currentUidProvider) ?? 'local';
        final now = ref.read(clockProvider).nowUtc();
        final notification = PlannedNotification(
          id: NotificationIdFactory.of(
            'test',
            uid,
            now.microsecondsSinceEpoch.toString(),
          ),
          kind: PlannedNotificationKind.due,
          scheduledAt: now.add(const Duration(seconds: 10)),
          title: l10n.notificationTestTitle,
          body: l10n.notificationTestBody,
          payload: '',
          refId: 'test',
          channelId: NotificationChannelId.family,
        );
        try {
          await ref.read(reminderSchedulerProvider).schedule(notification);
          ref.invalidate(reminderPlatformDiagnosticsProvider);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.notificationTestScheduled)),
            );
          }
        } on Object catch (error, stackTrace) {
          ref
              .read(reminderDiagnosticsProvider.notifier)
              .recordError(error, stackTrace);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.notificationTestFailed)),
            );
          }
        }
      },
      icon: const Icon(Icons.notifications_active_outlined),
      label: Text(l10n.notificationTestButton),
    );
  }
}
