import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/core/utils/date_ranges.dart';
import 'package:family_hub/features/chores/templates/domain/recurrence/recurrence.dart';

/// Answers "does this recurrence fire on this day?" (road map P3-05).
///
/// Everything is computed on household LOCAL calendar days ([DateKey]); no
/// `DateTime`, no UTC, no clock. The same instance is used by the generator,
/// the rotation `occurrence` unit and the editor preview, so they can never
/// disagree.
abstract final class RecurrenceEngine {
  /// True when [r] fires on [day], clipped to the template's active span.
  ///
  /// [startDate] is inclusive, [endDate] is inclusive; either may be null.
  static bool occursOn(
    Recurrence r,
    DateKey day, {
    DateKey? startDate,
    DateKey? endDate,
  }) {
    if (startDate != null && day.isBefore(startDate)) return false;
    if (endDate != null && day.isAfter(endDate)) return false;
    return switch (r) {
      OnceRecurrence(:final date) => day == date,
      DailyRecurrence() => true,
      EveryNDaysRecurrence(:final n, :final anchor) =>
        n > 0 && (day.epochDay - anchor.epochDay) % n == 0,
      WeekdaysRecurrence(:final weekdays) => weekdays.contains(day.isoWeekday),
      EveryNWeeksRecurrence() => _everyNWeeksOccurs(r, day),
      DaysOfMonthRecurrence() => _daysOfMonthOccurs(r, day),
      NthWeekdayRecurrence(:final nth, :final weekday) =>
        nthWeekdayOf(day.monthKey, nth, weekday) == day,
      LastDayRecurrence() => day == day.monthKey.endOfMonth,
    };
  }

  /// Every firing day inside [range], ascending, unique, clipped to the
  /// template's span. A `once` before the range costs one comparison, so the
  /// scan is bounded by the range length (months, not years).
  static List<DateKey> datesIn(
    Recurrence r,
    DateKeyRange range, {
    DateKey? startDate,
    DateKey? endDate,
  }) {
    var from = range.start;
    var to = range.end;
    if (startDate != null && from.isBefore(startDate)) from = startDate;
    if (endDate != null && to.isAfter(endDate)) to = endDate;
    if (from.isAfter(to)) return const <DateKey>[];

    // A `once` day is a single candidate: never walk the whole range for it.
    if (r is OnceRecurrence) {
      final inRange = r.date.compareTo(from) >= 0 && r.date.compareTo(to) <= 0;
      return inRange ? <DateKey>[r.date] : const <DateKey>[];
    }

    final days = <DateKey>[];
    for (final day in daysIn(DateKeyRange(from, to))) {
      if (occursOn(r, day)) days.add(day);
    }
    return List<DateKey>.unmodifiable(days);
  }

  /// The first firing day strictly after [after], or null.
  ///
  /// Looks at most [limit] days ahead (400 by default): a recurrence whose next
  /// day is further away is a template problem the validator reports, and a
  /// generator must never scan forever.
  static DateKey? nextAfter(
    Recurrence r,
    DateKey after, {
    DateKey? endDate,
    int limit = RecurrenceLimits.searchLimitDays,
  }) {
    var day = after.addDays(1);
    for (var i = 0; i < limit; i++) {
      if (endDate != null && day.isAfter(endDate)) return null;
      if (occursOn(r, day, endDate: endDate)) return day;
      day = day.addDays(1);
    }
    return null;
  }

  /// How many times [r] fires in the inclusive range (the rotation `occurrence`
  /// unit counts these).
  static int countBetween(
    Recurrence r,
    DateKey from,
    DateKey to, {
    DateKey? startDate,
    DateKey? endDate,
  }) {
    if (from.isAfter(to)) return 0;
    return datesIn(
      r,
      DateKeyRange(from, to),
      startDate: startDate,
      endDate: endDate,
    ).length;
  }

  /// The [nth] [weekday] of [month]; [nth] is 1 … 4, or -1 for the last one.
  ///
  /// Returns null for an impossible request (a 5th Monday), so the caller can
  /// treat it as "this month does not fire" instead of guessing.
  static DateKey? nthWeekdayOf(MonthKey month, int nth, int weekday) {
    if (weekday < DateTime.monday || weekday > DateTime.sunday) return null;
    if (nth == -1) {
      final last = month.endOfMonth;
      return last.addDays(-((last.isoWeekday - weekday + 7) % 7));
    }
    if (nth < 1 || nth > 4) return null;
    final first = month.startOfMonth;
    final offset = (weekday - first.isoWeekday + 7) % 7;
    final day = first.addDays(offset + (nth - 1) * 7);
    return day.monthKey == month ? day : null;
  }

  /// `week index = floor((day − weekStartOf(anchor)) / 7)`, fires when the
  /// index is a multiple of `n` AND the weekday is chosen.
  static bool _everyNWeeksOccurs(EveryNWeeksRecurrence r, DateKey day) {
    if (r.n <= 0 || !r.weekdays.contains(day.isoWeekday)) return false;
    final weekStartDay = r.weekStart;
    if (weekStartDay < DateTime.monday || weekStartDay > DateTime.sunday) {
      return false;
    }
    final anchorWeek = startOfWeek(r.anchor, weekStartDay);
    final distance = day.epochDay - anchorWeek.epochDay;
    // Dart's ~/ truncates toward zero, but the week index must floor, or a day
    // before the anchor lands in week 0 and fires wrongly.
    final index = _floorDiv(distance, 7);
    return index % r.n == 0;
  }

  /// A `days_of_month` rule: the chosen day, or (clamp) the month's last day
  /// when the month is shorter. Feb 29 follows the same rule.
  static bool _daysOfMonthOccurs(DaysOfMonthRecurrence r, DateKey day) {
    final days = r.days;
    if (days.isEmpty) return false;
    final lastDay = day.monthKey.daysInMonth;
    if (days.contains(day.day)) return true;
    if (r.monthEnd == MonthEndMode.skip) return false;
    // clamp: a day beyond this month's length fires on its last day.
    return day.day == lastDay && days.any((d) => d > lastDay);
  }

  /// `a ~/ b` that floors for a negative [a] too (Dart's `~/` truncates, and
  /// `%` keeps the sign of the dividend).
  static int _floorDiv(int a, int b) {
    final quotient = a ~/ b;
    final remainder = a - quotient * b;
    return remainder < 0 ? quotient - 1 : quotient;
  }
}
