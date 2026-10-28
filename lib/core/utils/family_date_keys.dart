import 'package:family_hub/core/utils/clock.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/core/utils/time_zones.dart';
import 'package:timezone/timezone.dart' as tz;

/// "Today", date keys and month keys in the FAMILY's time zone (H12).
///
/// Every dated record stores a `dateKey` / `monthKey` computed here, never with
/// the phone's own zone (CLAUDE.md rule 2): a family in Dhaka and a member
/// travelling in London must agree which day an expense belongs to.  Pure Dart:
/// the clock and the zone are injected.
class FamilyDateKeys {
  const FamilyDateKeys({required this._clock, this.timezone = defaultTimezone});

  final Clock _clock;

  /// IANA zone name from `settings/general.timezone` (default Asia/Dhaka).
  final String timezone;

  /// The same clock in another zone (a family that changes its time zone).
  FamilyDateKeys withTimezone(String zone) =>
      FamilyDateKeys(clock: _clock, timezone: zone);

  /// The family's current calendar day.
  DateKey today() => dateKeyOf(_clock.nowUtc());

  /// The current month.
  MonthKey thisMonth() => monthKeyOf(_clock.nowUtc());

  /// The calendar day of a UTC [instant] in the family zone.
  DateKey dateKeyOf(DateTime instant) =>
      DateKey.fromInstant(instant, timezone: timezone);

  /// The month of a UTC [instant] in the family zone.
  MonthKey monthKeyOf(DateTime instant) =>
      MonthKey.fromInstant(instant, timezone: timezone);

  /// The first..last day of [month], for Firestore range queries.
  DateKeyRange monthRangeOf(MonthKey month) => monthRange(month);

  /// The UTC instant of [minutesOfDay] wall-clock minutes on [key] in the
  /// family zone (00:00 = 0 … 23:59 = 1439).
  ///
  /// This is the inverse of [minutesOfDayOf]: `dateKeyOf(instantOf(k, m))` is
  /// always `k`, including the last minute of a day and a leap day, and
  /// consecutive minutes never decrease (a DST gap or a repeated hour changes
  /// the wall clock, never the day).
  DateTime instantOf(DateKey key, int minutesOfDay) {
    if (minutesOfDay < 0 || minutesOfDay > _minutesPerDay - 1) {
      throw RangeError.range(
        minutesOfDay,
        0,
        _minutesPerDay - 1,
        'minutesOfDay',
      );
    }
    ensureTimeZonesInitialized();
    final start = tz.TZDateTime(
      tz.getLocation(timezone),
      key.year,
      key.month,
      key.day,
    );
    final instant = start.add(Duration(minutes: minutesOfDay));
    if (DateKey.fromInstant(instant, timezone: timezone) != key) {
      // A Duration re-resolves until 00:00, which past a spring-forward gap
      // (London 2026-03-29) uses the offset in force BEFORE the gap and pushes
      // a late due time past midnight. Anchor on the offset the DAY uses (it is
      // the same at midnight once the gap is over) and step from there, so the
      // last minute of the day is the last minute of the day.
      final location = tz.getLocation(timezone);
      final noon = tz.TZDateTime(location, key.year, key.month, key.day, 12);
      final midnight = DateTime.utc(
        key.year,
        key.month,
        key.day,
      ).subtract(noon.timeZoneOffset);
      return midnight.add(Duration(minutes: minutesOfDay));
    }
    // Past a fall-back (London 00:00-00:59 on 2026-10-25) the Duration reaches
    // the END of the repeated hour; [minutesOfDayOf] reads the start of it, so
    // shift back to that first occurrence. Every other minute, and the
    // ascending order of the day, stays unchanged.
    final repeat = minutesOfDayOf(instant) - minutesOfDay;
    return repeat == 0
        ? instant.toUtc()
        : DateTime.fromMicrosecondsSinceEpoch(
            instant.microsecondsSinceEpoch - repeat * _microsecondsPerMinute,
            isUtc: true,
          );
  }

  /// The last second of [key] in the family zone: `instantOf(key, 1439)` plus
  /// 59 seconds. `dueAt` uses it when a chore has no time of day.
  DateTime endOfDay(DateKey key) =>
      instantOf(key, _minutesPerDay - 1).add(const Duration(seconds: 59));

  /// Wall-clock minutes of [instant] in the family zone (0 … 1439).
  int minutesOfDayOf(DateTime instant) {
    ensureTimeZonesInitialized();
    final local = tz.TZDateTime.from(instant.toUtc(), tz.getLocation(timezone));
    return local.hour * 60 + local.minute;
  }

  static const int _minutesPerDay = 24 * 60;
  static const int _microsecondsPerMinute = 60 * 1000 * 1000;
}
