import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/core/utils/date_ranges.dart';
import 'package:family_hub/core/utils/money.dart';
import 'package:family_hub/features/bazar/budgets/domain/budget.dart';
import 'package:family_hub/features/bazar/expenses/domain/expense.dart';
import 'package:family_hub/features/bazar/expenses/domain/expense_filters.dart';
import 'package:family_hub/features/bazar/items_categories/domain/text_normalizer.dart';
import 'package:family_hub/features/bazar/reports/domain/period_comparison.dart';
import 'package:family_hub/features/bazar/reports/domain/report_data.dart';
import 'package:family_hub/features/bazar/reports/domain/report_query.dart';

/// Builds every report view from ONE pass over the expenses (rule 30: reports,
/// budgets and the dashboard share one aggregation, and soft-deleted rows are
/// excluded everywhere).
///
/// Pure and integer-only: no `double`, no clock, no Firebase.  The filters are
/// the same ones the expense list uses (`applyFilters`), so a report and a
/// filtered list can never disagree about which rows belong to the period.
abstract final class ReportEngine {
  /// Key prefixes for unplanned dry-grocery spend (see `_unplannedSpend`).
  static const String _itemKeyPrefix = 'item:';
  static const String _nameKeyPrefix = 'name:';

  static ReportData build({
    required Iterable<Expense> expenses,
    required ReportQuery query,
    Budget? budget,
  }) {
    final range = query.resolvedRange;
    final rows = applyFilters(
      expenses,
      ExpenseFilters(
        range: range,
        categoryId: query.categoryId,
        itemId: query.itemId,
        memberId: query.memberId,
        funding: query.funding,
      ),
    );

    final total = Money.sum(rows.map((e) => e.total));
    return ReportData(
      query: query,
      summary: ReportSummary(total: total, count: rows.length, range: range),
      categories: _categories(rows, total),
      items: _items(rows),
      days: _days(rows, range),
      members: _members(rows),
      dryGrocery: _dryGrocery(rows, budget),
    );
  }

  /// This period against the comparable previous one (`previousComparable`:
  /// the previous full month, year or same-length range).
  ///
  /// [previousExpenses] must cover the previous range; rows outside it are
  /// ignored by the filters, so passing a whole month's rows is safe.
  static PeriodComparison compare({
    required ReportData current,
    required Iterable<Expense> previousExpenses,
    Budget? previousBudget,
  }) {
    final previousRange = previousComparable(current.summary.range);
    final previous = build(
      expenses: previousExpenses,
      query: current.query.withRange(previousRange),
      budget: previousBudget,
    );
    return PeriodComparison.of(
      current: current.summary.total,
      previous: previous.summary.total,
    );
  }

  /// [current] with its `comparison` attached, for a screen that loads both
  /// periods in one go.  The current figures are untouched.
  static ReportData withComparison(
    ReportData current, {
    required Iterable<Expense> previousExpenses,
    Budget? previousBudget,
  }) => ReportData(
    query: current.query,
    summary: current.summary,
    categories: current.categories,
    items: current.items,
    days: current.days,
    members: current.members,
    dryGrocery: current.dryGrocery,
    comparison: compare(
      current: current,
      previousExpenses: previousExpenses,
      previousBudget: previousBudget,
    ),
  );

  static List<CategoryTotal> _categories(
    List<Expense> rows,
    Money total,
  ) {
    final sums = <String, Money>{};
    final counts = <String, int>{};
    for (final expense in rows) {
      sums[expense.categoryId] =
          (sums[expense.categoryId] ?? Money.zero) + expense.total;
      counts[expense.categoryId] = (counts[expense.categoryId] ?? 0) + 1;
    }
    final result = <CategoryTotal>[
      for (final entry in sums.entries)
        CategoryTotal(
          categoryId: entry.key,
          total: entry.value,
          count: counts[entry.key]!,
          shareBp: total.isZero
              ? null
              : halfUpRatioBp(delta: entry.value, base: total),
        ),
    ]..sort(_largestFirst<CategoryTotal>((c) => c.total, (c) => c.categoryId));
    return result;
  }

  static List<ItemTotal> _items(List<Expense> rows) {
    final byKey = <String, _ItemAccumulator>{};
    for (final expense in rows) {
      final itemId = expense.itemId;
      final key = itemId ?? normalizeSearch(expense.itemName);
      if (key.isEmpty) continue;
      (byKey[key] ??= _ItemAccumulator(expense.itemName, itemId)).add(expense);
    }
    return <ItemTotal>[
      for (final entry in byKey.entries) entry.value.toTotal(entry.key),
    ]..sort(_largestFirst<ItemTotal>((i) => i.total, (i) => i.key));
  }

  static List<DayTotal> _days(List<Expense> rows, DateKeyRange range) {
    final sums = <DateKey, Money>{};
    for (final expense in rows) {
      sums[expense.dateKey] =
          (sums[expense.dateKey] ?? Money.zero) + expense.total;
    }
    return <DayTotal>[
      for (final day in daysIn(range))
        DayTotal(day: day, total: sums[day] ?? Money.zero),
    ];
  }

  static List<MemberTotal> _members(List<Expense> rows) {
    final sums = <String, Money>{};
    for (final expense in rows) {
      sums[expense.spenderId] =
          (sums[expense.spenderId] ?? Money.zero) + expense.total;
    }
    return <MemberTotal>[
      for (final entry in sums.entries)
        MemberTotal(memberId: entry.key, total: entry.value),
    ]..sort(
        _largestFirst<MemberTotal>((m) => m.total, (m) => m.memberId),
      );
  }

  /// The budget's dry-grocery lines against the actual spend.
  ///
  /// A line is matched by `itemId` when it has one, otherwise by its
  /// normalized name (so a typed "চাল " still matches a planned "চাল").  A
  /// spent row is claimed by AT MOST one line: the first line whose item id
  /// matches, else the first line with the same name.  Spending the plan never
  /// named is listed with a zero estimate, so [DryGroceryComparison.actual] is
  /// exactly the plan's real spend and nothing is counted twice.
  static DryGroceryComparison _dryGrocery(
    List<Expense> rows,
    Budget? budget,
  ) {
    if (budget == null || budget.lines.isEmpty) {
      return DryGroceryComparison.empty;
    }
    final spent = <Money>[for (final _ in budget.lines) Money.zero];

    for (final expense in rows) {
      final name = normalizeSearch(expense.itemName);
      var index = expense.itemId == null
          ? -1
          : budget.lines.indexWhere((l) => l.itemId == expense.itemId);
      if (index < 0) {
        index = budget.lines.indexWhere(
          (l) => normalizeSearch(l.name) == name,
        );
      }
      if (index < 0) continue; // unplanned: handled below
      spent[index] += expense.total;
    }

    final lines = <LineComparison>[];
    var estimate = Money.zero;
    var actual = Money.zero;
    for (var i = 0; i < budget.lines.length; i++) {
      final line = budget.lines[i];
      estimate += line.estimate;
      actual += spent[i];
      lines.add(
        LineComparison(
          key: line.itemId ?? normalizeSearch(line.name),
          name: line.name,
          itemId: line.itemId,
          estimate: line.estimate,
          actual: spent[i],
        ),
      );
    }

    final unplanned = _unplannedSpend(rows, budget);
    for (final entry in unplanned.entries) {
      actual += entry.value;
      lines.add(
        LineComparison(
          key: entry.key,
          name: entry.key,
          itemId: entry.key.startsWith(_itemKeyPrefix)
              ? entry.key.substring(_itemKeyPrefix.length)
              : null,
          estimate: Money.zero,
          actual: entry.value,
        ),
      );
    }

    return DryGroceryComparison(
      estimate: estimate,
      actual: actual,
      lines: lines,
    );
  }

  /// Spending on items no budget line names, keyed `item:<id>` or
  /// `name:<normalized>` so the list order is stable.
  /// Item spend is keyed `item:<id>`, free-text spend `name:<normalized>`.
  static Map<String, Money> _unplannedSpend(
    List<Expense> rows,
    Budget budget,
  ) {
    final plannedIds = <String>{
      for (final line in budget.lines)
        if (line.itemId != null) line.itemId!,
    };
    final plannedNames = <String>{
      for (final line in budget.lines) normalizeSearch(line.name),
    };
    final result = <String, Money>{};
    for (final expense in rows) {
      final itemId = expense.itemId;
      final name = normalizeSearch(expense.itemName);
      if (itemId != null) {
        if (plannedIds.contains(itemId) || plannedNames.contains(name)) {
          continue;
        }
        final key = '$_itemKeyPrefix$itemId';
        result[key] = (result[key] ?? Money.zero) + expense.total;
      } else {
        if (plannedNames.contains(name)) continue;
        final key = '$_nameKeyPrefix$name';
        result[key] = (result[key] ?? Money.zero) + expense.total;
      }
    }
    return result;
  }

  /// Largest total first; ties by the given key so the order is stable.
  static int Function(T, T) _largestFirst<T>(
    Money Function(T) total,
    String Function(T) key,
  ) => (a, b) {
    final byTotal = total(b).paisa.compareTo(total(a).paisa);
    return byTotal != 0 ? byTotal : key(a).compareTo(key(b));
  };
}

final class _ItemAccumulator {
  _ItemAccumulator(this.name, this.itemId);

  final String name;
  final String? itemId;
  Money total = Money.zero;
  int count = 0;

  void add(Expense expense) {
    total += expense.total;
    count++;
  }

  ItemTotal toTotal(String key) =>
      ItemTotal(key: key, name: name, total: total, count: count, itemId: itemId);
}
