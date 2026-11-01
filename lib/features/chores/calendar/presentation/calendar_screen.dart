import 'dart:async';

import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/features/chores/calendar/domain/calendar_enums.dart';
import 'package:family_hub/features/chores/calendar/domain/calendar_month_model.dart';
import 'package:family_hub/features/chores/calendar/presentation/calendar_providers.dart';
import 'package:family_hub/features/chores/calendar/presentation/widgets/calendar_header.dart';
import 'package:family_hub/features/chores/calendar/presentation/widgets/day_list.dart';
import 'package:family_hub/features/chores/calendar/presentation/widgets/filter_button.dart';
import 'package:family_hub/features/chores/calendar/presentation/widgets/filters_sheet.dart';
import 'package:family_hub/features/chores/calendar/presentation/widgets/month_grid.dart';
import 'package:family_hub/features/chores/calendar/presentation/widgets/month_grid_placeholder.dart';
import 'package:family_hub/features/chores/calendar/presentation/widgets/month_pager.dart';
import 'package:family_hub/features/chores/calendar/presentation/widgets/month_year_picker_sheet.dart';
import 'package:family_hub/features/chores/calendar/presentation/widgets/scope_chip.dart';
import 'package:family_hub/features/chores/calendar/presentation/widgets/truncated_banner.dart';
import 'package:family_hub/features/chores/calendar/presentation/widgets/view_switcher.dart';
import 'package:family_hub/features/chores/calendar/presentation/widgets/weekday_header_row.dart';
import 'package:family_hub/features/chores/occurrences/presentation/occurrence_providers.dart';
import 'package:family_hub/features/chores/presentation/chores_failure_messages.dart';
import 'package:family_hub/features/chores/settings/presentation/chore_settings_providers.dart';
import 'package:family_hub/features/family/presentation/family_providers.dart';
import 'package:family_hub/shared/widgets/error_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The chore calendar, Month view (P3-22, Appendix B). The body of
/// `ChoresHomeScreen`.
///
/// Layout: title row, view / scope / filter row, weekday header, the month
/// pager, an optional truncated banner and the selected day's chores. The whole
/// screen scrolls, so large text never clips the day list.
///
/// Agenda and Week are P3-23: until then the switcher shows them disabled and
/// the screen always draws the month.
class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  /// The pager's middle page; fixed for the screen's lifetime.
  late final MonthKey _epoch = ref
      .read(familyDateKeysProvider)
      .today()
      .monthKey;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final formatters = ref.watch(appFormattersProvider);
    final focus = ref.watch(calendarFocusProvider);
    final today = ref.watch(todayKeyProvider);
    final scope = ref.watch(calendarScopeProvider);
    final style = ref.watch(calendarMarkerStyleProvider);
    final weekStart = ref.watch(choreSettingsProvider).weekStartDay;
    final filters = ref.watch(calendarFiltersProvider);
    final reduce = MediaQuery.disableAnimationsOf(context);
    final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
    final cellHeight = 56 * scale.clamp(1.0, 2.0);
    final rows = _rowsOf(focus.month, weekStart);
    final controller = ref.read(calendarFocusProvider.notifier);
    final truncated =
        ref.watch(calendarMonthModelProvider(focus.month)).value?.truncated ??
        false;

    final first = _epoch.addMonths(-kCalendarPagesEachWay);
    final last = _epoch.addMonths(kCalendarPagesEachWay);

    Future<void> pick() async {
      final chosen = await showMonthYearPickerSheet(
        context,
        current: focus.month,
        first: first,
        last: last,
        formatters: formatters,
      );
      if (chosen != null) controller.showMonth(chosen);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CalendarHeader(
            title: formatters.monthLabel(focus.month),
            showToday: focus.month != today.monthKey || focus.day != today,
            onTitle: () => unawaited(pick()),
            onPrevious: () => controller.shiftMonth(-1),
            onNext: () => controller.shiftMonth(1),
            onToday: controller.goToToday,
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ViewSwitcher(
                selected: CalendarViewKind.month,
                enabled: const <CalendarView>{CalendarViewKind.month},
                onChanged: (view) => unawaited(
                  ref.read(calendarPrefsProvider.notifier).setView(view),
                ),
              ),
              ScopeChip(
                scope: scope,
                onToggle: () => unawaited(
                  ref.read(calendarPrefsProvider.notifier).toggleScope(),
                ),
              ),
              FilterButton(
                activeCount: filters.activeCount,
                formatters: formatters,
                onPressed: () => unawaited(showFiltersSheet(context)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          WeekdayHeaderRow(weekStartDay: weekStart, formatters: formatters),
          Semantics(
            container: true,
            label: l10n.calendarGridLabel,
            child: SizedBox(
              height: rows * cellHeight,
              child: MonthPager(
                epoch: _epoch,
                month: focus.month,
                reduceMotion: reduce,
                onMonthChanged: controller.showMonth,
                pageBuilder: (context, month) => _MonthPage(
                  month: month,
                  weekStartDay: weekStart,
                  cellHeight: cellHeight,
                  selectedDay: focus.day,
                  scope: scope,
                  markerStyle: style,
                  onSelect: (day) {
                    unawaited(HapticFeedback.selectionClick());
                    controller.selectDay(day);
                  },
                ),
              ),
            ),
          ),
          if (truncated) ...[
            const SizedBox(height: 8),
            TruncatedBanner(
              onOpenFilters: () => unawaited(showFiltersSheet(context)),
            ),
          ],
          DayList(day: focus.day),
        ],
      ),
    );
  }

  static int _rowsOf(MonthKey month, int weekStart) {
    // The first cell is the week start on or before the 1st; the grid ends with
    // the week that holds the last day.
    final lead = (month.startOfMonth.isoWeekday - weekStart + 7) % 7;
    return ((lead + month.daysInMonth) / 7).ceil();
  }
}

/// One page of the pager: placeholder, error or the grid of [month].
class _MonthPage extends ConsumerWidget {
  const _MonthPage({
    required this.month,
    required this.weekStartDay,
    required this.cellHeight,
    required this.selectedDay,
    required this.scope,
    required this.markerStyle,
    required this.onSelect,
  });

  final MonthKey month;
  final int weekStartDay;
  final double cellHeight;
  final DateKey selectedDay;
  final CalendarScope scope;
  final MarkerStyle markerStyle;
  final ValueChanged<DateKey> onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formatters = ref.watch(appFormattersProvider);
    final model = ref.watch(calendarMonthModelProvider(month));
    if (model.hasValue) {
      final CalendarMonthModel value = model.requireValue;
      return Align(
        alignment: Alignment.topCenter,
        child: MonthGrid(
          model: value,
          selectedDay: selectedDay,
          scope: scope,
          markerStyle: markerStyle,
          formatters: formatters,
          cellHeight: cellHeight,
          onSelect: onSelect,
          onLongPress: onSelect,
        ),
      );
    }
    if (model.hasError) {
      final error = model.error;
      return ErrorView(
        message: context.l10n.choresFailureMessage(
          error is AppFailure ? error : Unknown(error),
        ),
        onRetry: () => ref.invalidate(monthOccurrencesProvider(month)),
      );
    }
    return Align(
      alignment: Alignment.topCenter,
      child: MonthGridPlaceholder(
        month: month,
        weekStartDay: weekStartDay,
        formatters: formatters,
        cellHeight: cellHeight,
      ),
    );
  }
}
