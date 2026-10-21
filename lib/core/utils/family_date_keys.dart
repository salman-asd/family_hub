import 'package:family_hub/core/utils/clock.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/core/utils/time_zones.dart';

/// "Today", date keys and month keys in the FAMILY's time zone (H12).
///
/// Every dated record stores a `dateKey` / `monthKey` computed here, never with
/// the phone's own zone (CLAUDE.md rule 2): a family in Dhaka and a member
/// travelling in London must agree which day an expense belongs to.  Pure Dart:
/// the clock and the zone are injected.
class FamilyDateKeys {
  const FamilyDateKeys({
    required Clock clock,
    this.timezone = defaultTimezone,
  }) : _clock = clock;

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
}
