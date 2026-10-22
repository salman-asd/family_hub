import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/core/utils/date_ranges.dart';
import 'package:flutter_test/flutter_test.dart';

DateKey _day(int year, int month, int day) => DateKey(year, month, day);

DateKeyRange _range(int y1, int m1, int d1, int y2, int m2, int d2) =>
    DateKeyRange(_day(y1, m1, d1), _day(y2, m2, d2));

void main() {
  // Wednesday, 2026-10-21 (the roadmap's example).
  final wednesday = _day(2026, 10, 21);

  group('resolveRange', () {
    test('today and yesterday', () {
      expect(
        resolveRange(RangePreset.today, today: wednesday),
        _range(2026, 10, 21, 2026, 10, 21),
      );
      expect(
        resolveRange(RangePreset.yesterday, today: wednesday),
        _range(2026, 10, 20, 2026, 10, 20),
      );
    });

    test('last 7 days includes today', () {
      expect(
        resolveRange(RangePreset.last7Days, today: wednesday),
        _range(2026, 10, 15, 2026, 10, 21),
      );
    });

    test('this week starts on Saturday by default', () {
      expect(
        resolveRange(RangePreset.thisWeek, today: wednesday),
        _range(2026, 10, 17, 2026, 10, 23),
      );
    });

    test('this week honours a Monday start', () {
      expect(
        resolveRange(
          RangePreset.thisWeek,
          today: wednesday,
          weekStartDay: DateTime.monday,
        ),
        _range(2026, 10, 19, 2026, 10, 25),
      );
    });

    test('this month and last month', () {
      expect(
        resolveRange(RangePreset.thisMonth, today: wednesday),
        _range(2026, 10, 1, 2026, 10, 31),
      );
      expect(
        resolveRange(RangePreset.lastMonth, today: wednesday),
        _range(2026, 9, 1, 2026, 9, 30),
      );
    });

    test('last month from January crosses the year boundary', () {
      expect(
        resolveRange(RangePreset.lastMonth, today: _day(2026, 1, 15)),
        _range(2025, 12, 1, 2025, 12, 31),
      );
    });

    test('leap day', () {
      expect(
        resolveRange(RangePreset.thisMonth, today: _day(2024, 2, 29)),
        _range(2024, 2, 1, 2024, 2, 29),
      );
      expect(
        resolveRange(RangePreset.lastMonth, today: _day(2024, 3, 1)),
        _range(2024, 2, 1, 2024, 2, 29),
      );
    });

    test('this year', () {
      expect(
        resolveRange(RangePreset.thisYear, today: wednesday),
        _range(2026, 1, 1, 2026, 12, 31),
      );
    });

    test('custom is returned unchanged', () {
      final custom = _range(2026, 10, 2, 2026, 10, 9);
      expect(
        resolveRange(RangePreset.custom, today: wednesday, custom: custom),
        custom,
      );
    });

    test('custom requires a range', () {
      expect(
        () => resolveRange(RangePreset.custom, today: wednesday),
        throwsA(isA<AssertionError>()),
      );
    });

    test('custom rejects a reversed range', () {
      expect(
        () => resolveRange(
          RangePreset.custom,
          today: wednesday,
          custom: _range(2026, 10, 9, 2026, 10, 2),
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('startOfWeek', () {
    test('Saturday start', () {
      expect(startOfWeek(wednesday, DateTime.saturday), _day(2026, 10, 17));
      expect(
        startOfWeek(_day(2026, 10, 17), DateTime.saturday),
        _day(2026, 10, 17),
      );
      expect(
        startOfWeek(_day(2026, 10, 23), DateTime.saturday),
        _day(2026, 10, 17),
      );
    });

    test('Sunday and Monday starts', () {
      expect(startOfWeek(wednesday, DateTime.sunday), _day(2026, 10, 18));
      expect(startOfWeek(wednesday, DateTime.monday), _day(2026, 10, 19));
    });

    test('rejects an invalid week start', () {
      expect(() => startOfWeek(wednesday, 0), throwsA(isA<AssertionError>()));
      expect(() => startOfWeek(wednesday, 8), throwsA(isA<AssertionError>()));
    });
  });

  group('previousComparable', () {
    test('a full month compares with the previous full month', () {
      expect(
        previousComparable(_range(2026, 3, 1, 2026, 3, 31)),
        _range(2026, 2, 1, 2026, 2, 28),
      );
    });

    test('a full leap February compares with January', () {
      expect(
        previousComparable(_range(2024, 2, 1, 2024, 2, 29)),
        _range(2024, 1, 1, 2024, 1, 31),
      );
    });

    test('a full year compares with the previous year', () {
      expect(
        previousComparable(_range(2026, 1, 1, 2026, 12, 31)),
        _range(2025, 1, 1, 2025, 12, 31),
      );
    });

    test('any other range keeps its length and ends the day before', () {
      expect(
        previousComparable(_range(2026, 10, 10, 2026, 10, 16)),
        _range(2026, 10, 3, 2026, 10, 9),
      );
      expect(
        previousComparable(_range(2026, 1, 1, 2026, 1, 3)),
        _range(2025, 12, 29, 2025, 12, 31),
      );
    });
  });

  test('lengthInDays counts inclusively', () {
    expect(lengthInDays(_range(2026, 10, 21, 2026, 10, 21)), 1);
    expect(lengthInDays(_range(2026, 10, 17, 2026, 10, 23)), 7);
    expect(lengthInDays(_range(2024, 2, 1, 2024, 2, 29)), 29);
  });

  test('daysIn walks every day in order', () {
    final days = daysIn(_range(2026, 10, 30, 2026, 11, 2)).toList();
    expect(days, [
      _day(2026, 10, 30),
      _day(2026, 10, 31),
      _day(2026, 11, 1),
      _day(2026, 11, 2),
    ]);
    expect(daysIn(_range(2026, 10, 21, 2026, 10, 21)), hasLength(1));
  });

  test('monthsIn lists every month touched', () {
    expect(monthsIn(_range(2026, 10, 30, 2026, 11, 2)), [
      MonthKey(2026, 10),
      MonthKey(2026, 11),
    ]);
    expect(monthsIn(_range(2025, 12, 20, 2026, 1, 5)), [
      MonthKey(2025, 12),
      MonthKey(2026, 1),
    ]);
    expect(monthsIn(_range(2026, 10, 1, 2026, 10, 31)), [MonthKey(2026, 10)]);
  });
}
