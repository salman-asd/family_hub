import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/core/utils/time_zones.dart';
import 'package:timezone/timezone.dart' as tz;

String _pad(int value, int width) => value.toString().padLeft(width, '0');

/// A calendar day in the family timezone, written 'yyyy-MM-dd'.
final class DateKey implements Comparable<DateKey> {
  DateKey(this.year, this.month, this.day)
      : assert(_isValid(year, month, day), 'Invalid date $year-$month-$day');

  /// The calendar day of [instant] in [timezone] (IANA name).
  /// An unknown timezone name is a programmer error and throws.
  factory DateKey.fromInstant(
    DateTime instant, {
    String timezone = defaultTimezone,
  }) {
    ensureTimeZonesInitialized();
    final local = tz.TZDateTime.from(instant.toUtc(), tz.getLocation(timezone));
    return DateKey(local.year, local.month, local.day);
  }

  static final RegExp _pattern = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');

  /// Parses 'yyyy-MM-dd'. Failure code `invalid_date` otherwise.
  static Result<DateKey> parse(String input) {
    final match = _pattern.firstMatch(input);
    if (match == null) {
      return const Failure<DateKey>(Validation('dateKey', 'invalid_date'));
    }
    final year = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    final day = int.parse(match.group(3)!);
    if (!_isValid(year, month, day)) {
      return const Failure<DateKey>(Validation('dateKey', 'invalid_date'));
    }
    return Success<DateKey>(DateKey(year, month, day));
  }

  static bool _isValid(int year, int month, int day) {
    if (year < 1 || year > 9999 || month < 1 || month > 12 || day < 1) {
      return false;
    }
    final check = DateTime.utc(year, month, day);
    return check.year == year && check.month == month && check.day == day;
  }

  final int year;
  final int month;
  final int day;

  DateTime get _utcMidnight => DateTime.utc(year, month, day);

  MonthKey get monthKey => MonthKey(year, month);

  /// 1 = Monday ... 7 = Sunday.
  int get weekday => _utcMidnight.weekday;

  DateKey addDays(int days) {
    final moved = DateTime.utc(year, month, day + days);
    return DateKey(moved.year, moved.month, moved.day);
  }

  /// Whole days from this day to [other] (negative if [other] is earlier).
  int daysUntil(DateKey other) =>
      other._utcMidnight.difference(_utcMidnight).inDays;

  bool isBefore(DateKey other) => compareTo(other) < 0;

  bool isAfter(DateKey other) => compareTo(other) > 0;

  /// 'yyyyMMdd', used inside deterministic ids such as {templateId}_{yyyyMMdd}.
  String get compact => '${_pad(year, 4)}${_pad(month, 2)}${_pad(day, 2)}';

  @override
  int compareTo(DateKey other) {
    final byYear = year.compareTo(other.year);
    if (byYear != 0) {
      return byYear;
    }
    final byMonth = month.compareTo(other.month);
    return byMonth != 0 ? byMonth : day.compareTo(other.day);
  }

  @override
  bool operator ==(Object other) =>
      other is DateKey &&
      other.year == year &&
      other.month == month &&
      other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);

  /// 'yyyy-MM-dd'. Sorts correctly as a string, which Firestore range
  /// queries rely on.
  @override
  String toString() => '${_pad(year, 4)}-${_pad(month, 2)}-${_pad(day, 2)}';
}

/// A calendar month in the family timezone, written 'yyyy-MM'.
final class MonthKey implements Comparable<MonthKey> {
  MonthKey(this.year, this.month)
      : assert(
          year >= 1 && year <= 9999 && month >= 1 && month <= 12,
          'Invalid month $year-$month',
        );

  factory MonthKey.fromInstant(
    DateTime instant, {
    String timezone = defaultTimezone,
  }) =>
      DateKey.fromInstant(instant, timezone: timezone).monthKey;

  static final RegExp _pattern = RegExp(r'^(\d{4})-(\d{2})$');

  /// Parses 'yyyy-MM'. Failure code `invalid_month` otherwise.
  static Result<MonthKey> parse(String input) {
    final match = _pattern.firstMatch(input);
    if (match == null) {
      return const Failure<MonthKey>(Validation('monthKey', 'invalid_month'));
    }
    final year = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    if (year < 1 || month < 1 || month > 12) {
      return const Failure<MonthKey>(Validation('monthKey', 'invalid_month'));
    }
    return Success<MonthKey>(MonthKey(year, month));
  }

  final int year;
  final int month;

  /// 28, 29, 30 or 31. Leap years are handled by the DateTime calendar.
  int get daysInMonth => DateTime.utc(year, month + 1, 0).day;

  DateKey get startOfMonth => DateKey(year, month, 1);

  DateKey get endOfMonth => DateKey(year, month, daysInMonth);

  MonthKey addMonths(int months) {
    final index = year * 12 + (month - 1) + months;
    return MonthKey(index ~/ 12, index % 12 + 1);
  }

  @override
  int compareTo(MonthKey other) {
    final byYear = year.compareTo(other.year);
    return byYear != 0 ? byYear : month.compareTo(other.month);
  }

  @override
  bool operator ==(Object other) =>
      other is MonthKey && other.year == year && other.month == month;

  @override
  int get hashCode => Object.hash(year, month);

  @override
  String toString() => '${_pad(year, 4)}-${_pad(month, 2)}';
}

/// Inclusive range of days, for Firestore range queries on dateKey.
final class DateKeyRange {
  const DateKeyRange(this.start, this.end);

  final DateKey start;
  final DateKey end;

  bool contains(DateKey key) =>
      key.compareTo(start) >= 0 && key.compareTo(end) <= 0;

  @override
  bool operator ==(Object other) =>
      other is DateKeyRange && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() => 'DateKeyRange($start..$end)';
}

/// First to last day of [month], inclusive.
DateKeyRange monthRange(MonthKey month) =>
    DateKeyRange(month.startOfMonth, month.endOfMonth);
