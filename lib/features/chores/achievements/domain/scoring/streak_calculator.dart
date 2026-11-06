import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/features/chores/occurrences/domain/chore_occurrence.dart';
import 'package:family_hub/features/chores/occurrences/domain/effective_status.dart';
import 'package:family_hub/features/chores/occurrences/domain/occurrence_status.dart';

final class StreakState {
  const StreakState({
    required this.current,
    required this.best,
    required this.pausedDays,
    required this.asOfDateKey,
  }) : assert(current >= 0),
       assert(best >= current),
       assert(pausedDays >= 0);

  static const StreakState empty = StreakState(
    current: 0,
    best: 0,
    pausedDays: 0,
    asOfDateKey: null,
  );

  final int current;
  final int best;
  final int pausedDays;
  final DateKey? asOfDateKey;

  StreakState copyWith({
    int? current,
    int? best,
    int? pausedDays,
    DateKey? asOfDateKey,
    bool clearAsOfDateKey = false,
  }) => StreakState(
    current: current ?? this.current,
    best: best ?? this.best,
    pausedDays: pausedDays ?? this.pausedDays,
    asOfDateKey: clearAsOfDateKey ? null : (asOfDateKey ?? this.asOfDateKey),
  );

  @override
  bool operator ==(Object other) =>
      other is StreakState &&
      other.current == current &&
      other.best == best &&
      other.pausedDays == pausedDays &&
      other.asOfDateKey == asOfDateKey;

  @override
  int get hashCode => Object.hash(current, best, pausedDays, asOfDateKey);
}

final class StreakDay {
  const StreakDay({required this.eligible, required this.completed})
    : assert(eligible >= 0),
      assert(completed >= 0),
      assert(completed <= eligible);

  final int eligible;
  final int completed;

  StreakDay copyWith({int? eligible, int? completed}) => StreakDay(
    eligible: eligible ?? this.eligible,
    completed: completed ?? this.completed,
  );

  @override
  bool operator ==(Object other) =>
      other is StreakDay &&
      other.eligible == eligible &&
      other.completed == completed;

  @override
  int get hashCode => Object.hash(eligible, completed);
}

final class StreakDayFacts {
  StreakDayFacts({
    required this.startedOn,
    required this.today,
    required Map<DateKey, StreakDay> days,
  }) : days = Map<DateKey, StreakDay>.unmodifiable(days);

  final DateKey startedOn;
  final DateKey today;
  final Map<DateKey, StreakDay> days;

  StreakDayFacts copyWith({
    DateKey? startedOn,
    DateKey? today,
    Map<DateKey, StreakDay>? days,
  }) => StreakDayFacts(
    startedOn: startedOn ?? this.startedOn,
    today: today ?? this.today,
    days: days ?? this.days,
  );

  @override
  bool operator ==(Object other) =>
      other is StreakDayFacts &&
      other.startedOn == startedOn &&
      other.today == today &&
      _sameDays(other.days, days);

  @override
  int get hashCode => Object.hash(
    startedOn,
    today,
    Object.hashAllUnordered(
      days.entries.map((entry) => Object.hash(entry.key, entry.value)),
    ),
  );

  factory StreakDayFacts.fromOccurrences({
    required DateKey startedOn,
    required DateKey today,
    required Iterable<ChoreOccurrence> items,
    required String viewerId,
    bool Function(ChoreOccurrence item) absenceNeutral = _notNeutral,
  }) {
    final eligibleByDay = <DateKey, int>{};
    final completedByDay = <DateKey, int>{};
    for (final item in items) {
      if (item.isDeleted ||
          item.dateKey.isBefore(startedOn) ||
          item.dateKey.isAfter(today) ||
          item.assigneeId != viewerId ||
          item.skipReason != null ||
          item.status == OccurrenceStatus.skipped ||
          absenceNeutral(item)) {
        continue;
      }

      eligibleByDay.update(
        item.dateKey,
        (count) => count + 1,
        ifAbsent: () => 1,
      );
      final status = effectiveStatus(item);
      if (status == ChoreStatus.completed || status == ChoreStatus.verified) {
        completedByDay.update(
          item.dateKey,
          (count) => count + 1,
          ifAbsent: () => 1,
        );
      }
    }

    final days = <DateKey, StreakDay>{
      for (final date in eligibleByDay.keys)
        date: StreakDay(
          eligible: eligibleByDay[date]!,
          completed: completedByDay[date] ?? 0,
        ),
    };
    return StreakDayFacts(startedOn: startedOn, today: today, days: days);
  }
}

abstract final class StreakCalculator {
  static StreakState advance(StreakState prev, StreakDayFacts dayFacts) {
    final yesterday = dayFacts.today.addDays(-1);
    var cursor = prev.asOfDateKey?.addDays(1) ?? dayFacts.startedOn;
    if (cursor.isBefore(dayFacts.startedOn)) cursor = dayFacts.startedOn;
    var current = prev.current;
    var best = prev.best;
    var pausedDays = prev.pausedDays;
    DateKey? asOf = prev.asOfDateKey;

    while (!cursor.isAfter(yesterday)) {
      final day =
          dayFacts.days[cursor] ?? const StreakDay(eligible: 0, completed: 0);
      if (day.eligible == 0) {
        pausedDays++;
      } else if (day.completed == day.eligible) {
        current++;
        if (current > best) best = current;
      } else {
        current = 0;
      }
      asOf = cursor;
      cursor = cursor.addDays(1);
    }

    if (dayFacts.today == cursor) {
      final today = dayFacts.days[dayFacts.today];
      if (today != null &&
          today.eligible > 0 &&
          today.completed == today.eligible) {
        current++;
        if (current > best) best = current;
        asOf = dayFacts.today;
      }
    }

    return StreakState(
      current: current,
      best: best,
      pausedDays: pausedDays,
      asOfDateKey: asOf,
    );
  }
}

bool _notNeutral(ChoreOccurrence _) => false;

bool _sameDays(Map<DateKey, StreakDay> first, Map<DateKey, StreakDay> second) {
  if (first.length != second.length) return false;
  return first.entries.every((entry) => second[entry.key] == entry.value);
}
