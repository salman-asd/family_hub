import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/core/notifications/domain/reminder_settings.dart';
import 'package:flutter/material.dart';

class CategorySection extends StatelessWidget {
  const CategorySection({
    required this.settings,
    required this.onChanged,
    super.key,
  });

  final ReminderSettings settings;
  final ValueChanged<ReminderSettings> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      children: [
        SwitchListTile(
          key: const Key('notifications_chores'),
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.notificationCategoryChores),
          subtitle: !settings.globalEnabled || !settings.choresEnabled
              ? Text(
                  !settings.globalEnabled
                      ? l10n.notificationMasterOffReason
                      : l10n.notificationCategoryOffReason,
                )
              : null,
          isThreeLine: !settings.globalEnabled || !settings.choresEnabled,
          value: settings.choresEnabled,
          onChanged: (value) =>
              onChanged(settings.copyWith(choresEnabled: value)),
        ),
        SwitchListTile(
          key: const Key('notifications_bazar'),
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.notificationCategoryBazar),
          subtitle: !settings.globalEnabled || !settings.bazarEnabled
              ? Text(
                  !settings.globalEnabled
                      ? l10n.notificationMasterOffReason
                      : l10n.notificationCategoryOffReason,
                )
              : null,
          isThreeLine: !settings.globalEnabled || !settings.bazarEnabled,
          value: settings.bazarEnabled,
          onChanged: (value) =>
              onChanged(settings.copyWith(bazarEnabled: value)),
        ),
        SwitchListTile(
          key: const Key('notifications_family'),
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.notificationCategoryFamily),
          subtitle: !settings.globalEnabled || !settings.familyEnabled
              ? Text(
                  !settings.globalEnabled
                      ? l10n.notificationMasterOffReason
                      : l10n.notificationCategoryOffReason,
                )
              : null,
          isThreeLine: !settings.globalEnabled || !settings.familyEnabled,
          value: settings.familyEnabled,
          onChanged: (value) =>
              onChanged(settings.copyWith(familyEnabled: value)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(l10n.notificationTemplateHint),
          ),
        ),
      ],
    );
  }
}
