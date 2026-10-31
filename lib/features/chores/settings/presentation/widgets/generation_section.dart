import 'package:family_hub/core/localization/app_formatters.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/features/chores/settings/domain/chore_catalog_entries.dart';
import 'package:family_hub/features/chores/settings/domain/chore_settings.dart';
import 'package:family_hub/features/family/presentation/family_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Generation & timing section of the chore settings screen (P3-17).
///
/// Edits: generation horizon (14-90 days) and overdue grace period (0-240 min).
/// All values come from and are applied to the caller's [draft].
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Generation horizon ─────────────────────────────────────────
          Text(
            l10n.choresSettingsHorizon(
              formatters.number(draft.generationHorizonDays),
            ),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Text(
            l10n.choresSettingsHorizonSubtitle,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Slider(
            key: const ValueKey('horizon-slider'),
            value: draft.generationHorizonDays.toDouble(),
            min: ChoreSettingsLimits.minGenerationHorizonDays.toDouble(),
            max: ChoreSettingsLimits.maxGenerationHorizonDays.toDouble(),
            divisions: ChoreSettingsLimits.maxGenerationHorizonDays -
                ChoreSettingsLimits.minGenerationHorizonDays,
            label: formatters.number(draft.generationHorizonDays),
            onChanged: (v) => onChanged(
              draft.copyWith(generationHorizonDays: v.round()),
            ),
          ),
          const SizedBox(height: 8),

          // ── Overdue grace period ───────────────────────────────────────
          Text(
            l10n.choresSettingsOverdueGrace(
              formatters.number(draft.overdueGraceMinutes),
            ),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Text(
            l10n.choresSettingsOverdueGraceSubtitle,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Slider(
            key: const ValueKey('grace-slider'),
            value: draft.overdueGraceMinutes.toDouble(),
            min: 0,
            max: ChoreSettingsLimits.maxOverdueGraceMinutes.toDouble(),
            divisions: ChoreSettingsLimits.maxOverdueGraceMinutes ~/ 10,
            label: formatters.number(draft.overdueGraceMinutes),
            onChanged: (v) =>
                onChanged(draft.copyWith(overdueGraceMinutes: v.round())),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

