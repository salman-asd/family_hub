import 'package:family_hub/core/utils/date_key.dart';

/// A named range the expense/report screens offer.
enum RangePreset {
  today,
  yesterday,
  last7Days,
  thisWeek,
  thisMonth,
  lastMonth,
  thisYear,
  custom,
}

/// Resolves [preset] against [today] (a calendar day in the family timezone).
///
/// [weekStartDay] uses `DateTime` weekday numbers (1 = Monday ... 7 = Sunday)
/// and defaults to Saturday, the Bangladeshi week start. [custom] is required
/// for [RangePreset.custom]; its `start` must not be after its `end`.
DateKeyRange resolveRange(
  RangePreset preset, {
  required DateKey today,
  int weekStartDay = DateTime.saturday,
  DateKeyRange? custom,
}) {
  switch (preset) {
    case RangePreset.today:
      return DateKeyRange(today, today);
    case RangePreset.yesterday:
      final yesterday = today.addDays(-1);
      return DateKeyRange(yesterday, yesterday);
    case RangePreset.last7Days:
      return DateKeyRange(today.addDays(-6), today);
    case RangePreset.thisWeek:
      final start = startOfWeek(today, weekStartDay);
      return DateKeyRange(start, start.addDays(6));
    case RangePreset.thisMonth:
      return monthRange(today.monthKey);
    case RangePreset.lastMonth:
      return monthRange(today.monthKey.addMonths(-1));
    case RangePreset.thisYear:
      return DateKeyRange(
        DateKey(today.year, 1, 1),
        DateKey(today.year, 12, 31),
      );
    case RangePreset.custom:
      assert(custom != null, 'custom range is required for RangePreset.custom');
      assert(
        !custom!.start.isAfter(custom.end),
        'custom range start must not be after its end',
      );
      return custom!;
  }
}

/// The first day of the week containing [day].
///
/// With [weekStartDay] = Saturday, Wednesday 2026-10-21 starts on Saturday
/// 2026-10-17.
DateKey startOfWeek(DateKey day, int weekStartDay) {
  assert(
    weekStartDay >= DateTime.monday && weekStartDay <= DateTime.sunday,
    'weekStartDay must be 1..7',
  );
  return day.addDays(-((day.weekday - weekStartDay + 7) % 7));
}

/// The earlier range a comparison chart should use for [range].
///
/// A full calendar month compares with the previous full month, a full
/// calendar year with the previous year, and any other range with a range of
/// the same length immediately before it.
DateKeyRange previousComparable(DateKeyRange range) {
  assert(
    !range.start.isAfter(range.end),
    'range start must not be after its end',
  );
  final start = range.start;
  final end = range.end;

  final sameMonth = start.year == end.year && start.month == end.month;
  if (sameMonth && start.day == 1 && end.day == start.monthKey.daysInMonth) {
    return monthRange(start.monthKey.addMonths(-1));
  }

  if (start.year == end.year &&
      start.month == DateTime.january &&
      start.day == 1 &&
      end.month == DateTime.december &&
      end.day == 31) {
    assert(start.year > 1, 'there is no year before 1');
    return DateKeyRange(
      DateKey(start.year - 1, 1, 1),
      DateKey(start.year - 1, 12, 31),
    );
  }

  final length = lengthInDays(range);
  return DateKeyRange(start.addDays(-length), start.addDays(-1));
}

/// Number of calendar days in [range], inclusive.
int lengthInDays(DateKeyRange range) {
  assert(
    !range.start.isAfter(range.end),
    'range start must not be after its end',
  );
  return range.start.daysUntil(range.end) + 1;
}

/// Every day in [range], inclusive, in ascending order.
Iterable<DateKey> daysIn(DateKeyRange range) sync* {
  assert(
    !range.start.isAfter(range.end),
    'range start must not be after its end',
  );
  for (var day = range.start; !day.isAfter(range.end); day = day.addDays(1)) {
    yield day;
  }
}

/// Every calendar month touched by [range], in ascending order.
List<MonthKey> monthsIn(DateKeyRange range) {
  assert(
    !range.start.isAfter(range.end),
    'range start must not be after its end',
  );
  final months = <MonthKey>[];
  var month = range.start.monthKey;
  final last = range.end.monthKey;
  while (month.compareTo(last) <= 0) {
    months.add(month);
    month = month.addMonths(1);
  }
  return months;
}
