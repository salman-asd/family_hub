import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/core/utils/date_ranges.dart';
import 'package:family_hub/core/utils/money.dart';
import 'package:family_hub/features/bazar/reports/domain/period_comparison.dart';
import 'package:family_hub/features/bazar/reports/domain/report_query.dart';

/// Headline figures of a report: the total, how many rows, the daily average
/// and the days the range covers.
///
/// [averagePerDay] is integer arithmetic (half-up on paisa), so nothing here
/// can introduce a rounding difference between platforms.
final class ReportSummary {
  ReportSummary({
    required this.total,
    required this.count,
    required this.range,
  }) : averagePerDay = averageMoney(total, lengthInDays(range));

  final Money total;
  final int count;
  final Money averagePerDay;
  final DateKeyRange range;

  @override
  bool operator ==(Object other) =>
      other is ReportSummary &&
      other.total == total &&
      other.count == count &&
      other.averagePerDay == averagePerDay &&
      other.range == range;

  @override
  int get hashCode => Object.hash(total, count, averagePerDay, range);
}

/// `total / days`, rounded half-up, in paisa.  `days <= 0` is a programmer
/// error (a range always has at least one day).
Money averageMoney(Money total, int days) {
  assert(days > 0, 'a report range always has at least one day');
  final scaled = total.paisa * 2 + days;
  return Money.paisa(scaled ~/ (days * 2));
}

/// One category's share of the total.
final class CategoryTotal {
  const CategoryTotal({
    required this.categoryId,
    required this.total,
    required this.count,
    required this.shareBp,
  });

  final String categoryId;
  final Money total;
  final int count;

  /// `total / reportTotal` in basis points (10_000 = 100 %), rounded; `null`
  /// when the report total is zero (nothing to divide by).
  final int? shareBp;

  @override
  bool operator ==(Object other) =>
      other is CategoryTotal &&
      other.categoryId == categoryId &&
      other.total == total &&
      other.count == count &&
      other.shareBp == shareBp;

  @override
  int get hashCode => Object.hash(categoryId, total, count, shareBp);
}

/// One item's total.  [key] is the item id when there is one, otherwise the
/// normalized name, so the free-text lines of one item group together.
final class ItemTotal {
  const ItemTotal({
    required this.key,
    required this.name,
    required this.total,
    required this.count,
    this.itemId,
  });

  final String key;
  final String name;
  final Money total;
  final int count;
  final String? itemId;

  @override
  bool operator ==(Object other) =>
      other is ItemTotal &&
      other.key == key &&
      other.name == name &&
      other.total == total &&
      other.count == count &&
      other.itemId == itemId;

  @override
  int get hashCode => Object.hash(key, name, total, count, itemId);
}

/// One day of the range; days without spending are present with zero.
final class DayTotal {
  const DayTotal({required this.day, required this.total});

  final DateKey day;
  final Money total;

  @override
  bool operator ==(Object other) =>
      other is DayTotal && other.day == day && other.total == total;

  @override
  int get hashCode => Object.hash(day, total);
}

/// One member's spending ("who spent" = `Expense.spenderId`).
final class MemberTotal {
  const MemberTotal({required this.memberId, required this.total});

  final String memberId;
  final Money total;

  @override
  bool operator ==(Object other) =>
      other is MemberTotal && other.memberId == memberId && other.total == total;

  @override
  int get hashCode => Object.hash(memberId, total);
}

/// One dry-grocery line: what was planned against what was spent.
final class LineComparison {
  const LineComparison({
    required this.key,
    required this.name,
    required this.estimate,
    required this.actual,
    this.itemId,
  });

  final String key;
  final String name;
  final String? itemId;
  final Money estimate;
  final Money actual;

  /// `actual - estimate`: positive means over the plan.
  Money get delta => actual - estimate;

  @override
  bool operator ==(Object other) =>
      other is LineComparison &&
      other.key == key &&
      other.name == name &&
      other.itemId == itemId &&
      other.estimate == estimate &&
      other.actual == actual;

  @override
  int get hashCode => Object.hash(key, name, itemId, estimate, actual);
}

/// The dry-grocery plan against the actual spending of the range.
final class DryGroceryComparison {
  DryGroceryComparison({
    required this.estimate,
    required this.actual,
    required List<LineComparison> lines,
  }) : lines = List<LineComparison>.unmodifiable(lines);

  static final DryGroceryComparison empty = DryGroceryComparison(
    estimate: Money.zero,
    actual: Money.zero,
    lines: const <LineComparison>[],
  );

  final Money estimate;
  final Money actual;
  final List<LineComparison> lines;

  Money get delta => actual - estimate;

  @override
  bool operator ==(Object other) =>
      other is DryGroceryComparison &&
      other.estimate == estimate &&
      other.actual == actual &&
      _sameLines(other.lines, lines);

  @override
  int get hashCode =>
      Object.hash(estimate, actual, Object.hashAll(lines));
}



/// Everything a report screen draws, computed once by `ReportEngine`.
final class ReportData {
  ReportData({
    required this.query,
    required this.summary,
    required List<CategoryTotal> categories,
    required List<ItemTotal> items,
    required List<DayTotal> days,
    required List<MemberTotal> members,
    required this.dryGrocery,
    this.comparison,
  }) : categories = List<CategoryTotal>.unmodifiable(categories),
       items = List<ItemTotal>.unmodifiable(items),
       days = List<DayTotal>.unmodifiable(days),
       members = List<MemberTotal>.unmodifiable(members);

  final ReportQuery query;
  final ReportSummary summary;

  /// Sorted by total, largest first.
  final List<CategoryTotal> categories;

  /// Sorted by total, largest first.
  final List<ItemTotal> items;

  /// Every day of the range, ascending, zero-filled.
  final List<DayTotal> days;

  /// Sorted by total, largest first.
  final List<MemberTotal> members;

  final DryGroceryComparison dryGrocery;

  /// Set by `ReportEngine.compare` (or a screen that loaded both periods).
  final PeriodComparison? comparison;

  /// The number of rows the report was built from (equals `summary.count`).
  int get count => summary.count;

  @override
  String toString() =>
      'ReportData(${query.preset.name}, total: ${summary.total}, '
      'rows: ${summary.count})';
}

bool _sameLines(List<LineComparison> a, List<LineComparison> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
