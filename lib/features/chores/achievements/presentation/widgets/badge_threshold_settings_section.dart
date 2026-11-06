import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/features/chores/achievements/domain/engagement_settings.dart';
import 'package:family_hub/features/chores/achievements/presentation/widgets/engagement_setting_fields.dart';
import 'package:flutter/material.dart';

class BadgeThresholdSettingsSection extends StatelessWidget {
  const BadgeThresholdSettingsSection({
    required this.settings,
    required this.onChanged,
    required this.onValidityChanged,
    required this.onReset,
    super.key,
  });

  final EngagementSettings settings;
  final ValueChanged<EngagementSettings> onChanged;
  final void Function(String fieldId, bool valid) onValidityChanged;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final thresholds = settings.badgeThresholds;
    final fields = <(String, String, int, int, int)>[
      (
        'badges.days',
        l10n.engagementSettingsConsistentDays,
        thresholds.consistentDays,
        1,
        365,
      ),
      (
        'badges.reliablePercent',
        l10n.engagementSettingsReliablePercent,
        thresholds.reliablePercent,
        0,
        100,
      ),
      (
        'badges.reliableCount',
        l10n.engagementSettingsReliableCount,
        thresholds.reliableMinDone,
        1,
        1000,
      ),
      (
        'badges.covers',
        l10n.engagementSettingsHelperCovers,
        thresholds.helperCovers,
        1,
        1000,
      ),
      (
        'badges.detail',
        l10n.engagementSettingsDetailCount,
        thresholds.detailCount,
        1,
        1000,
      ),
    ];
    return Column(
      children: [
        for (final (id, label, value, min, max) in fields)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: IntegerSettingField(
              fieldId: id,
              label: label,
              value: value,
              min: min,
              max: max,
              onChanged: (next) {
                final updated = switch (id) {
                  'badges.days' => thresholds.copyWith(consistentDays: next),
                  'badges.reliablePercent' => thresholds.copyWith(
                    reliablePercent: next,
                  ),
                  'badges.reliableCount' => thresholds.copyWith(
                    reliableMinDone: next,
                  ),
                  'badges.covers' => thresholds.copyWith(helperCovers: next),
                  _ => thresholds.copyWith(detailCount: next),
                };
                onChanged(settings.copyWith(badgeThresholds: updated));
              },
              onValidityChanged: (valid) => onValidityChanged(id, valid),
            ),
          ),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: TextButton(
            onPressed: onReset,
            child: Text(l10n.engagementSettingsResetSection),
          ),
        ),
      ],
    );
  }
}
