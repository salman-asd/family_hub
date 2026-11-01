import 'package:family_hub/core/localization/app_formatters.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/features/chores/settings/domain/chore_catalog_entries.dart';
import 'package:family_hub/features/chores/settings/domain/chore_settings.dart';
import 'package:family_hub/shared/widgets/choice_wrap.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Calendar defaults of the chore settings page (P3-17): default view, default
/// scope, week start, projected chores and how far ahead they are projected.
///
/// A pure view over [draft]: every change is reported as a whole new value and
/// nothing is written here.
class CalendarDefaultsSection extends ConsumerWidget {
  const CalendarDefaultsSection({
    required this.draft,
    required this.onChanged,
    super.key,
  });

  final ChoreSettings draft;
  final ValueChanged<ChoreSettings> onChanged;

  /// The week-start choices, Saturday first (the family default week), then
  /// the rest in calendar order. The order is fixed so the chips do not jump
  /// around while one of them is being chosen.
  static const List<int> weekStartChoices = <int>[
    DateTime.saturday,
    DateTime.sunday,
    DateTime.monday,
    DateTime.tuesday,
    DateTime.wednesday,
    DateTime.thursday,
    DateTime.friday,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final formatters = ref.watch(appFormattersProvider);
    final label = Theme.of(context).textTheme.labelLarge;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.choresSettingsDefaultView, style: label),
        const SizedBox(height: 8),
        ChoiceWrap<CalendarViewKind>(
          selected: draft.defaultCalendarView,
          onChanged: (v) => onChanged(draft.copyWith(defaultCalendarView: v)),
          options: [
            for (final kind in CalendarViewKind.values)
              ChoiceOption<CalendarViewKind>(
                kind,
                _viewLabel(context, kind),
                key: ValueKey<String>('view_${kind.id}'),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Text(l10n.choresSettingsDefaultScope, style: label),
        const SizedBox(height: 8),
        ChoiceWrap<CalendarScopeKind>(
          selected: draft.defaultScope,
          onChanged: (v) => onChanged(draft.copyWith(defaultScope: v)),
          options: [
            for (final kind in CalendarScopeKind.values)
              ChoiceOption<CalendarScopeKind>(
                kind,
                _scopeLabel(context, kind),
                key: ValueKey<String>('scope_${kind.id}'),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Text(l10n.choresSettingsWeekStart, style: label),
        const SizedBox(height: 8),
        ChoiceWrap<int>(
          selected: draft.weekStartDay,
          onChanged: (day) => onChanged(draft.copyWith(weekStartDay: day)),
          options: [
            for (final day in weekStartChoices)
              ChoiceOption<int>(
                day,
                formatters.weekdayName(day),
                key: ValueKey<String>('week_start_$day'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          key: const ValueKey<String>('show_projected'),
          contentPadding: EdgeInsets.zero,
          value: draft.showProjected,
          title: Text(l10n.choresSettingsShowProjected),
          subtitle: Text(l10n.choresSettingsShowProjectedSubtitle),
          onChanged: (v) => onChanged(draft.copyWith(showProjected: v)),
        ),
        if (draft.showProjected) ...[
          Text(
            l10n.choresSettingsProjectedMonths(
              formatters.number(draft.projectedMonthsAhead),
            ),
          ),
          Slider(
            key: const ValueKey<String>('projected_months'),
            value: draft.projectedMonthsAhead.toDouble(),
            max: ChoreSettingsLimits.maxProjectedMonthsAhead.toDouble(),
            divisions: ChoreSettingsLimits.maxProjectedMonthsAhead,
            label: formatters.number(draft.projectedMonthsAhead),
            onChanged: (v) =>
                onChanged(draft.copyWith(projectedMonthsAhead: v.round())),
          ),
        ],
      ],
    );
  }

  static String _viewLabel(BuildContext context, CalendarViewKind kind) =>
      switch (kind) {
        CalendarViewKind.agenda => context.l10n.choresCalendarViewAgenda,
        CalendarViewKind.month => context.l10n.choresCalendarViewMonth,
        CalendarViewKind.week => context.l10n.choresCalendarViewWeek,
      };

  static String _scopeLabel(BuildContext context, CalendarScopeKind kind) =>
      switch (kind) {
        CalendarScopeKind.mine => context.l10n.choresCalendarScopeMine,
        CalendarScopeKind.all => context.l10n.choresCalendarScopeAll,
      };
}
