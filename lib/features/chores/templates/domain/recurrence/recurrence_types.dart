part of 'recurrence.dart';

/// One specific day. The template's `startDate` still clips it.
final class OnceRecurrence extends Recurrence {
  const OnceRecurrence(this.date);

  final DateKey date;

  @override
  RecurrenceKind get kind => RecurrenceKind.once;

  @override
  Map<String, Object?> toMap() => <String, Object?>{
    'kind': kind.id,
    'date': date.toString(),
  };

  @override
  bool operator ==(Object other) =>
      other is OnceRecurrence && other.date == date;

  @override
  int get hashCode => Object.hash(kind, date);

  @override
  String toString() => 'OnceRecurrence($date)';
}

/// Every day.
final class DailyRecurrence extends Recurrence {
  const DailyRecurrence();

  @override
  RecurrenceKind get kind => RecurrenceKind.daily;

  @override
  Map<String, Object?> toMap() => <String, Object?>{'kind': kind.id};

  @override
  bool operator ==(Object other) => other is DailyRecurrence;

  @override
  int get hashCode => kind.index;

  @override
  String toString() => 'DailyRecurrence()';
}

/// Every [n] days counting from [anchor] (both directions, so a day BEFORE the
/// anchor also fires when the distance is a multiple of [n]).
final class EveryNDaysRecurrence extends Recurrence {
  const EveryNDaysRecurrence({required this.n, required this.anchor});

  final int n;
  final DateKey anchor;

  @override
  RecurrenceKind get kind => RecurrenceKind.everyNDays;

  @override
  Map<String, Object?> toMap() => <String, Object?>{
    'kind': kind.id,
    'n': n,
    'anchor': anchor.toString(),
  };

  @override
  bool operator ==(Object other) =>
      other is EveryNDaysRecurrence && other.n == n && other.anchor == anchor;

  @override
  int get hashCode => Object.hash(kind, n, anchor);

  @override
  String toString() => 'EveryNDaysRecurrence($n, $anchor)';
}

/// The chosen ISO weekdays (1 = Monday … 7 = Sunday).
final class WeekdaysRecurrence extends Recurrence {
  const WeekdaysRecurrence({required this.weekdays});

  final List<int> weekdays;

  @override
  RecurrenceKind get kind => RecurrenceKind.weekdays;

  @override
  Map<String, Object?> toMap() => <String, Object?>{
    'kind': kind.id,
    'weekdays': weekdays,
  };

  @override
  bool operator ==(Object other) =>
      other is WeekdaysRecurrence && sameIntSet(other.weekdays, weekdays);

  @override
  int get hashCode => Object.hash(kind, intSetHash(weekdays));

  @override
  String toString() => 'WeekdaysRecurrence($weekdays)';
}

/// Every [n] weeks on the chosen weekdays.
///
/// [weekStart] is SNAPSHOT into the recurrence (road map 3.2): a later change
/// of the family's week-start setting must never move the pattern.
final class EveryNWeeksRecurrence extends Recurrence {
  const EveryNWeeksRecurrence({
    required this.n,
    required this.anchor,
    required this.weekdays,
    required this.weekStart,
  });

  final int n;
  final DateKey anchor;
  final List<int> weekdays;
  final int weekStart;

  @override
  RecurrenceKind get kind => RecurrenceKind.everyNWeeks;

  @override
  Map<String, Object?> toMap() => <String, Object?>{
    'kind': kind.id,
    'n': n,
    'anchor': anchor.toString(),
    'weekdays': weekdays,
    'weekStart': weekStart,
  };

  @override
  bool operator ==(Object other) =>
      other is EveryNWeeksRecurrence &&
      other.n == n &&
      other.anchor == anchor &&
      other.weekStart == weekStart &&
      sameIntSet(other.weekdays, weekdays);

  @override
  int get hashCode =>
      Object.hash(kind, n, anchor, weekStart, intSetHash(weekdays));

  @override
  String toString() =>
      'EveryNWeeksRecurrence($n, $anchor, $weekdays, start $weekStart)';
}

/// The chosen days of the month (1 … 31).
final class DaysOfMonthRecurrence extends Recurrence {
  const DaysOfMonthRecurrence({
    required this.days,
    this.monthEnd = MonthEndMode.clamp,
  });

  final List<int> days;
  final MonthEndMode monthEnd;

  @override
  RecurrenceKind get kind => RecurrenceKind.daysOfMonth;

  @override
  Map<String, Object?> toMap() => <String, Object?>{
    'kind': kind.id,
    'days': days,
    'monthEnd': monthEnd.id,
  };

  @override
  bool operator ==(Object other) =>
      other is DaysOfMonthRecurrence &&
      other.monthEnd == monthEnd &&
      sameIntSet(other.days, days);

  @override
  int get hashCode => Object.hash(kind, monthEnd, intSetHash(days));

  @override
  String toString() => 'DaysOfMonthRecurrence($days, ${monthEnd.id})';
}

/// The [nth] [weekday] of the month; [nth] is 1 … 4, or -1 for the last one.
final class NthWeekdayRecurrence extends Recurrence {
  const NthWeekdayRecurrence({required this.nth, required this.weekday});

  final int nth;
  final int weekday;

  @override
  RecurrenceKind get kind => RecurrenceKind.nthWeekday;

  @override
  Map<String, Object?> toMap() => <String, Object?>{
    'kind': kind.id,
    'nth': nth,
    'weekday': weekday,
  };

  @override
  bool operator ==(Object other) =>
      other is NthWeekdayRecurrence &&
      other.nth == nth &&
      other.weekday == weekday;

  @override
  int get hashCode => Object.hash(kind, nth, weekday);

  @override
  String toString() => 'NthWeekdayRecurrence($nth, $weekday)';
}

/// The last calendar day of every month.
final class LastDayRecurrence extends Recurrence {
  const LastDayRecurrence();

  @override
  RecurrenceKind get kind => RecurrenceKind.lastDay;

  @override
  Map<String, Object?> toMap() => <String, Object?>{'kind': kind.id};

  @override
  bool operator ==(Object other) => other is LastDayRecurrence;

  @override
  int get hashCode => kind.index;

  @override
  String toString() => 'LastDayRecurrence()';
}

/// Order-insensitive comparison of two weekday/day lists.
bool sameIntSet(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  final set = b.toSet();
  return a.every(set.contains);
}

/// Order-insensitive hash, so `[1, 3]` and `[3, 1]` are the same value.
int intSetHash(List<int> values) =>
    Object.hashAll(values.toSet().toList()..sort());
