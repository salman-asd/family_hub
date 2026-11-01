import 'dart:async';

import 'package:animations/animations.dart';
import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/features/chores/calendar/domain/calendar_enums.dart';
import 'package:family_hub/features/chores/calendar/domain/calendar_month_model.dart';
import 'package:family_hub/features/chores/calendar/presentation/calendar_providers.dart';
import 'package:family_hub/features/chores/calendar/presentation/widgets/agenda_view.dart';
import 'package:family_hub/features/chores/calendar/presentation/widgets/calendar_filter_sheet.dart';
import 'package:family_hub/features/chores/calendar/presentation/widgets/calendar_header.dart';
import 'package:family_hub/features/chores/calendar/presentation/widgets/day_panel.dart';
import 'package:family_hub/features/chores/calendar/presentation/widgets/filter_button.dart';
import 'package:family_hub/features/chores/calendar/presentation/widgets/filter_chips_row.dart';
import 'package:family_hub/features/chores/calendar/presentation/widgets/legend_sheet.dart';
import 'package:family_hub/features/chores/calendar/presentation/widgets/month_grid.dart';
import 'package:family_hub/features/chores/calendar/presentation/widgets/month_grid_placeholder.dart';
import 'package:family_hub/features/chores/calendar/presentation/widgets/month_pager.dart';
import 'package:family_hub/features/chores/calendar/presentation/widgets/month_year_picker_sheet.dart';
import 'package:family_hub/features/chores/calendar/presentation/widgets/scope_chip.dart';
import 'package:family_hub/features/chores/calendar/presentation/widgets/truncated_banner.dart';
import 'package:family_hub/features/chores/calendar/presentation/widgets/view_switcher.dart';
import 'package:family_hub/features/chores/calendar/presentation/widgets/week_view.dart';
import 'package:family_hub/features/chores/calendar/presentation/widgets/weekday_header_row.dart';
import 'package:family_hub/features/chores/occurrences/presentation/occurrence_providers.dart';
import 'package:family_hub/features/chores/presentation/chores_failure_messages.dart';
import 'package:family_hub/features/chores/settings/presentation/chore_settings_providers.dart';
import 'package:family_hub/features/family/presentation/family_providers.dart';
import 'package:family_hub/shared/widgets/error_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Below this width seven 48 dp cells do not fit, so the month is replaced by
/// the week (B.6).
const double kMonthMinWidth = 336;

/// The chore calendar (P3-22 Month, P3-23 Agenda and Week). The body of
/// `ChoresHomeScreen`.
///
/// All three views share ONE selected day, ONE focused month, ONE scope and ONE
/// filter state (`calendarFocusProvider`, `calendarPrefsProvider`); switching
/// views keeps them. Each view keeps its own scroll position (`PageStorageKey`).
class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  /// The month pager's middle page; fixed for the screen's lifetime.
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
    final stored = ref.watch(calendarViewProvider);
    final filters = ref.watch(calendarFiltersProvider);
    final reduce = MediaQuery.disableAnimationsOf(context);
    final narrow = MediaQuery.sizeOf(context).width < kMonthMinWidth;
    final view = stored == CalendarViewKind.month && narrow
        ? CalendarViewKind.week
        : stored;
    final controller = ref.read(calendarFocusProvider.notifier);
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

    final weekly = view == CalendarViewKind.week;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CalendarHeader(
                title: formatters.monthLabel(focus.month),
                showToday: focus.month != today.monthKey || focus.day != today,
                showArrows: view != CalendarViewKind.agenda,
                previousLabel: weekly
                    ? l10n.calendarPreviousWeek
                    : l10n.calendarPreviousMonth,
                nextLabel: weekly
                    ? l10n.calendarNextWeek
                    : l10n.calendarNextMonth,
                onTitle: () => unawaited(pick()),
                onPrevious: () => weekly
                    ? controller.shiftDays(-7)
                    : controller.shiftMonth(-1),
                onNext: () =>
                    weekly ? controller.shiftDays(7) : controller.shiftMonth(1),
                onToday: controller.goToToday,
              ),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  ViewSwitcher(
                    selected: view,
                    enabled: <CalendarView>{
                      CalendarViewKind.agenda,
                      CalendarViewKind.week,
                      if (!narrow) CalendarViewKind.month,
                    },
                    onChanged: (next) => unawaited(
                      ref.read(calendarPrefsProvider.notifier).setView(next),
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
                    onPressed: () => unawaited(showCalendarFilterSheet(context)),
                  ),
                  IconButton(
                    key: const Key('calendar_legend_button'),
                    tooltip: l10n.calendarLegend,
                    onPressed: () => unawaited(showLegendSheet(context)),
                    icon: const Icon(Icons.help_outline_rounded),
                  ),
                ],
              ),
              if (stored == CalendarViewKind.month && narrow)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    l10n.calendarMonthNarrow,
                    key: const Key('calendar_month_narrow'),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              const FilterChipsRow(),
              const SizedBox(height: 4),
            ],
          ),
        ),
        Expanded(
          child: PageTransitionSwitcher(
            duration: reduce ? Duration.zero : const Duration(milliseconds: 250),
            transitionBuilder: (child, animation, secondary) =>
                FadeThroughTransition(
                  animation: animation,
                  secondaryAnimation: secondary,
                  child: child,
                ),
            child: KeyedSubtree(
              key: ValueKey<CalendarView>(view),
              child: switch (view) {
                CalendarViewKind.agenda => const AgendaView(),
                CalendarViewKind.week => const WeekView(),
                CalendarViewKind.month => _MonthBody(epoch: _epoch),
              },
            ),
          ),
        ),
      ],
    );
  }
}

/// The month grid with the draggable day panel over its lower part.
class _MonthBody extends ConsumerWidget {
  const _MonthBody({required this.epoch});

  final MonthKey epoch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formatters = ref.watch(appFormattersProvider);
    final focus = ref.watch(calendarFocusProvider);
    final scope = ref.watch(calendarScopeProvider);
    final style = ref.watch(calendarMarkerStyleProvider);
    final weekStart = ref.watch(choreSettingsProvider).weekStartDay;
    final reduce = MediaQuery.disableAnimationsOf(context);
    final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
    final cellHeight = 56 * scale.clamp(1.0, 2.0);
    final rows = _rowsOf(focus.month, weekStart);
    final controller = ref.read(calendarFocusProvider.notifier);
    final truncated =
        ref.watch(calendarMonthModelProvider(focus.month)).value?.truncated ??
        false;
    final height = MediaQuery.sizeOf(context).height;

    return Stack(
      children: [
        Positioned.fill(
          child: SingleChildScrollView(
            key: const PageStorageKey<String>('calendar_month'),
            // Room under the grid for the panel at its lowest snap.
            padding: EdgeInsets.fromLTRB(12, 0, 12, height * 0.3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                WeekdayHeaderRow(
                  weekStartDay: weekStart,
                  formatters: formatters,
                ),
                Semantics(
                  container: true,
                  label: context.l10n.calendarGridLabel,
                  child: SizedBox(
                    height: rows * cellHeight,
                    child: MonthPager(
                      epoch: epoch,
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
                    onOpenFilters: () =>
                        unawaited(showCalendarFilterSheet(context)),
                  ),
                ],
              ],
            ),
          ),
        ),
        DayPanel(day: focus.day),
      ],
    );
  }

  static int _rowsOf(MonthKey month, int weekStart) {
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
