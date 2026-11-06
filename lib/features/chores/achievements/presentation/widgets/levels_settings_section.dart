import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/features/chores/achievements/domain/engagement_settings.dart';
import 'package:family_hub/features/chores/achievements/domain/levels/level_table.dart';
import 'package:family_hub/features/chores/achievements/presentation/widgets/engagement_setting_fields.dart';
import 'package:flutter/material.dart';

class LevelsSettingsSection extends StatelessWidget {
  const LevelsSettingsSection({
    required this.settings,
    required this.onChanged,
    required this.onValidityChanged,
    required this.onReset,
    required this.onInvalidated,
    required this.number,
    required this.newLevelName,
    super.key,
  });

  final EngagementSettings settings;
  final ValueChanged<EngagementSettings> onChanged;
  final void Function(String fieldId, bool valid) onValidityChanged;
  final VoidCallback onReset;
  final VoidCallback onInvalidated;
  final String Function(int) number;
  final String newLevelName;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      children: [
        for (var index = 0; index < settings.levels.length; index++)
          _LevelFields(
            key: ValueKey(settings.levels[index].id),
            index: index,
            level: settings.levels[index],
            number: number,
            onValidityChanged: onValidityChanged,
            onChanged: (next) {
              final levels = [...settings.levels];
              levels[index] = next;
              onChanged(settings.copyWith(levels: levels));
            },
            onRemove: index == 0
                ? null
                : () {
                    final levels = [...settings.levels]..removeAt(index);
                    onChanged(settings.copyWith(levels: levels));
                    onInvalidated();
                  },
          ),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            onPressed: settings.levels.length >= 12
                ? null
                : () {
                    final ids = settings.levels
                        .map((level) => level.id)
                        .toSet();
                    var suffix = settings.levels.length + 1;
                    while (ids.contains('custom_$suffix')) {
                      suffix++;
                    }
                    final previous = settings.levels.last;
                    onChanged(
                      settings.copyWith(
                        levels: [
                          ...settings.levels,
                          EngagementLevel(
                            id: 'custom_$suffix',
                            minPoints: previous.minPoints + 100,
                            nameBn: newLevelName,
                            nameEn: newLevelName,
                          ),
                        ],
                      ),
                    );
                  },
            icon: const Icon(Icons.add_rounded),
            label: Text(l10n.engagementSettingsAddLevel),
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

class _LevelFields extends StatelessWidget {
  const _LevelFields({
    required this.index,
    required this.level,
    required this.number,
    required this.onValidityChanged,
    required this.onChanged,
    required this.onRemove,
    super.key,
  });

  final int index;
  final EngagementLevel level;
  final String Function(int) number;
  final void Function(String, bool) onValidityChanged;
  final ValueChanged<EngagementLevel> onChanged;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final prefix = 'level.${level.id}';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.achievementLevel(number(index + 1)),
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                if (onRemove != null)
                  IconButton(
                    tooltip: l10n.engagementSettingsRemoveLevel,
                    onPressed: onRemove,
                    icon: const Icon(Icons.delete_outline_rounded),
                  ),
              ],
            ),
            if (index == 0)
              Text('${l10n.engagementSettingsLevelPoints}: ${number(0)}')
            else ...[
              const SizedBox(height: 8),
              IntegerSettingField(
                fieldId: '$prefix.points',
                label: l10n.engagementSettingsLevelPoints,
                value: level.minPoints,
                min: 1,
                max: 1000000,
                onChanged: (value) =>
                    onChanged(level.copyWith(minPoints: value)),
                onValidityChanged: (valid) =>
                    onValidityChanged('$prefix.points', valid),
              ),
            ],
            const SizedBox(height: 8),
            TextSettingField(
              fieldId: '$prefix.bn',
              label: l10n.engagementSettingsLevelNameBn,
              value: level.nameBn,
              onChanged: (value) => onChanged(level.copyWith(nameBn: value)),
              onValidityChanged: (valid) =>
                  onValidityChanged('$prefix.bn', valid),
            ),
            const SizedBox(height: 8),
            TextSettingField(
              fieldId: '$prefix.en',
              label: l10n.engagementSettingsLevelNameEn,
              value: level.nameEn,
              onChanged: (value) => onChanged(level.copyWith(nameEn: value)),
              onValidityChanged: (valid) =>
                  onValidityChanged('$prefix.en', valid),
            ),
          ],
        ),
      ),
    );
  }
}
