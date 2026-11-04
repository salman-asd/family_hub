import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/features/chores/calendar/presentation/calendar_items_providers.dart';
import 'package:family_hub/features/chores/occurrences/domain/chore_item.dart';
import 'package:family_hub/features/chores/occurrences/domain/occurrence_status.dart';
import 'package:family_hub/features/chores/occurrences/domain/today_sections.dart';
import 'package:family_hub/features/chores/occurrences/presentation/today_providers.dart';
import 'package:family_hub/features/chores/rota/presentation/rota_providers.dart';
import 'package:family_hub/features/chores/settings/domain/chore_catalog_entries.dart';
import 'package:family_hub/features/chores/settings/presentation/chore_settings_providers.dart';
import 'package:family_hub/features/family/presentation/family_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Providers behind the Home dashboard cards (P3-29).
///
/// Every number here is derived from the providers Today and the calendar
/// already use (`todayItemsProvider`, `monthItemsProvider`,
/// `verifyQueueCountProvider`), so the dashboard can never disagree with them
/// and costs no extra listener (rule 37). The viewer's scope starts at the
/// family's `defaultScope`, exactly like the Today screen does.

/// [items] kept to the viewer's own chores when the family default is "mine".
List<ChoreItem> _scoped(List<ChoreItem> items, Ref ref) {
  final scope = ref.watch(choreSettingsProvider.select((s) => s.defaultScope));
  return scope == CalendarScopeKind.mine
      ? mineOnly(items, ref.watch(currentUidProvider))
      : items;
}

/// Today's chores as the dashboard counts them.
final dashboardTodayItemsProvider = Provider<List<ChoreItem>>(
  (ref) => _scoped(ref.watch(todayItemsProvider), ref),
);

/// Today's progress for the same list (the ring on the card).
final dashboardTodayProgressProvider = Provider<TodayProgress>(
  (ref) => TodayProgress.of(ref.watch(dashboardTodayItemsProvider)),
);

/// The next open chore of today, earliest deadline first, or null when nothing
/// is left (overdue ones belong to the Overdue card, so they are skipped here).
final dashboardNextItemProvider = Provider<ChoreItem?>((ref) {
  ChoreItem? next;
  for (final item in ref.watch(dashboardTodayItemsProvider)) {
    if (!item.status.isOpen) continue;
    if (next == null || item.dueAt.isBefore(next.dueAt)) next = item;
  }
  return next;
});

/// Open chores of this month whose deadline has passed, oldest first.
///
/// This month, not only today: a chore missed yesterday is still overdue and
/// the dashboard must not forget it at midnight. (Today's own Overdue section
/// shows today only; the agenda shows all.)
final dashboardOverdueProvider = Provider<List<ChoreItem>>((ref) {
  final month = ref.watch(familyDateKeysProvider).thisMonth();
  final items =
      ref.watch(monthItemsProvider(month)).value?.items ??
      const <ChoreItem>[];
  return <ChoreItem>[
    for (final item in _scoped(items, ref))
      if (!item.isProjected && item.status == ChoreStatus.overdue) item,
  ]..sort((a, b) => a.dueAt.compareTo(b.dueAt));
});

/// One day of the "This week" strip.
final class WeekStripDay {
  const WeekStripDay({
    required this.day,
    required this.total,
    required this.done,
    required this.isToday,
  });

  final DateKey day;

  /// Chores of that day (skipped ones are not counted).
  final int total;

  /// Completed or verified chores of that day.
  final int done;

  final bool isToday;

  @override
  bool operator ==(Object other) =>
      other is WeekStripDay &&
      other.day == day &&
      other.total == total &&
      other.done == done &&
      other.isToday == isToday;

  @override
  int get hashCode => Object.hash(day, total, done, isToday);
}

/// The seven days of the current chore week (the family's week start), each
/// with its chore count. Reads at most the two month listeners a week can touch.
final dashboardWeekProvider = Provider<List<WeekStripDay>>((ref) {
  final keys = ref.watch(familyDateKeysProvider);
  final today = keys.today();
  final bounds = rotaBoundsFor(
    range: RotaRange.week,
    today: today,
    weekStartDay: ref.watch(
      choreSettingsProvider.select((s) => s.weekStartDay),
    ),
  );
  final months = <MonthKey>{
    MonthKey(bounds.from.year, bounds.from.month),
    MonthKey(bounds.to.year, bounds.to.month),
  };
  final items = <ChoreItem>[
    for (final month in months)
      ...(ref.watch(monthItemsProvider(month)).value?.items ??
          const <ChoreItem>[]),
  ];
  final scoped = _scoped(items, ref);
  final week = <WeekStripDay>[];
  for (var i = 0; i < 7; i++) {
    final day = bounds.from.addDays(i);
    var total = 0;
    var done = 0;
    for (final item in scoped) {
      if (item.dateKey != day || item.status == ChoreStatus.skipped) continue;
      total++;
      if (isDoneStatus(item.status)) done++;
    }
    week.add(
      WeekStripDay(day: day, total: total, done: done, isToday: day == today),
    );
  }
  return week;
});
