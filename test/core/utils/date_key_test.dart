import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('timezone conversion', () {
    test('2026-10-14T19:00Z is 2026-10-15 in Asia/Dhaka (UTC+6)', () {
      final instant = DateTime.utc(2026, 10, 14, 19);
      expect(DateKey.fromInstant(instant).toString(), '2026-10-15');
      expect(MonthKey.fromInstant(instant).toString(), '2026-10');
    });

    test('month boundary: 31 Oct to 1 Nov', () {
      final before = DateTime.utc(2026, 10, 31, 17, 59);
      final after = DateTime.utc(2026, 10, 31, 18);
      expect(DateKey.fromInstant(before).toString(), '2026-10-31');
      expect(DateKey.fromInstant(after).toString(), '2026-11-01');
      expect(MonthKey.fromInstant(after).toString(), '2026-11');
    });

    test('another timezone is honored', () {
      final instant = DateTime.utc(2026, 10, 14, 19);
      expect(
        DateKey.fromInstant(instant, timezone: 'America/New_York').toString(),
        '2026-10-14',
      );
    });
  });

  group('DateKey', () {
    test('parse and format', () {
      expect(DateKey.parse('2026-10-14').valueOrNull, DateKey(2026, 10, 14));
      expect(DateKey(2026, 1, 5).toString(), '2026-01-05');
      expect(DateKey(2026, 1, 5).compact, '20260105');
    });

    test('rejects invalid dates', () {
      const invalid = Validation('dateKey', 'invalid_date');
      expect(DateKey.parse('2027-02-29').failureOrNull, invalid);
      expect(DateKey.parse('2026-13-01').failureOrNull, invalid);
      expect(DateKey.parse('2026-1-1').failureOrNull, invalid);
      expect(DateKey.parse('nope').failureOrNull, invalid);
    });

    test('leap day 2028-02-29 exists and addDays crosses it', () {
      expect(DateKey.parse('2028-02-29').isSuccess, isTrue);
      expect(DateKey(2028, 2, 28).addDays(1), DateKey(2028, 2, 29));
      expect(DateKey(2028, 2, 29).addDays(1), DateKey(2028, 3, 1));
      expect(DateKey(2027, 2, 28).addDays(1), DateKey(2027, 3, 1));
    });

    test('addDays across month and year, negative too', () {
      expect(DateKey(2026, 12, 31).addDays(1), DateKey(2027, 1, 1));
      expect(DateKey(2026, 3, 1).addDays(-1), DateKey(2026, 2, 28));
    });

    test('isoWeekday uses 1 = Monday ... 7 = Sunday', () {
      expect(DateKey(2026, 10, 12).isoWeekday, DateTime.monday);
      expect(DateKey(2026, 10, 16).isoWeekday, DateTime.friday);
      expect(DateKey(2026, 10, 17).isoWeekday, DateTime.saturday);
      expect(DateKey(2026, 10, 18).isoWeekday, DateTime.sunday);
      expect(DateKey(2026, 10, 18).isoWeekday, 7);
    });

    test('epochDay is whole days since 1970-01-01', () {
      expect(DateKey(1970, 1, 1).epochDay, 0);
      expect(DateKey(1970, 1, 2).epochDay, 1);
      expect(DateKey(1969, 12, 31).epochDay, -1);
      expect(DateKey(2026, 10, 14).epochDay, 20740);
    });

    test('fromEpochDay is the inverse of epochDay', () {
      expect(DateKey.fromEpochDay(0), DateKey(1970, 1, 1));
      expect(DateKey.fromEpochDay(20740), DateKey(2026, 10, 14));
      expect(
        DateKey.fromEpochDay(DateKey(2028, 2, 29).epochDay),
        DateKey(2028, 2, 29),
      );
      var day = DateKey(2026, 1, 1);
      for (var i = 0; i < 400; i++) {
        expect(DateKey.fromEpochDay(day.epochDay), day);
        day = day.addDays(1);
      }
    });

    test('daysUntil, weekday, ordering', () {
      expect(DateKey(2026, 10, 14).daysUntil(DateKey(2026, 10, 21)), 7);
      expect(DateKey(2026, 10, 21).daysUntil(DateKey(2026, 10, 14)), -7);
      expect(DateKey(2026, 10, 16).weekday, DateTime.friday);
      expect(DateKey(2026, 10, 14).isBefore(DateKey(2026, 10, 15)), isTrue);
      expect(DateKey(2026, 10, 14).isAfter(DateKey(2025, 12, 31)), isTrue);
      expect(
        '2026-09-30'.compareTo('2026-10-01') < 0,
        DateKey(2026, 9, 30).isBefore(DateKey(2026, 10, 1)),
      );
    });
  });

  group('MonthKey and monthRange', () {
    test('parse, format, addMonths', () {
      expect(MonthKey.parse('2026-10').valueOrNull, MonthKey(2026, 10));
      expect(MonthKey(2026, 3).toString(), '2026-03');
      expect(MonthKey(2026, 12).addMonths(1), MonthKey(2027, 1));
      expect(MonthKey(2026, 1).addMonths(-1), MonthKey(2025, 12));
      expect(
        MonthKey.parse('2026-00').failureOrNull,
        const Validation('monthKey', 'invalid_month'),
      );
    });

    test('daysInMonth', () {
      expect(MonthKey(2026, 10).daysInMonth, 31);
      expect(MonthKey(2026, 11).daysInMonth, 30);
      expect(MonthKey(2028, 2).daysInMonth, 29);
      expect(MonthKey(2027, 2).daysInMonth, 28);
    });

    test('monthRange of February in a leap and a non-leap year', () {
      expect(
        monthRange(MonthKey(2028, 2)),
        DateKeyRange(DateKey(2028, 2, 1), DateKey(2028, 2, 29)),
      );
      expect(
        monthRange(MonthKey(2027, 2)),
        DateKeyRange(DateKey(2027, 2, 1), DateKey(2027, 2, 28)),
      );
    });

    test('range contains is inclusive', () {
      final range = monthRange(MonthKey(2026, 10));
      expect(range.contains(DateKey(2026, 10, 1)), isTrue);
      expect(range.contains(DateKey(2026, 10, 31)), isTrue);
      expect(range.contains(DateKey(2026, 11, 1)), isFalse);
      expect(range.contains(DateKey(2026, 9, 30)), isFalse);
    });
  });
}
