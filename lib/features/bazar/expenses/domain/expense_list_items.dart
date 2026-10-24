import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/core/utils/money.dart';
import 'package:family_hub/features/bazar/expenses/domain/expense.dart';

/// One line of the flattened expense list: a day header or an expense row.
sealed class ExpenseListItem {
  const ExpenseListItem();
}

/// "Wed, 14 October 2026" and what was spent that day (deleted rows excluded).
final class DayHeaderItem extends ExpenseListItem {
  const DayHeaderItem({required this.date, required this.total});

  final DateKey date;
  final Money total;
}

final class ExpenseRowItem extends ExpenseListItem {
  const ExpenseRowItem(this.expense);

  final Expense expense;
}

/// Flattens [rows] (newest day first, as the repository returns them) into
/// headers and rows, keeping at most [limit] rows.
///
/// A flat list lets `ListView.builder` build only what is on screen, so 2,000
/// rows stay smooth.  Days are grouped in input order; a day's total counts
/// every row of that day, not only the visible ones.
List<ExpenseListItem> buildExpenseListItems(
  List<Expense> rows, {
  required int limit,
}) {
  final totals = <DateKey, Money>{};
  for (final row in rows) {
    if (row.isDeleted) continue;
    totals[row.dateKey] = (totals[row.dateKey] ?? Money.zero) + row.total;
  }

  final items = <ExpenseListItem>[];
  DateKey? current;
  var shown = 0;
  for (final row in rows) {
    if (shown >= limit) break;
    if (current != row.dateKey) {
      current = row.dateKey;
      items.add(
        DayHeaderItem(date: row.dateKey, total: totals[row.dateKey] ?? Money.zero),
      );
    }
    items.add(ExpenseRowItem(row));
    shown++;
  }
  return items;
}
