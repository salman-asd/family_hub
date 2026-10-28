import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/core/utils/date_key.dart';
part 'recurrence_types.dart';

/// The `kind` strings of road map 3.2. Closed on purpose: the engine's switch
/// is exhaustive over it, and the rules accept exactly these values.
enum RecurrenceKind {
  once('once'),
  daily('daily'),
  everyNDays('every_n_days'),
  weekdays('weekdays'),
  everyNWeeks('every_n_weeks'),
  daysOfMonth('days_of_month'),
  nthWeekday('nth_weekday'),
  lastDay('last_day');

  const RecurrenceKind(this.id);

  /// The stored string.
  final String id;

  /// `null` for an unknown id (a document written by a newer app version).
  static RecurrenceKind? fromId(String id) {
    for (final kind in values) {
      if (kind.id == id) return kind;
    }
    return null;
  }
}

/// What a month without the chosen day does (`days_of_month` only).
enum MonthEndMode {
  /// Day 31 fires on the last day of a 30-day month (the default).
  clamp('clamp'),

  /// The month is skipped entirely.
  skip('skip');

  const MonthEndMode(this.id);

  final String id;

  static MonthEndMode fromId(Object? id) =>
      id == skip.id ? MonthEndMode.skip : MonthEndMode.clamp;
}

/// Limits shared by the shapes, the validator and the rules (road map 3.2).
abstract final class RecurrenceLimits {
  static const int minN = 2;
  static const int maxN = 60;
  static const int maxWeekdays = 7;
  static const int maxDaysOfMonth = 31;

  /// `nextAfter` never searches further than this (road map P3-05).
  static const int searchLimitDays = 400;
}

/// A calendar-based repeat rule, in household LOCAL dates (never UTC).
///
/// Every subtype is a value object: `==`, `hashCode` and a `copyWith`-free
/// immutable shape. Instances may hold out-of-range values (a day 32, an empty
/// weekday set): [RecurrenceValidator] is what rejects them, so a document read
/// from Firestore never throws in a constructor.
sealed class Recurrence {
  const Recurrence();

  RecurrenceKind get kind;

  /// The stored map (`toMap` in the mapper). Optional keys are omitted when
  /// they are absent, so two devices write identical documents.
  Map<String, Object?> toMap();

  /// Reads the stored shape. Returns a [Validation] with code
  /// `invalid_recurrence` when the map is not an object or `kind` is unknown.
  static Result<Recurrence> fromMap(Object? raw) {
    if (raw is! Map) {
      return const Failure<Recurrence>(
        Validation('recurrence', 'invalid_recurrence'),
      );
    }
    final map = raw.cast<Object?, Object?>();
    final kind = RecurrenceKind.fromId('${map['kind']}');
    if (kind == null) {
      return const Failure<Recurrence>(
        Validation('recurrence', 'invalid_recurrence'),
      );
    }
    final date = _date(map['date']);
    final anchor = _date(map['anchor']);
    final weekdays = _ints(map['weekdays']);
    final days = _ints(map['days']);
    // Missing numbers read as 0 and missing lists as empty: the shape is
    // accepted and the VALIDATOR reports the real problem with a stable code,
    // instead of the reader guessing a default that hides it.
    final n = _int(map['n']);
    final weekStart = _int(map['weekStart']);
    final nth = _int(map['nth']);
    final weekday = _int(map['weekday']);
    return switch (kind) {
      RecurrenceKind.once =>
        date == null
            ? const Failure<Recurrence>(
                Validation('recurrence', 'invalid_date'),
              )
            : Success<Recurrence>(OnceRecurrence(date)),
      RecurrenceKind.daily => const Success<Recurrence>(DailyRecurrence()),
      RecurrenceKind.everyNDays =>
        anchor == null
            ? const Failure<Recurrence>(
                Validation('recurrence', 'invalid_date'),
              )
            : Success<Recurrence>(EveryNDaysRecurrence(n: n, anchor: anchor)),
      RecurrenceKind.weekdays => Success<Recurrence>(
        WeekdaysRecurrence(weekdays: weekdays),
      ),
      RecurrenceKind.everyNWeeks =>
        anchor == null
            ? const Failure<Recurrence>(
                Validation('recurrence', 'invalid_date'),
              )
            : Success<Recurrence>(
                EveryNWeeksRecurrence(
                  n: n,
                  anchor: anchor,
                  weekdays: weekdays,
                  weekStart: weekStart,
                ),
              ),
      RecurrenceKind.daysOfMonth => Success<Recurrence>(
        DaysOfMonthRecurrence(
          days: days,
          monthEnd: MonthEndMode.fromId(map['monthEnd']),
        ),
      ),
      RecurrenceKind.nthWeekday => Success<Recurrence>(
        NthWeekdayRecurrence(nth: nth, weekday: weekday),
      ),
      RecurrenceKind.lastDay => const Success<Recurrence>(LastDayRecurrence()),
    };
  }

  static int _int(Object? v) => v is int ? v : 0;

  static List<int> _ints(Object? v) =>
      v is List ? v.whereType<int>().toList(growable: false) : const <int>[];

  static DateKey? _date(Object? v) {
    if (v is! String) return null;
    return DateKey.parse(v).valueOrNull;
  }
}
