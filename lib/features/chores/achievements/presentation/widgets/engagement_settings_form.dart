import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/features/chores/achievements/domain/engagement_settings.dart';
import 'package:family_hub/features/chores/achievements/presentation/widgets/badge_threshold_settings_section.dart';
import 'package:family_hub/features/chores/achievements/presentation/widgets/levels_settings_section.dart';
import 'package:family_hub/features/chores/achievements/presentation/widgets/scoring_settings_section.dart';
import 'package:family_hub/shared/widgets/permission_gate.dart';
import 'package:flutter/material.dart';

class EngagementSettingsForm extends StatelessWidget {
  const EngagementSettingsForm({
    required this.settings,
    required this.defaults,
    required this.offline,
    required this.valid,
    required this.editorRevision,
    required this.canEditVisibility,
    required this.number,
    required this.onChanged,
    required this.onValidityChanged,
    required this.onInvalidatedLevels,
    required this.onVisibilityChanged,
    required this.onResetLevels,
    super.key,
  });

  final EngagementSettings settings;
  final EngagementSettings defaults;
  final bool offline;
  final bool valid;
  final int editorRevision;
  final bool canEditVisibility;
  final String Function(int) number;
  final ValueChanged<EngagementSettings> onChanged;
  final void Function(String fieldId, bool valid) onValidityChanged;
  final VoidCallback onInvalidatedLevels;
  final ValueChanged<StatsVisibility> onVisibilityChanged;
  final VoidCallback onResetLevels;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        if (offline)
          Card(
            child: ListTile(
              leading: const Icon(Icons.cloud_off_outlined),
              title: Text(l10n.engagementSettingsOffline),
            ),
          ),
        _generalSection(context),
        _section(
          key: ValueKey('score_$editorRevision'),
          title: l10n.engagementSettingsScoring,
          child: ScoringSettingsSection(
            settings: settings,
            onChanged: onChanged,
            onValidityChanged: onValidityChanged,
            onReset: () =>
                onChanged(settings.copyWith(scoreSpec: defaults.scoreSpec)),
          ),
        ),
        _section(
          key: ValueKey('levels_$editorRevision'),
          title: l10n.engagementSettingsLevels,
          child: LevelsSettingsSection(
            settings: settings,
            onChanged: onChanged,
            onValidityChanged: onValidityChanged,
            onInvalidated: onInvalidatedLevels,
            number: number,
            newLevelName: l10n.engagementSettingsNewLevelName(
              number(settings.levels.length + 1),
            ),
            onReset: onResetLevels,
          ),
        ),
        _section(
          key: ValueKey('badges_$editorRevision'),
          title: l10n.engagementSettingsBadgeThresholds,
          child: BadgeThresholdSettingsSection(
            settings: settings,
            onChanged: onChanged,
            onValidityChanged: onValidityChanged,
            onReset: () => onChanged(
              settings.copyWith(badgeThresholds: defaults.badgeThresholds),
            ),
          ),
        ),
        _visibilitySection(context),
        if (!valid)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              l10n.engagementSettingsInvalidValue,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
      ],
    );
  }

  Widget _generalSection(BuildContext context) {
    final l10n = context.l10n;
    return Card(
      child: Column(
        children: [
          SwitchListTile(
            title: Text(l10n.engagementSettingsEnabled),
            subtitle: Text(l10n.engagementSettingsEnabledDescription),
            value: settings.enabled,
            onChanged: (value) => onChanged(settings.copyWith(enabled: value)),
          ),
          SwitchListTile(
            title: Text(l10n.engagementSettingsCelebrations),
            subtitle: Text(l10n.engagementSettingsCelebrationsDescription),
            value: settings.celebrationEnabled,
            onChanged: (value) =>
                onChanged(settings.copyWith(celebrationEnabled: value)),
          ),
          SwitchListTile(
            title: Text(l10n.engagementSettingsHelpers),
            subtitle: Text(l10n.engagementSettingsHelpersDescription),
            value: settings.showHelpersHighlight,
            onChanged: (value) =>
                onChanged(settings.copyWith(showHelpersHighlight: value)),
          ),
        ],
      ),
    );
  }

  Widget _visibilitySection(BuildContext context) {
    final l10n = context.l10n;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: PermissionGate(
          allowed: canEditVisibility,
          mode: PermissionGateMode.disable,
          deniedMessage: l10n.engagementSettingsVisibilityAdminOnly,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.engagementSettingsVisibility,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              RadioGroup<StatsVisibility>(
                groupValue: settings.statsVisibility,
                onChanged: (value) {
                  if (canEditVisibility && value != null) {
                    onVisibilityChanged(value);
                  }
                },
                child: Column(
                  children: [
                    RadioListTile<StatsVisibility>(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.engagementSettingsPrivate),
                      value: StatsVisibility.private,
                    ),
                    RadioListTile<StatsVisibility>(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.engagementSettingsLevelsOnly),
                      value: StatsVisibility.levels,
                    ),
                  ],
                ),
              ),
              Text(
                l10n.engagementPointsNeverShared,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _section({
    required Key key,
    required String title,
    required Widget child,
  }) => Card(
    child: ExpansionTile(
      key: key,
      title: Text(title),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      children: [child],
    ),
  );
}
