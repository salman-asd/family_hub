import 'package:family_hub/core/utils/money.dart';
import 'package:family_hub/features/bazar/budgets/domain/budget_alert.dart';
import 'package:family_hub/features/bazar/budgets/domain/budget_status.dart';
import 'package:family_hub/features/bazar/expenses/domain/month_spend.dart';
import 'package:flutter_test/flutter_test.dart';

import '../budget_test_helpers.dart';

void main() {
  test('alerts list only warning/exceeded, worst first', () {
    final budget = sampleBudget(
      BudgetFixture.october,
      total: const Money.paisa(100000),
      categories: const {
        'cat_a': Money.paisa(10000),
        'cat_b': Money.paisa(10000),
        'cat_c': Money.paisa(10000),
        'cat_d': Money.paisa(10000),
      },
    );
    final spend = MonthSpend(
      total: const Money.paisa(85000),
      byCategory: const {
        'cat_a': Money.paisa(8000), // warning 80 %
        'cat_b': Money.paisa(15000), // exceeded 150 %
        'cat_c': Money.paisa(1000), // ok
        'cat_d': Money.paisa(10000), // exceeded 100 %
        'cat_e': Money.paisa(999999), // no limit
      },
      byDay: const {},
      count: 5,
    );
    final alerts = buildBudgetAlerts(ComputeBudgetStatus.call(budget, spend));

    expect(alerts.map((a) => a.categoryId), [null, 'cat_b', 'cat_d', 'cat_a']);
    expect(alerts.first.isTotal, isTrue);
    expect(alerts.first.status.level, BudgetLevel.warning);
  });

  test('no alerts when everything is fine or unlimited', () {
    final report = ComputeBudgetStatus.call(
      null,
      MonthSpend(
        total: const Money.paisa(5000),
        byCategory: const {'cat_a': Money.paisa(5000)},
        byDay: const {},
        count: 1,
      ),
    );
    expect(buildBudgetAlerts(report), isEmpty);
  });
}
