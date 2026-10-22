import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/features/bazar/expenses/domain/expense.dart';
import 'package:family_hub/features/bazar/expenses/domain/funding.dart';
import 'package:family_hub/features/bazar/items_categories/domain/text_normalizer.dart';

/// Client-side filters for the expense list.  The month/range query is done by
/// the repository; these narrow the already-loaded rows without another read.
final class ExpenseFilters {
  const ExpenseFilters({
    this.range,
    this.categoryId,
    this.itemId,
    this.memberId,
    this.funding,
    this.includeDeleted = false,
    this.text,
  });

  final DateKeyRange? range;
  final String? categoryId;
  final String? itemId;

  /// Matches [Expense.spenderId] (`purchaserId`, else payer, else creator).
  final String? memberId;
  final FundingSource? funding;
  final bool includeDeleted;
  final String? text;

  List<Expense> apply(Iterable<Expense> expenses) =>
      applyFilters(expenses, this);

  Map<DateKey, List<Expense>> groupByDay(Iterable<Expense> expenses) =>
      groupExpensesByDay(expenses);
}

/// Applies every non-null filter, preserving the input order.
List<Expense> applyFilters(Iterable<Expense> expenses, ExpenseFilters filters) {
  final query = normalizeSearch(filters.text ?? '');
  final result = <Expense>[];
  for (final expense in expenses) {
    if (!filters.includeDeleted && expense.isDeleted) continue;
    if (filters.range != null && !filters.range!.contains(expense.dateKey)) {
      continue;
    }
    if (filters.categoryId != null &&
        expense.categoryId != filters.categoryId) {
      continue;
    }
    if (filters.itemId != null && expense.itemId != filters.itemId) continue;
    if (filters.memberId != null && expense.spenderId != filters.memberId) {
      continue;
    }
    if (filters.funding != null && expense.funding != filters.funding) {
      continue;
    }
    if (query.isNotEmpty && !_matchesText(expense, query)) continue;
    result.add(expense);
  }
  return result;
}

bool _matchesText(Expense expense, String query) {
  if (normalizeSearch(expense.itemName).contains(query)) return true;
  if (normalizeSearch(expense.shop ?? '').contains(query)) return true;
  return normalizeSearch(expense.note ?? '').contains(query);
}

/// Alias for [groupExpensesByDay] matching the P2-09 card's helper name.
Map<DateKey, List<Expense>> groupByDay(Iterable<Expense> expenses) =>
    groupExpensesByDay(expenses);

/// Groups by calendar day in the input order, preserving each day's order.
Map<DateKey, List<Expense>> groupExpensesByDay(Iterable<Expense> expenses) {
  final groups = <DateKey, List<Expense>>{};
  for (final expense in expenses) {
    (groups[expense.dateKey] ??= <Expense>[]).add(expense);
  }
  return groups;
}
