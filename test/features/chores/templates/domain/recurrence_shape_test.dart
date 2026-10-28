import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/features/chores/templates/domain/recurrence/recurrence.dart';
import 'package:family_hub/features/chores/templates/domain/recurrence/recurrence_describe.dart';
import 'package:family_hub/features/chores/templates/domain/recurrence/recurrence_validator.dart';
import 'package:flutter_test/flutter_test.dart';

/// Appendix F.1 rows 19-23, the stored shape (`toMap` / `fromMap`) and the
/// description value object.
void main() {
  DateKey d(String iso) => DateKey.parse(iso).valueOrNull!;

  List<String> codes(Recurrence r) =>
      RecurrenceValidator.validate(r).errors.map((e) => e.code).toList();

  group('F.1 rows 19-23: validation', () {
    test('#19 an empty weekday set has no dates', () {
      expect(codes(const WeekdaysRecurrence(weekdays: [])), ['no_dates']);
    });

    test('#20 day 32 is not a recurrence', () {
      expect(codes(const DaysOfMonthRecurrence(days: [32])), [
        'invalid_recurrence',
      ]);
      expect(codes(const DaysOfMonthRecurrence(days: [0])), [
        'invalid_recurrence',
      ]);
    });

    test('#21 every_n_days must be 2..60', () {
      expect(codes(EveryNDaysRecurrence(n: 1, anchor: d('2026-10-01'))), [
        'invalid_recurrence',
      ]);
      expect(codes(EveryNDaysRecurrence(n: 61, anchor: d('2026-10-01'))), [
        'invalid_recurrence',
      ]);
      expect(
        codes(EveryNDaysRecurrence(n: 2, anchor: d('2026-10-01'))),
        isEmpty,
      );
      expect(
        codes(EveryNDaysRecurrence(n: 60, anchor: d('2026-10-01'))),
        isEmpty,
      );
    });

    test('#22 day 31 with skip is a warning, not an error', () {
      final check = RecurrenceValidator.validate(
        const DaysOfMonthRecurrence(days: [31], monthEnd: MonthEndMode.skip),
      );
      expect(check.isValid, isTrue, reason: 'the user chose to skip');
      expect(check.warnings.map((w) => w.code), ['invalid_recurrence']);
    });

    test('#23 a once day before the start has no dates', () {
      expect(
        codes(OnceRecurrence(d('2026-09-01'))),
        isEmpty,
        reason: 'no span, nothing to clip against',
      );
      final check = RecurrenceValidator.validate(
        OnceRecurrence(d('2026-09-01')),
        startDate: d('2026-10-01'),
      );
      expect(check.isValid, isFalse);
      expect(check.errors.single.code, 'no_dates');
    });

    test('an end before the start is invalid_range', () {
      final check = RecurrenceValidator.validate(
        const DailyRecurrence(),
        startDate: d('2026-11-01'),
        endDate: d('2026-10-01'),
      );
      expect(check.errors.single.code, 'invalid_range');
    });

    test('a malformed nth or weekday is rejected', () {
      expect(codes(const NthWeekdayRecurrence(nth: 5, weekday: 3)), [
        'invalid_recurrence',
      ]);
      expect(codes(const NthWeekdayRecurrence(nth: 0, weekday: 3)), [
        'invalid_recurrence',
      ]);
      expect(codes(const NthWeekdayRecurrence(nth: 2, weekday: 9)), [
        'invalid_recurrence',
      ]);
      expect(codes(const NthWeekdayRecurrence(nth: -1, weekday: 5)), isEmpty);
    });

    test('every_n_weeks checks n, the weekday set and the week start', () {
      Recurrence rule({
        int n = 2,
        List<int> weekdays = const [6],
        int ws = 6,
      }) => EveryNWeeksRecurrence(
        n: n,
        anchor: d('2026-10-03'),
        weekdays: weekdays,
        weekStart: ws,
      );
      expect(codes(rule()), isEmpty);
      expect(codes(rule(n: 1)), ['invalid_recurrence']);
      expect(codes(rule(weekdays: const [])), ['no_dates']);
      expect(codes(rule(weekdays: const [8])), ['invalid_recurrence']);
      expect(codes(rule(ws: 0)), ['invalid_recurrence']);
    });

    test('a well-formed rule of every kind is valid', () {
      final valid = <Recurrence>[
        OnceRecurrence(d('2026-11-05')),
        const DailyRecurrence(),
        EveryNDaysRecurrence(n: 3, anchor: d('2026-10-01')),
        const WeekdaysRecurrence(weekdays: [1, 3]),
        EveryNWeeksRecurrence(
          n: 2,
          anchor: d('2026-10-03'),
          weekdays: const [6],
          weekStart: 6,
        ),
        const DaysOfMonthRecurrence(days: [1, 15]),
        const NthWeekdayRecurrence(nth: -1, weekday: 5),
        const LastDayRecurrence(),
      ];
      for (final r in valid) {
        expect(RecurrenceValidator.validate(r).errors, isEmpty, reason: '$r');
      }
    });
  });

  group('stored shape', () {
    final samples = <Recurrence>[
      OnceRecurrence(d('2026-11-05')),
      const DailyRecurrence(),
      EveryNDaysRecurrence(n: 4, anchor: d('2026-10-01')),
      const WeekdaysRecurrence(weekdays: [6]),
      EveryNWeeksRecurrence(
        n: 2,
        anchor: d('2026-10-03'),
        weekdays: const [7],
        weekStart: 7,
      ),
      const DaysOfMonthRecurrence(days: [31], monthEnd: MonthEndMode.skip),
      const NthWeekdayRecurrence(nth: 1, weekday: 6),
      const LastDayRecurrence(),
    ];

    test('toMap -> fromMap round-trips every kind', () {
      for (final r in samples) {
        final map = r.toMap();
        final back = Recurrence.fromMap(map).valueOrNull;
        expect(back, r, reason: '$r');
        expect(back!.toMap(), map, reason: 'the map is stable');
      }
    });

    test('the kind strings are the road map 3.2 ids', () {
      expect(RecurrenceKind.values.map((k) => k.id).toList(), [
        'once',
        'daily',
        'every_n_days',
        'weekdays',
        'every_n_weeks',
        'days_of_month',
        'nth_weekday',
        'last_day',
      ]);
    });

    test('an unknown or malformed shape fails with invalid_recurrence', () {
      for (final raw in <Object?>[
        null,
        'daily',
        42,
        <String, Object?>{},
        {'kind': 'hourly'},
      ]) {
        expect(
          Recurrence.fromMap(raw).failureOrNull,
          const Validation('recurrence', 'invalid_recurrence'),
          reason: '$raw',
        );
      }
    });

    test('a missing required date fails with invalid_date', () {
      expect(
        Recurrence.fromMap({'kind': 'once'}).failureOrNull,
        const Validation('recurrence', 'invalid_date'),
      );
      expect(
        Recurrence.fromMap({'kind': 'every_n_days', 'n': 3}).failureOrNull,
        const Validation('recurrence', 'invalid_date'),
      );
      expect(
        Recurrence.fromMap({'kind': 'once', 'date': '2026-02-30'})
            .failureOrNull,
        const Validation('recurrence', 'invalid_date'),
      );
    });

    test(
      'missing numbers and lists read as 0 / empty, then fail validation',
      () {
        final r = Recurrence.fromMap({'kind': 'days_of_month'}).valueOrNull!;
        expect(r, isA<DaysOfMonthRecurrence>());
        expect((r as DaysOfMonthRecurrence).days, isEmpty);
        expect(RecurrenceValidator.validate(r).errors.map((e) => e.code), [
          'no_dates',
        ]);

        final n = Recurrence.fromMap({'kind': 'nth_weekday'}).valueOrNull!;
        // Both the missing nth (0) and the missing weekday (0) are invalid, so
        // the user sees the real problem rather than a guessed default.
        expect(
          RecurrenceValidator.validate(n).errors.map((e) => e.code).toSet(),
          {'invalid_recurrence'},
        );
        expect(RecurrenceValidator.validate(n).errors, hasLength(2));
      },
    );

    test('weekday order does not change the value', () {
      expect(
        const WeekdaysRecurrence(weekdays: [1, 3]),
        const WeekdaysRecurrence(weekdays: [3, 1]),
      );
      expect(
        const WeekdaysRecurrence(weekdays: [1, 3]).hashCode,
        const WeekdaysRecurrence(weekdays: [3, 1]).hashCode,
      );
    });

    test('monthEnd defaults to clamp when absent', () {
      final r = Recurrence.fromMap({
        'kind': 'days_of_month',
        'days': [15],
      }).valueOrNull!;
      expect((r as DaysOfMonthRecurrence).monthEnd, MonthEndMode.clamp);
    });
  });

  group('RecurrenceSummary', () {
    test('carries values only, sorted, with no strings', () {
      final summary = RecurrenceSummary.of(
        const WeekdaysRecurrence(weekdays: [6, 1, 3]),
      );
      expect(summary.kind, RecurrenceKind.weekdays);
      expect(summary.weekdays, [1, 3, 6]);
      expect(summary.n, isNull);
    });

    test('an every-n-weeks summary keeps n and the weekdays', () {
      final summary = RecurrenceSummary.of(
        EveryNWeeksRecurrence(
          n: 3,
          anchor: d('2026-10-03'),
          weekdays: const [6],
          weekStart: 6,
        ),
      );
      expect(summary.kind, RecurrenceKind.everyNWeeks);
      expect(summary.n, 3);
      expect(summary.weekdays, [6]);
    });

    test(
      'the last weekday is flagged, not encoded as a number to translate',
      () {
        expect(
          RecurrenceSummary.of(const NthWeekdayRecurrence(nth: -1, weekday: 5))
              .isLast,
          isTrue,
        );
        expect(
          RecurrenceSummary.of(const NthWeekdayRecurrence(nth: 2, weekday: 5))
              .isLast,
          isFalse,
        );
      },
    );

    test('is a value object', () {
      final a = RecurrenceSummary.of(
        const DaysOfMonthRecurrence(days: [15, 1]),
      );
      final b = RecurrenceSummary.of(
        const DaysOfMonthRecurrence(days: [1, 15]),
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a.days, [1, 15]);
    });

    test('every kind produces a summary', () {
      for (final r in <Recurrence>[
        OnceRecurrence(d('2026-11-05')),
        const DailyRecurrence(),
        EveryNDaysRecurrence(n: 2, anchor: d('2026-10-01')),
        const WeekdaysRecurrence(weekdays: [1]),
        EveryNWeeksRecurrence(
          n: 2,
          anchor: d('2026-10-03'),
          weekdays: const [1],
          weekStart: 6,
        ),
        const DaysOfMonthRecurrence(days: [1]),
        const NthWeekdayRecurrence(nth: 1, weekday: 1),
        const LastDayRecurrence(),
      ]) {
        expect(RecurrenceSummary.of(r).kind, r.kind);
      }
    });
  });
}
