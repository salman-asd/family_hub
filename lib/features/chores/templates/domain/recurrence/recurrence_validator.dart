import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/features/chores/templates/domain/recurrence/recurrence.dart';

/// The outcome of checking a recurrence before it is saved.
///
/// [errors] block a save (a [Validation] with the stable codes of road map 3.6);
/// [warnings] are shown but allowed, because they describe a pattern the user
/// may well want ("day 31 is skipped in short months").
final class RecurrenceCheck {
  const RecurrenceCheck({this.errors = const [], this.warnings = const []});

  final List<Validation> errors;
  final List<Validation> warnings;

  bool get isValid => errors.isEmpty;

  @override
  String toString() => 'RecurrenceCheck(errors: $errors, warnings: $warnings)';
}

/// Checks the closed shapes of road map 3.2 (P3-05).
///
/// Codes, exactly as the roadmap fixes them:
/// `invalid_recurrence`, `no_dates`, `invalid_range`, `invalid_date`.
abstract final class RecurrenceValidator {
  /// Checks [r] against its template span.
  ///
  /// [startDate] is the template's own start (required in practice; null means
  /// "no lower bound"). Nothing here throws for a malformed value: a document
  /// read from Firestore may hold anything.
  static RecurrenceCheck validate(
    Recurrence r, {
    DateKey? startDate,
    DateKey? endDate,
  }) {
    final errors = <Validation>[];
    final warnings = <Validation>[];
    void error(String code) => errors.add(Validation('recurrence', code));

    if (startDate != null && endDate != null && endDate.isBefore(startDate)) {
      errors.add(const Validation('recurrence', 'invalid_range'));
    }

    switch (r) {
      case OnceRecurrence(:final date):
        if (startDate != null && date.isBefore(startDate)) {
          error('no_dates');
        }
        if (endDate != null && date.isAfter(endDate)) {
          error('no_dates');
        }

      case DailyRecurrence():
        break;

      case EveryNDaysRecurrence(:final n, :final anchor):
        if (n < RecurrenceLimits.minN || n > RecurrenceLimits.maxN) {
          error('invalid_recurrence');
        }
        // The anchor must lie inside the template span, or the pattern is
        // measured from a day the chore never runs.
        if (startDate != null && anchor.isBefore(startDate)) {
          warnings.add(const Validation('recurrence', 'invalid_date'));
        }
        if (endDate != null && anchor.isAfter(endDate)) {
          warnings.add(const Validation('recurrence', 'invalid_date'));
        }

      case WeekdaysRecurrence(:final weekdays):
        if (weekdays.isEmpty) error('no_dates');
        if (weekdays.any(_notAWeekday)) error('invalid_recurrence');

      case EveryNWeeksRecurrence(:final n, :final weekdays, :final weekStart):
        if (n < RecurrenceLimits.minN || n > RecurrenceLimits.maxN) {
          error('invalid_recurrence');
        }
        if (weekdays.isEmpty) error('no_dates');
        if (weekdays.any(_notAWeekday)) error('invalid_recurrence');
        if (_notAWeekday(weekStart)) error('invalid_recurrence');

      case DaysOfMonthRecurrence(:final days):
        if (days.isEmpty) {
          error('no_dates');
        } else if (days.any(
          (d) => d < 1 || d > RecurrenceLimits.maxDaysOfMonth,
        )) {
          error('invalid_recurrence');
        } else if (r.monthEnd == MonthEndMode.skip && days.any((d) => d > 28)) {
          // Not an error: the user asked to skip, so the day simply does not
          // fire in shorter months. Worth saying out loud.
          warnings.add(const Validation('recurrence', 'invalid_recurrence'));
        }

      case NthWeekdayRecurrence(:final nth, :final weekday):
        if (!(nth == -1 || (nth >= 1 && nth <= 4))) error('invalid_recurrence');
        if (_notAWeekday(weekday)) error('invalid_recurrence');

      case LastDayRecurrence():
        break;
    }

    return RecurrenceCheck(errors: errors, warnings: warnings);
  }

  static bool _notAWeekday(int value) =>
      value < DateTime.monday || value > DateTime.sunday;
}
