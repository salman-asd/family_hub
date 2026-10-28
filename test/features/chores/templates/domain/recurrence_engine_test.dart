import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/core/utils/date_ranges.dart';
import 'package:family_hub/features/chores/templates/domain/recurrence/recurrence.dart';
import 'package:family_hub/features/chores/templates/domain/recurrence/recurrence_engine.dart';
import 'package:flutter_test/flutter_test.dart';

/// Appendix F.1 (road map) as a data-driven test, plus the fuzz and ordering
/// invariants. Dates: 2026-10-24 is a Saturday.
void main() {
  DateKey d(String iso) => DateKey.parse(iso).valueOrNull!;
  DateKeyRange month(MonthKey m) => monthRange(m);
  final oct = [for (var i = 1; i <= 31; i++) DateKey(2026, 10, i)];

  bool on(Recurrence r, String day) => RecurrenceEngine.occursOn(r, d(day));

  group('F.1 rows 1-9: once, daily, every_n_days, weekdays, every_n_weeks', () {
    test('#1 once 2026-11-05', () {
      final r = OnceRecurrence(d('2026-11-05'));
      expect(on(r, '2026-11-05'), isTrue);
      expect(on(r, '2026-11-06'), isFalse);
    });

    test('#2 daily with an inclusive end', () {
      final dates = RecurrenceEngine.datesIn(
        const DailyRecurrence(),
        DateKeyRange(d('2026-10-24'), d('2026-10-28')),
        startDate: d('2026-10-25'),
        endDate: d('2026-10-27'),
      );
      expect(dates.map((x) => x.toString()), [
        '2026-10-25',
        '2026-10-26',
        '2026-10-27',
      ]);
    });

    test('#3 every 3 days from 10-01, before the anchor too', () {
      final r = EveryNDaysRecurrence(n: 3, anchor: d('2026-10-01'));
      expect(on(r, '2026-10-04'), isTrue);
      expect(on(r, '2026-10-28'), isTrue);
      expect(on(r, '2026-10-31'), isTrue);
      expect(on(r, '2026-09-28'), isTrue, reason: 'a day before the anchor');
      expect(on(r, '2026-09-29'), isFalse);
    });

    test('#4 every Saturday in October 2026', () {
      final r = const WeekdaysRecurrence(weekdays: [6]);
      final dates = RecurrenceEngine.datesIn(r, month(MonthKey(2026, 10)));
      expect(dates.map((x) => x.day), [3, 10, 17, 24, 31]);
    });

    test('#5 Monday and Wednesday in October 2026', () {
      final r = const WeekdaysRecurrence(weekdays: [1, 3]);
      final dates = RecurrenceEngine.datesIn(r, month(MonthKey(2026, 10)));
      expect(dates.map((x) => x.day), [5, 7, 12, 14, 19, 21, 26, 28]);
    });

    test('#6 every 2 weeks on Saturday, week start Saturday', () {
      final r = EveryNWeeksRecurrence(
        n: 2,
        anchor: d('2026-10-03'),
        weekdays: [6],
        weekStart: DateTime.saturday,
      );
      final dates = RecurrenceEngine.datesIn(
        r,
        DateKeyRange(d('2026-10-01'), d('2026-11-21')),
      );
      expect(dates.map((x) => x.toString()), [
        '2026-10-03',
        '2026-10-17',
        '2026-10-31',
        '2026-11-14',
      ]);
    });

    test('#7 the same pattern with week start Sunday gives the same days', () {
      final r = EveryNWeeksRecurrence(
        n: 2,
        anchor: d('2026-10-03'),
        weekdays: [6],
        weekStart: DateTime.sunday,
      );
      final dates = RecurrenceEngine.datesIn(
        r,
        DateKeyRange(d('2026-10-01'), d('2026-11-21')),
      );
      expect(dates.map((x) => x.toString()), [
        '2026-10-03',
        '2026-10-17',
        '2026-10-31',
        '2026-11-14',
      ]);
    });

    test('#8 every 2 weeks on Sunday, week start Saturday', () {
      final r = EveryNWeeksRecurrence(
        n: 2,
        anchor: d('2026-10-03'),
        weekdays: [7],
        weekStart: DateTime.saturday,
      );
      final dates = RecurrenceEngine.datesIn(r, month(MonthKey(2026, 10)));
      expect(dates.map((x) => x.day), [4, 18]);
    });

    test(
      '#9 every 2 weeks on Sunday, week start Sunday (why it is stored)',
      () {
        final r = EveryNWeeksRecurrence(
          n: 2,
          anchor: d('2026-10-03'),
          weekdays: [7],
          weekStart: DateTime.sunday,
        );
        final dates = RecurrenceEngine.datesIn(r, month(MonthKey(2026, 10)));
        expect(dates.map((x) => x.day), [11, 25]);
      },
    );
  });

  group('F.1 rows 10-17: days_of_month, nth_weekday, last_day', () {
    test('#10 day 31 clamped fires on every month end', () {
      final r = const DaysOfMonthRecurrence(days: [31]);
      expect(on(r, '2026-10-31'), isTrue);
      expect(on(r, '2026-11-30'), isTrue);
      expect(on(r, '2027-02-28'), isTrue);
      expect(on(r, '2028-02-29'), isTrue);
    });

    test('#11 day 31 with skip does not fire in November', () {
      final r = const DaysOfMonthRecurrence(
        days: [31],
        monthEnd: MonthEndMode.skip,
      );
      expect(on(r, '2026-10-31'), isTrue);
      expect(on(r, '2026-11-30'), isFalse);
    });

    test('#12 day 29 follows the same clamp rule', () {
      final r = const DaysOfMonthRecurrence(days: [29]);
      expect(on(r, '2027-02-28'), isTrue);
      expect(on(r, '2028-02-29'), isTrue);
      expect(on(r, '2028-02-28'), isFalse);
    });

    test('#13 days 1 and 15 in November 2026', () {
      final r = const DaysOfMonthRecurrence(days: [1, 15]);
      final dates = RecurrenceEngine.datesIn(r, month(MonthKey(2026, 11)));
      expect(dates.map((x) => x.toString()), ['2026-11-01', '2026-11-15']);
    });

    test('#14 first Saturday', () {
      final r = const NthWeekdayRecurrence(nth: 1, weekday: DateTime.saturday);
      expect(on(r, '2026-10-03'), isTrue);
      expect(on(r, '2026-11-07'), isTrue);
    });

    test('#15 last Friday', () {
      final r = const NthWeekdayRecurrence(nth: -1, weekday: DateTime.friday);
      expect(on(r, '2026-10-30'), isTrue);
      expect(on(r, '2026-11-27'), isTrue);
    });

    test('#16 fourth Monday of November 2026', () {
      final r = const NthWeekdayRecurrence(nth: 4, weekday: DateTime.monday);
      expect(on(r, '2026-11-23'), isTrue);
      // October 2026 has only four Mondays: the 26th is the fourth.
      expect(on(r, '2026-10-26'), isTrue);
      expect(on(r, '2026-11-16'), isFalse);
    });

    test('#17 last_day fires on every month end', () {
      const r = LastDayRecurrence();
      for (final day in [
        '2026-10-31',
        '2026-11-30',
        '2027-02-28',
        '2028-02-29',
      ]) {
        expect(on(r, day), isTrue, reason: day);
      }
      expect(on(r, '2026-10-30'), isFalse);
    });
  });

  group('F.1 rows 18-24: span clipping and nextAfter', () {
    test('#18 a daily chore does not fire before its start', () {
      expect(
        RecurrenceEngine.occursOn(
          const DailyRecurrence(),
          d('2026-10-31'),
          startDate: d('2026-11-01'),
        ),
        isFalse,
      );
    });

    test('#24 nextAfter returns null past the end date', () {
      expect(
        RecurrenceEngine.nextAfter(
          const DailyRecurrence(),
          d('2026-10-27'),
          endDate: d('2026-10-27'),
        ),
        isNull,
      );
    });

    test('nextAfter skips to the next real day', () {
      final r = const WeekdaysRecurrence(weekdays: [6]);
      // 2026-10-24 is a Saturday; the next one is the 31st.
      expect(RecurrenceEngine.nextAfter(r, d('2026-10-24')), d('2026-10-31'));
    });

    test('nextAfter is bounded by the search limit', () {
      // A once day 500 days away is never "next" within the 400-day limit.
      final far = OnceRecurrence(d('2028-01-01'));
      expect(RecurrenceEngine.nextAfter(far, d('2026-10-24')), isNull);
    });

    test('endDate clips datesIn as well', () {
      final dates = RecurrenceEngine.datesIn(
        const DailyRecurrence(),
        month(MonthKey(2026, 10)),
        endDate: d('2026-10-03'),
      );
      expect(dates.map((x) => x.day), [1, 2, 3]);
    });
  });

  group('F.1 rows 25-26: fuzz and invariants', () {
    final kinds = <String, Recurrence>{
      'once': OnceRecurrence(d('2026-03-04')),
      'daily': const DailyRecurrence(),
      'every_n_days': EveryNDaysRecurrence(n: 5, anchor: d('2026-09-17')),
      'weekdays': const WeekdaysRecurrence(weekdays: [2, 6]),
      'every_n_weeks': EveryNWeeksRecurrence(
        n: 3,
        anchor: d('2026-08-01'),
        weekdays: [1, 4],
        weekStart: DateTime.saturday,
      ),
      'days_of_month': const DaysOfMonthRecurrence(days: [31, 15]),
      'days_of_month_skip': const DaysOfMonthRecurrence(
        days: [30],
        monthEnd: MonthEndMode.skip,
      ),
      'nth_weekday': const NthWeekdayRecurrence(
        nth: 2,
        weekday: DateTime.wednesday,
      ),
      'last_day': const LastDayRecurrence(),
    };

    test('#25 datesIn equals a 365-day filter of occursOn, for every kind', () {
      final range = DateKeyRange(d('2026-01-01'), d('2026-12-31'));
      for (final entry in kinds.entries) {
        final r = entry.value;
        final expected = daysIn(range)
            .where((day) => RecurrenceEngine.occursOn(r, day))
            .toList();
        expect(RecurrenceEngine.datesIn(r, range), expected, reason: entry.key);
        expect(
          expected,
          isNotEmpty,
          reason: '${entry.key} fires at least once',
        );
      }
    });

    test('#26 datesIn is ascending, unique and inside the span', () {
      final range = DateKeyRange(d('2026-09-01'), d('2026-12-31'));
      for (final entry in kinds.entries) {
        final dates = RecurrenceEngine.datesIn(
          entry.value,
          range,
          startDate: d('2026-10-01'),
          endDate: d('2026-11-30'),
        );
        expect(dates.toSet(), hasLength(dates.length), reason: entry.key);
        for (var i = 1; i < dates.length; i++) {
          expect(dates[i].isAfter(dates[i - 1]), isTrue, reason: entry.key);
        }
        for (final day in dates) {
          expect(day.isBefore(d('2026-10-01')), isFalse, reason: entry.key);
          expect(day.isAfter(d('2026-11-30')), isFalse, reason: entry.key);
        }
      }
    });

    test('a 5th weekday does not exist and is not invented', () {
      expect(
        RecurrenceEngine.nthWeekdayOf(MonthKey(2026, 10), 5, DateTime.monday),
        isNull,
      );
      expect(
        RecurrenceEngine.nthWeekdayOf(MonthKey(2026, 10), 1, DateTime.monday),
        DateKey(2026, 10, 5),
      );
      expect(
        RecurrenceEngine.nthWeekdayOf(MonthKey(2026, 10), -1, DateTime.monday),
        DateKey(2026, 10, 26),
      );
    });

    test('countBetween agrees with datesIn', () {
      final r = const WeekdaysRecurrence(weekdays: [6]);
      expect(
        RecurrenceEngine.countBetween(r, d('2026-10-01'), d('2026-10-31')),
        5,
      );
      expect(
        RecurrenceEngine.countBetween(r, d('2026-10-31'), d('2026-10-01')),
        0,
        reason: 'an inverted range counts nothing instead of throwing',
      );
    });

    test('a once day outside the range costs one comparison', () {
      final r = OnceRecurrence(d('2030-01-01'));
      expect(RecurrenceEngine.datesIn(r, month(MonthKey(2026, 10))), isEmpty);
      expect(oct, isNotEmpty);
    });
  });
}
