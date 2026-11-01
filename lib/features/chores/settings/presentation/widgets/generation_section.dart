import 'package:family_hub/core/localization/app_formatters.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/features/chores/settings/domain/chore_catalog_entries.dart';
import 'package:family_hub/features/chores/settings/domain/chore_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Generation and timing (P3-17): how far ahead occurrences are written
/// (14-90 days) and how long after the due time a chore becomes overdue
/// (0-240 minutes, in steps of 10).
class GenerationSection extends ConsumerWidget {
  const GenerationSection({
    required this.draft,
    required this.onChanged,
    super.key,
  });

  final ChoreSettings draft;
  final ValueChanged<ChoreSettings> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final formatters = ref.watch(appFormattersProvider);
    final hint = Theme.of(context).textTheme.bodySmall;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.choresSettingsHorizon(
            formatters.number(draft.generationHorizonDays),
          ),
        ),
        Text(l10n.choresSettingsHorizonSubtitle, style: hint),
        Slider(
          key: const ValueKey<String>('horizon'),
          value: draft.generationHorizonDays.toDouble(),
          min: ChoreSettingsLimits.minGenerationHorizonDays.toDouble(),
          max: ChoreSettingsLimits.maxGenerationHorizonDays.toDouble(),
          divisions:
              ChoreSettingsLimits.maxGenerationHorizonDays -
              ChoreSettingsLimits.minGenerationHorizonDays,
          label: formatters.number(draft.generationHorizonDays),
          onChanged: (v) =>
              onChanged(draft.copyWith(generationHorizonDays: v.round())),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.choresSettingsOverdueGrace(
            formatters.number(draft.overdueGraceMinutes),
          ),
        ),
        Text(l10n.choresSettingsOverdueGraceSubtitle, style: hint),
        Slider(
          key: const ValueKey<String>('grace'),
          value: draft.overdueGraceMinutes.toDouble(),
          max: ChoreSettingsLimits.maxOverdueGraceMinutes.toDouble(),
          divisions: ChoreSettingsLimits.maxOverdueGraceMinutes ~/ 10,
          label: formatters.number(draft.overdueGraceMinutes),
          onChanged: (v) =>
              onChanged(draft.copyWith(overdueGraceMinutes: v.round())),
        ),
      ],
    );
  }
}
