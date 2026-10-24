import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/core/utils/money.dart';
import 'package:family_hub/features/bazar/expenses/domain/expense.dart';
import 'package:family_hub/features/bazar/expenses/domain/expense_list_items.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../bazar_test_helpers.dart';

void main() {
  late BazarFixture f;
  setUp(() => f = BazarFixture());

  Expense row(String id, int day, int paisa, {bool deleted = false}) =>
      f.putExpense(
        id: id,
        dateKey: DateKey(2026, 10, day),
        total: Money.paisa(paisa),
        deletedAt: deleted ? DateTime.utc(2026, 10, day, 7) : null,
        deletedBy: deleted ? 'alice' : null,
      );

  test('groups by day, newest first, with day totals', () {
    final items = buildExpenseListItems([
      row('a', 18, 1000),
      row('b', 18, 2000),
      row('c', 17, 500),
    ], limit: 30);

    expect(items, hasLength(5));
    final first = items[0] as DayHeaderItem;
    expect(first.date, DateKey(2026, 10, 18));
    expect(first.total, const Money.paisa(3000));
    expect((items[1] as ExpenseRowItem).expense.id, 'a');
    expect((items[3] as DayHeaderItem).total, const Money.paisa(500));
  });

  test('a deleted row is listed but never counted in the day total', () {
    final items = buildExpenseListItems([
      row('a', 18, 1000),
      row('b', 18, 2000, deleted: true),
    ], limit: 30);
    expect((items.first as DayHeaderItem).total, const Money.paisa(1000));
    expect(items.whereType<ExpenseRowItem>(), hasLength(2));
  });

  test('the limit caps rows but the day total still counts every row', () {
    final items = buildExpenseListItems([
      row('a', 18, 1000),
      row('b', 18, 2000),
    ], limit: 1);
    expect(items.whereType<ExpenseRowItem>(), hasLength(1));
    expect((items.first as DayHeaderItem).total, const Money.paisa(3000));
  });

  test('2,000 rows flatten fast', () {
    final rows = <Expense>[
      for (var i = 0; i < 2000; i++) row('e$i', 1 + i % 28, 100 + i),
    ]..sort((a, b) => b.dateKey.compareTo(a.dateKey));
    final watch = Stopwatch()..start();
    final items = buildExpenseListItems(rows, limit: 2000);
    watch.stop();
    expect(items.whereType<ExpenseRowItem>(), hasLength(2000));
    expect(watch.elapsedMilliseconds, lessThan(200));
  });
}
