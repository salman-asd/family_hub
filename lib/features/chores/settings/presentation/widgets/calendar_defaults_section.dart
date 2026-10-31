import 'package:family_hub/core/localization/app_formatters.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/features/chores/settings/domain/chore_catalog_entries.dart';
import 'package:family_hub/features/chores/settings/domain/chore_settings.dart';
import 'package:family_hub/features/family/presentation/family_providers.dart';
import 'package:family_hub/shared/widgets/choice_wrap.dart';
import 'package:family_hub/shared/widgets/weekday_chips.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Calendar & display section of the chore settings screen (P3-17).
///
/// Edits: default view (agenda / month / week), default scope (mine / all),
/// week start day, show projected, and projected months ahead.
/// All values come from and are applied to the caller's [draft]; no Firestore
/// writes happen here.
class CalendarDefaultsSection extends ConsumerWidget {
  const CalendarDefaultsSection({
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
          // ── Default calendar view ──────────────────────────────────────
          Text(
            l10n.choresSettingsDefaultView,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          ChoiceWrap<CalendarViewKind>(
            selected: draft.defaultCalendarView,
            onChanged: (v) =>
                onChanged(draft.copyWith(defaultCalendarView: v)),
            options: [
              ChoiceOption(
                CalendarViewKind.agenda,
                l10n.choresCalendarViewAgenda,
              ),
              ChoiceOption(
                CalendarViewKind.month,
                l10n.choresCalendarViewMonth,
              ),
              ChoiceOption(
                CalendarViewKind.week,
                l10n.choresCalendarViewWeek,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Default scope ──────────────────────────────────────────────
          Text(
            l10n.choresSettingsDefaultScope,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          ChoiceWrap<CalendarScopeKind>(
            selected: draft.defaultScope,
            onChanged: (v) =>
                onChanged(draft.copyWith(defaultScope: v)),
            options: [
              ChoiceOption(
                CalendarScopeKind.mine,
                l10n.choresCalendarScopeMine,
              ),
              ChoiceOption(
                CalendarScopeKind.all,
                l10n.choresCalendarScopeAll,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Week start day ─────────────────────────────────────────────
          Text(
            l10n.choresSettingsWeekStart,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          WeekdayChips(
            // Show all 7 days as single-select for week start.
            selected: {draft.weekStartDay},
            weekStartDay: draft.weekStartDay,
            formatters: formatters,
            onChanged: (days) {
              if (days.isEmpty) return;
              onChanged(draft.copyWith(weekStartDay: days.first));
            },
          ),
          const SizedBox(height: 16),

          // ── Show projected chores ──────────────────────────────────────
          SwitchListTile(
            key: const ValueKey('show-projected'),
            value: draft.showProjected,
            title: Text(l10n.choresSettingsShowProjected),
            subtitle: Text(l10n.choresSettingsShowProjectedSubtitle),
            contentPadding: EdgeInsets.zero,
            onChanged: (v) =>
                onChanged(draft.copyWith(showProjected: v)),
          ),

          // ── Projected months ahead (only when showProjected) ───────────
          if (draft.showProjected) ...[
            Text(
              l10n.choresSettingsProjectedMonths(
                formatters.number(draft.projectedMonthsAhead),
              ),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Slider(
              key: const ValueKey('projected-months-slider'),
              value: draft.projectedMonthsAhead.toDouble(),
              min: 0,
              max: ChoreSettingsLimits.maxProjectedMonthsAhead.toDouble(),
              divisions: ChoreSettingsLimits.maxProjectedMonthsAhead,
              label: formatters.number(draft.projectedMonthsAhead),
              onChanged: (v) =>
                  onChanged(draft.copyWith(projectedMonthsAhead: v.round())),
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

