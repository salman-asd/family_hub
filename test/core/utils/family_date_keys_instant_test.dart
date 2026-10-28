import 'package:family_hub/core/utils/clock.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/core/utils/family_date_keys.dart';
import 'package:flutter_test/flutter_test.dart';

/// `instantOf` / `endOfDay` / `minutesOfDayOf` (P3-02, C-8).
void main() {
  final keys = FamilyDateKeys(clock: FakeClock(DateTime.utc(2026, 10, 24, 9)));

  group('instantOf — Asia/Dhaka (UTC+6, no DST)', () {
    test('Dhaka midnight is 18:00 UTC of the previous day', () {
      expect(
        keys.instantOf(DateKey(2026, 10, 15), 0),
        DateTime.utc(2026, 10, 14, 18),
      );
    });

    test('09:00 wall clock is 03:00 UTC the same day', () {
      expect(
        keys.instantOf(DateKey(2026, 10, 15), 9 * 60),
        DateTime.utc(2026, 10, 15, 3),
      );
    });

    test('23:59 is 17:59 UTC the same day, not the next one', () {
      expect(
        keys.instantOf(DateKey(2026, 10, 15), 1439),
        DateTime.utc(2026, 10, 15, 17, 59),
      );
    });

    test('00:00 of the next day follows 23:59 by exactly one minute', () {
      final last = keys.instantOf(DateKey(2026, 10, 15), 1439);
      final next = keys.instantOf(DateKey(2026, 10, 16), 0);
      expect(next.difference(last), const Duration(minutes: 1));
    });

    test('leap day 2028-02-29 round-trips at every boundary minute', () {
      final leap = DateKey(2028, 2, 29);
      for (final minutes in <int>[0, 1, 719, 720, 1438, 1439]) {
        final instant = keys.instantOf(leap, minutes);
        expect(keys.dateKeyOf(instant), leap, reason: 'minute $minutes');
        expect(keys.minutesOfDayOf(instant), minutes);
      }
    });

    test('month end: 31 Oct 23:59 is still October', () {
      final instant = keys.instantOf(DateKey(2026, 10, 31), 1439);
      expect(keys.monthKeyOf(instant), MonthKey(2026, 10));
      expect(keys.dateKeyOf(instant), DateKey(2026, 10, 31));
    });

    test('out-of-range minutes are rejected', () {
      expect(() => keys.instantOf(DateKey(2026, 10, 15), -1), throwsRangeError);
      expect(
        () => keys.instantOf(DateKey(2026, 10, 15), 1440),
        throwsRangeError,
      );
    });
  });

  group('endOfDay', () {
    test('is the last second of the Dhaka day', () {
      expect(
        keys.endOfDay(DateKey(2026, 10, 15)),
        DateTime.utc(2026, 10, 15, 17, 59, 59),
      );
    });

    test('stays inside the same calendar day and month', () {
      final end = keys.endOfDay(DateKey(2026, 12, 31));
      expect(keys.dateKeyOf(end), DateKey(2026, 12, 31));
      expect(keys.monthKeyOf(end), MonthKey(2026, 12));
    });
  });

  group('minutesOfDayOf', () {
    test('reads the family wall clock, not UTC', () {
      expect(keys.minutesOfDayOf(DateTime.utc(2026, 10, 15, 3)), 9 * 60);
      expect(keys.minutesOfDayOf(DateTime.utc(2026, 10, 14, 18)), 0);
    });

    test('the family wall clock is the same instant for every member', () {
      final instant = keys.instantOf(DateKey(2026, 10, 15), 9 * 60);
      expect(keys.minutesOfDayOf(instant), 9 * 60);
      expect(keys.dateKeyOf(instant), DateKey(2026, 10, 15));
    });

    test('another zone reads the same instant as its own wall clock', () {
      final london = keys.withTimezone('Europe/London');
      // October: London is UTC+1, Dhaka UTC+6 — five hours apart.
      final instant = keys.instantOf(DateKey(2026, 10, 15), 9 * 60);
      expect(london.minutesOfDayOf(instant), 4 * 60);
    });
  });

  group('DST (Europe/London)', () {
    final london = keys.withTimezone('Europe/London');

    test('the skipped hour of 2026-03-29 stays on the same day', () {
      // 01:00-01:59 does not exist on 29 March 2026.
      for (final minutes in <int>[60, 90, 119, 1439]) {
        final instant = london.instantOf(DateKey(2026, 3, 29), minutes);
        expect(
          london.dateKeyOf(instant),
          DateKey(2026, 3, 29),
          reason: 'minute $minutes',
        );
      }
    });

    test(
      'the repeated hour of 2026-10-25 resolves to its first occurrence',
      () {
        final instant = london.instantOf(DateKey(2026, 10, 25), 90);
        expect(instant, DateTime.utc(2026, 10, 25, 0, 30));
        expect(london.dateKeyOf(instant), DateKey(2026, 10, 25));
        expect(london.minutesOfDayOf(instant), 90);
      },
    );
  });

  group('property: dateKeyOf(instantOf(k, m)) == k', () {
    test('every minute of a sample month in Dhaka', () {
      var day = DateKey(2026, 10, 1);
      final last = DateKey(2026, 10, 31);
      while (!day.isAfter(last)) {
        for (var minutes = 0; minutes < 24 * 60; minutes += 37) {
          expect(
            keys.dateKeyOf(keys.instantOf(day, minutes)),
            day,
            reason: '$day minute $minutes',
          );
        }
        day = day.addDays(1);
      }
    });

    test('every minute of a DST month in Europe/London', () {
      final london = keys.withTimezone('Europe/London');
      var day = DateKey(2026, 3, 1);
      final last = DateKey(2026, 3, 31);
      while (!day.isAfter(last)) {
        for (var minutes = 0; minutes < 24 * 60; minutes += 61) {
          expect(
            london.dateKeyOf(london.instantOf(day, minutes)),
            day,
            reason: '$day minute $minutes',
          );
        }
        day = day.addDays(1);
      }
    });
  });
}
