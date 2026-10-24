import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/core/utils/money.dart';

/// The family's Bazar-wide preferences (`settings/bazar`).
///
/// `weekStartDay` uses `DateTime`'s ISO numbering (1 = Monday, 7 = Sunday) and
/// defaults to Saturday for the Bangladeshi week.  Money is integer paisa.
final class BazarSettings {
  const BazarSettings({
    this.weekStartDay = 6,
    this.defaultMonthlyContribution = Money.zero,
    this.contributionDueDay = 5,
    this.alertThresholds = const <int>[80, 100],
    this.fundStartMonth,
  });

  /// What every family gets before the document exists.
  static const BazarSettings defaults = BazarSettings();

  final int weekStartDay;
  final Money defaultMonthlyContribution;
  final int contributionDueDay;

  /// Percentage breakpoints for budget warnings, ascending and unique.
  final List<int> alertThresholds;

  /// First month in the fund window; `null` until an opening balance is set.
  final MonthKey? fundStartMonth;

  BazarSettings copyWith({
    int? weekStartDay,
    Money? defaultMonthlyContribution,
    int? contributionDueDay,
    List<int>? alertThresholds,
    MonthKey? fundStartMonth,
    bool clearFundStartMonth = false,
  }) => BazarSettings(
    weekStartDay: weekStartDay ?? this.weekStartDay,
    defaultMonthlyContribution:
        defaultMonthlyContribution ?? this.defaultMonthlyContribution,
    contributionDueDay: contributionDueDay ?? this.contributionDueDay,
    alertThresholds: alertThresholds ?? this.alertThresholds,
    fundStartMonth: clearFundStartMonth
        ? null
        : (fundStartMonth ?? this.fundStartMonth),
  );

  @override
  bool operator ==(Object other) =>
      other is BazarSettings &&
      other.weekStartDay == weekStartDay &&
      other.defaultMonthlyContribution == defaultMonthlyContribution &&
      other.contributionDueDay == contributionDueDay &&
      _sameInts(other.alertThresholds, alertThresholds) &&
      other.fundStartMonth == fundStartMonth;

  @override
  int get hashCode => Object.hash(
    weekStartDay,
    defaultMonthlyContribution,
    contributionDueDay,
    Object.hashAll(alertThresholds),
    fundStartMonth,
  );

  static bool _sameInts(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  String toString() =>
      'BazarSettings(weekStartDay: $weekStartDay, '
      'defaultMonthlyContribution: $defaultMonthlyContribution, '
      'contributionDueDay: $contributionDueDay, '
      'alertThresholds: $alertThresholds, fundStartMonth: $fundStartMonth)';
}
