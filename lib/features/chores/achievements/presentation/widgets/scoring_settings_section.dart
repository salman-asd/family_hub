import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/features/chores/achievements/domain/engagement_settings.dart';
import 'package:family_hub/features/chores/templates/domain/template_enums.dart';
import 'package:family_hub/features/chores/achievements/presentation/widgets/engagement_setting_fields.dart';
import 'package:flutter/material.dart';

class ScoringSettingsSection extends StatelessWidget {
  const ScoringSettingsSection({
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
    final spec = settings.scoreSpec;
    final pointFields = <(Difficulty, String)>[
      (Difficulty.easy, l10n.engagementSettingsEasyPoints),
      (Difficulty.normal, l10n.engagementSettingsNormalPoints),
      (Difficulty.hard, l10n.engagementSettingsHardPoints),
    ];
    return Column(
      children: [
        for (final (difficulty, label) in pointFields)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: IntegerSettingField(
              fieldId: 'score.${difficulty.name}',
              label: label,
              value: spec.pointBases[difficulty]!,
              min: 0,
              max: 1000,
              onChanged: (value) {
                final bases = Map<Difficulty, int>.of(spec.pointBases)
                  ..[difficulty] = value;
                onChanged(
                  settings.copyWith(
                    scoreSpec: spec.copyWith(pointBases: bases),
                  ),
                );
              },
              onValidityChanged: (valid) =>
                  onValidityChanged('score.${difficulty.name}', valid),
            ),
          ),
        _PercentField(
          id: 'score.late',
          label: l10n.engagementSettingsLateBonusPercent,
          value: spec.latePermille,
          onValidityChanged: onValidityChanged,
          onChanged: (value) => onChanged(
            settings.copyWith(
              scoreSpec: spec.copyWith(latePermille: value * 10),
            ),
          ),
        ),
        _PercentField(
          id: 'score.verified',
          label: l10n.engagementSettingsVerifiedBonusPercent,
          value: spec.verifiedPermille,
          onValidityChanged: onValidityChanged,
          onChanged: (value) => onChanged(
            settings.copyWith(
              scoreSpec: spec.copyWith(verifiedPermille: value * 10),
            ),
          ),
        ),
        _PercentField(
          id: 'score.cover',
          label: l10n.engagementSettingsCoverBonusPercent,
          value: spec.coverBonusPermille,
          onValidityChanged: onValidityChanged,
          onChanged: (value) => onChanged(
            settings.copyWith(
              scoreSpec: spec.copyWith(coverBonusPermille: value * 10),
            ),
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

class _PercentField extends StatelessWidget {
  const _PercentField({
    required this.id,
    required this.label,
    required this.value,
    required this.onValidityChanged,
    required this.onChanged,
  });

  final String id;
  final String label;
  final int value;
  final void Function(String, bool) onValidityChanged;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: IntegerSettingField(
      fieldId: id,
      label: label,
      value: value ~/ 10,
      min: 0,
      max: 200,
      onChanged: onChanged,
      onValidityChanged: (valid) => onValidityChanged(id, valid),
    ),
  );
}
