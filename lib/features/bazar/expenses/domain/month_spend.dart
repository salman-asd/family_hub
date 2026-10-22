import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/core/utils/money.dart';
import 'package:family_hub/features/bazar/expenses/domain/expense.dart';

/// One month's spend, built once and reused by budgets, reports and the
/// dashboard.  Soft-deleted expenses are ignored everywhere.
final class MonthSpend {
  MonthSpend({
    required this.total,
    required Map<String, Money> byCategory,
    required Map<DateKey, Money> byDay,
    required this.count,
  }) : byCategory = Map<String, Money>.unmodifiable(byCategory),
       byDay = Map<DateKey, Money>.unmodifiable(byDay);

  factory MonthSpend.of(Iterable<Expense> expenses) {
    var total = Money.zero;
    var count = 0;
    final byCategory = <String, Money>{};
    final byDay = <DateKey, Money>{};

    for (final expense in expenses) {
      if (expense.isDeleted) continue;
      total += expense.total;
      count++;
      byCategory[expense.categoryId] =
          (byCategory[expense.categoryId] ?? Money.zero) + expense.total;
      byDay[expense.dateKey] =
          (byDay[expense.dateKey] ?? Money.zero) + expense.total;
    }

    return MonthSpend(
      total: total,
      byCategory: byCategory,
      byDay: byDay,
      count: count,
    );
  }

  final Money total;
  final Map<String, Money> byCategory;
  final Map<DateKey, Money> byDay;
  final int count;

  @override
  bool operator ==(Object other) =>
      other is MonthSpend &&
      other.total == total &&
      other.count == count &&
      _sameMoneyMap(other.byCategory, byCategory) &&
      _sameMoneyMap(other.byDay, byDay);

  @override
  int get hashCode => Object.hash(
    total,
    count,
    Object.hashAll(byCategory.entries.map((e) => Object.hash(e.key, e.value))),
    Object.hashAll(byDay.entries.map((e) => Object.hash(e.key, e.value))),
  );

  @override
  String toString() =>
      'MonthSpend(total: $total, count: $count, '
      'categories: ${byCategory.length}, days: ${byDay.length})';
}

bool _sameMoneyMap<K>(Map<K, Money> a, Map<K, Money> b) {
  if (a.length != b.length) return false;
  for (final entry in a.entries) {
    if (b[entry.key] != entry.value) return false;
  }
  return true;
}
