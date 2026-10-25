import 'package:family_hub/core/utils/money.dart';
import 'package:family_hub/core/utils/money_math.dart';
import 'package:family_hub/features/bazar/budgets/domain/budget.dart';
import 'package:family_hub/features/bazar/expenses/domain/month_spend.dart';

/// How a limit is being used.  `noLimit` (no estimate, or zero) never alerts.
enum BudgetLevel { noLimit, ok, warning, exceeded }

/// Spend against one limit (a category or the whole month).
final class CategoryBudgetStatus {
  const CategoryBudgetStatus({
    required this.limit,
    required this.spent,
    required this.remaining,
    required this.percentBp,
    required this.level,
  });

  final Money limit;
  final Money spent;

  /// `limit - spent`; negative once the limit is passed.
  final Money remaining;

  /// Share of the limit in basis points (8000 = 80 %); `null` without a limit.
  final int? percentBp;
  final BudgetLevel level;

  bool get isAlert =>
      level == BudgetLevel.warning || level == BudgetLevel.exceeded;

  @override
  bool operator ==(Object other) =>
      other is CategoryBudgetStatus &&
      other.limit == limit &&
      other.spent == spent &&
      other.remaining == remaining &&
      other.percentBp == percentBp &&
      other.level == level;

  @override
  int get hashCode => Object.hash(limit, spent, remaining, percentBp, level);

  @override
  String toString() => 'CategoryBudgetStatus($level, $spent / $limit)';
}

/// The whole month plus every category that has an estimate or any spend.
final class BudgetStatusReport {
  BudgetStatusReport({
    required this.total,
    required Map<String, CategoryBudgetStatus> byCategory,
  }) : byCategory = Map<String, CategoryBudgetStatus>.unmodifiable(byCategory);

  final CategoryBudgetStatus total;
  final Map<String, CategoryBudgetStatus> byCategory;

  @override
  bool operator ==(Object other) {
    if (other is! BudgetStatusReport || other.total != total) return false;
    if (other.byCategory.length != byCategory.length) return false;
    for (final entry in byCategory.entries) {
      if (other.byCategory[entry.key] != entry.value) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
    total,
    Object.hashAll(byCategory.entries.map((e) => Object.hash(e.key, e.value))),
  );
}

/// Turns a plan and the month's spend into levels.  Pure: no Firebase, no
/// floating point.  An alert never blocks an expense.
abstract final class ComputeBudgetStatus {
  /// [thresholds] are percent breakpoints.  Two or more: warning at the first,
  /// exceeded at the last.  One: warning at it, exceeded at 100 (or at it, when
  /// it is already 100 or more).  None: 80 and 100.
  static BudgetStatusReport call(
    Budget? budget,
    MonthSpend spend, {
    List<int>? thresholds,
  }) {
    final marks = _breakpoints(
      thresholds ?? budget?.alertThresholds ?? kDefaultBudgetThresholds,
    );
    final estimates = budget?.categoryEstimates ?? const <String, Money>{};

    final byCategory = <String, CategoryBudgetStatus>{};
    for (final entry in estimates.entries) {
      byCategory[entry.key] = statusFor(
        entry.value,
        spend.byCategory[entry.key] ?? Money.zero,
        marks.warn,
        marks.exceed,
      );
    }
    // Spend in a category nobody planned for: shown, but never an alert.
    for (final entry in spend.byCategory.entries) {
      byCategory.putIfAbsent(
        entry.key,
        () => statusFor(Money.zero, entry.value, marks.warn, marks.exceed),
      );
    }

    return BudgetStatusReport(
      total: statusFor(
        budget?.totalEstimate ?? Money.zero,
        spend.total,
        marks.warn,
        marks.exceed,
      ),
      byCategory: byCategory,
    );
  }

  /// One limit against one spend.  The level compares exact integers
  /// (`spent * 100 >= limit * percent`), so 79.99 % is still `ok`.
  static CategoryBudgetStatus statusFor(
    Money limit,
    Money spent,
    int warnAt,
    int exceedAt,
  ) {
    if (limit.paisa <= 0) {
      return CategoryBudgetStatus(
        limit: limit,
        spent: spent,
        remaining: limit - spent,
        percentBp: null,
        level: BudgetLevel.noLimit,
      );
    }
    final scaled = spent.paisa * 100;
    final level = scaled >= limit.paisa * exceedAt
        ? BudgetLevel.exceeded
        : scaled >= limit.paisa * warnAt
        ? BudgetLevel.warning
        : BudgetLevel.ok;
    return CategoryBudgetStatus(
      limit: limit,
      spent: spent,
      remaining: limit - spent,
      percentBp: basisPoints(spent, limit),
      level: level,
    );
  }

  static ({int warn, int exceed}) _breakpoints(List<int> thresholds) {
    final clean = thresholds.where((v) => v > 0).toList()..sort();
    if (clean.isEmpty) return (warn: 80, exceed: 100);
    if (clean.length == 1) {
      final only = clean.first;
      return (warn: only, exceed: only < 100 ? 100 : only);
    }
    return (warn: clean.first, exceed: clean.last);
  }
}
