import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/core/utils/month_matrix.dart';
import 'package:flutter_test/flutter_test.dart';

/// P3-02: every week start 1–7 × a set of months, plus the invariants the
/// calendar relies on (full weeks, contiguous days, correct first cell).
void main() {
  final months = <MonthKey>[
    MonthKey(2026, 2), // 28 days, starts on a Sunday
    MonthKey(2026, 10), // 31 days, starts on a Thursday
    MonthKey(2028, 2), // leap February, 29 days
  ];

  test('weekdayOrder rotates from the week start', () {
    expect(MonthMatrix.weekdayOrder(DateTime.saturday), [6, 7, 1, 2, 3, 4, 5]);
    expect(MonthMatrix.weekdayOrder(DateTime.monday), [1, 2, 3, 4, 5, 6, 7]);
    expect(MonthMatrix.weekdayOrder(DateTime.sunday), [7, 1, 2, 3, 4, 5, 6]);
    for (var start = 1; start <= 7; start++) {
      final order = MonthMatrix.weekdayOrder(start);
      expect(order, hasLength(7));
      expect(order.toSet(), {1, 2, 3, 4, 5, 6, 7});
      expect(order.first, start);
    }
  });

  group('build', () {
    test('October 2026 with a Saturday week start', () {
      final grid = MonthMatrix.build(MonthKey(2026, 10), DateTime.saturday);
      // 1 Oct 2026 is a Thursday: the grid opens on Saturday 26 September and
      // the month spans six Saturday-started weeks, so the row after 30 Oct
      // is still part of it.
      expect(grid.rows, hasLength(6));
      expect(grid.rows.first.first, DateKey(2026, 9, 26));
      expect(grid.rows.first.last, DateKey(2026, 10, 2));
      expect(grid.rows.last.last, DateKey(2026, 11, 6));
      expect(grid.rows[1].first, DateKey(2026, 10, 3));
    });

    test(
      'a six-row month is padded at the end (August 2026, Sunday start)',
      () {
        final grid = MonthMatrix.build(MonthKey(2026, 8), DateTime.sunday);
        expect(grid.rows, hasLength(6));
        expect(grid.rows.first.first, DateKey(2026, 7, 26));
        expect(grid.rows.last.last, DateKey(2026, 9, 5));
      },
    );

    test('a four-row month is possible (February 2026, Sunday start)', () {
      // 1 Feb 2026 is a Sunday and the month has 28 days: exactly four weeks.
      final grid = MonthMatrix.build(MonthKey(2026, 2), DateTime.sunday);
      expect(grid.rows, hasLength(4));
      expect(grid.rows.first.first, DateKey(2026, 2, 1));
      expect(grid.rows.last.last, DateKey(2026, 2, 28));
    });

    test('a leap February spills into March', () {
      final grid = MonthMatrix.build(MonthKey(2028, 2), DateTime.monday);
      expect(grid.rows, hasLength(5));
      expect(grid.rows.expand((row) => row), contains(DateKey(2028, 2, 29)));
      expect(grid.isInMonth(DateKey(2028, 2, 29)), isTrue);
      expect(grid.isInMonth(DateKey(2028, 3, 1)), isFalse);
    });

    test(
      'every weekday order on every month: full, contiguous, unique rows',
      () {
        for (var start = 1; start <= 7; start++) {
          for (final month in months) {
            final grid = MonthMatrix.build(month, start);
            expect(grid.rows.length, inInclusiveRange(4, 6));
            final days = grid.days;
            expect(days, hasLength(grid.rows.length * 7));
            expect(
              days.toSet(),
              hasLength(days.length),
              reason: 'no duplicates',
            );
            for (var i = 1; i < days.length; i++) {
              expect(
                days[i].epochDay - days[i - 1].epochDay,
                1,
                reason: 'contiguous days in $month from $start',
              );
            }
            for (var row = 0; row < grid.rows.length; row++) {
              expect(grid.rows[row], hasLength(7));
              expect(
                grid.rows[row].first.isoWeekday,
                start,
                reason: 'row $row of $month starts on $start',
              );
            }
            expect(days, contains(month.startOfMonth));
            expect(days, contains(month.endOfMonth));
          }
        }
      },
    );

    test('days is flattened row by row', () {
      final grid = MonthMatrix.build(MonthKey(2026, 10), DateTime.saturday);
      expect(grid.days.take(7), grid.rows.first);
      expect(grid.days.skip(7).take(7), grid.rows[1]);
    });
  });

  group('weekOf', () {
    test('Saturday to Friday for a Saturday week start', () {
      final grid = MonthMatrix.build(MonthKey(2026, 10), DateTime.saturday);
      expect(
        grid.weekContaining(DateKey(2026, 10, 14)),
        DateKeyRange(DateKey(2026, 10, 10), DateKey(2026, 10, 16)),
      );
      expect(
        MonthMatrix.weekOf(DateKey(2026, 10, 14), DateTime.friday),
        DateKeyRange(DateKey(2026, 10, 9), DateKey(2026, 10, 15)),
      );
    });

    test('week rows of the grid are the weeks of their days', () {
      final grid = MonthMatrix.build(MonthKey(2026, 10), DateTime.saturday);
      for (final row in grid.rows) {
        expect(grid.weekContaining(row[3]), DateKeyRange(row.first, row.last));
      }
    });

    test('a week start outside the range is asserted', () {
      expect(() => MonthMatrix.weekdayOrder(0), throwsA(isA<AssertionError>()));
      expect(() => MonthMatrix.weekdayOrder(8), throwsA(isA<AssertionError>()));
    });
  });
}
