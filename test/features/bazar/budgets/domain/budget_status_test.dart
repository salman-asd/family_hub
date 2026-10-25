import 'package:family_hub/core/utils/money.dart';
import 'package:family_hub/core/utils/quantity.dart';
import 'package:family_hub/features/bazar/budgets/domain/budget.dart';
import 'package:family_hub/features/bazar/budgets/domain/budget_status.dart';
import 'package:family_hub/features/bazar/expenses/domain/month_spend.dart';
import 'package:flutter_test/flutter_test.dart';

import '../budget_test_helpers.dart';

MonthSpend _spend(Map<String, int> byCategory) => MonthSpend(
  total: Money.paisa(byCategory.values.fold(0, (a, b) => a + b)),
  byCategory: {
    for (final e in byCategory.entries) e.key: Money.paisa(e.value),
  },
  byDay: const {},
  count: byCategory.length,
);

void main() {
  // A limit of 10,000 paisa makes every percent exactly 100 paisa.
  CategoryBudgetStatus at(int spentPaisa, {List<int>? thresholds}) {
    final budget = sampleBudget(
      BudgetFixture.october,
      total: const Money.paisa(10000),
    );
    return ComputeBudgetStatus.call(
      budget,
      _spend({'cat_a': spentPaisa}),
      thresholds: thresholds,
    ).total;
  }

  group('levels at the 80 % and 100 % boundaries (inclusive)', () {
    test('79 % is ok, 80 % warns, 99 % warns', () {
      expect(at(7900).level, BudgetLevel.ok);
      expect(at(7999).level, BudgetLevel.ok);
      expect(at(8000).level, BudgetLevel.warning);
      expect(at(9900).level, BudgetLevel.warning);
      expect(at(9999).level, BudgetLevel.warning);
    });

    test('100 % and 101 % are exceeded', () {
      expect(at(10000).level, BudgetLevel.exceeded);
      expect(at(10100).level, BudgetLevel.exceeded);
    });

    test('percent and remaining are exact', () {
      final status = at(8000);
      expect(status.percentBp, 8000);
      expect(status.remaining, const Money.paisa(2000));
      expect(status.spent, const Money.paisa(8000));
      expect(status.limit, const Money.paisa(10000));
    });

    test('remaining is negative once the limit is passed', () {
      final status = at(12500);
      expect(status.remaining, const Money.paisa(-2500));
      expect(status.percentBp, 12500);
      expect(status.level, BudgetLevel.exceeded);
    });
  });

  group('thresholds', () {
    test('three thresholds use the first and the last', () {
      expect(at(7000, thresholds: [70, 90, 100]).level, BudgetLevel.warning);
      expect(at(6900, thresholds: [70, 90, 100]).level, BudgetLevel.ok);
      expect(at(10000, thresholds: [70, 90, 100]).level, BudgetLevel.exceeded);
      expect(at(9000, thresholds: [70, 90, 100]).level, BudgetLevel.warning);
    });

    test('one threshold warns at it and is exceeded at 100', () {
      expect(at(8999, thresholds: [90]).level, BudgetLevel.ok);
      expect(at(9000, thresholds: [90]).level, BudgetLevel.warning);
      expect(at(9999, thresholds: [90]).level, BudgetLevel.warning);
      expect(at(10000, thresholds: [90]).level, BudgetLevel.exceeded);
    });

    test('a single threshold of 100 or more is exceeded at it', () {
      expect(at(9999, thresholds: [100]).level, BudgetLevel.ok);
      expect(at(10000, thresholds: [100]).level, BudgetLevel.exceeded);
      expect(at(14999, thresholds: [150]).level, BudgetLevel.ok);
      expect(at(15000, thresholds: [150]).level, BudgetLevel.exceeded);
    });

    test('an empty list falls back to 80 and 100', () {
      expect(at(8000, thresholds: <int>[]).level, BudgetLevel.warning);
      expect(at(10000, thresholds: <int>[]).level, BudgetLevel.exceeded);
    });

    test('thresholds default to the budget\'s own', () {
      final budget = sampleBudget(
        BudgetFixture.october,
        total: const Money.paisa(10000),
        thresholds: const [50, 100],
      );
      final report = ComputeBudgetStatus.call(budget, _spend({'cat_a': 5000}));
      expect(report.total.level, BudgetLevel.warning);
    });
  });

  group('no limit', () {
    test('a zero budget is noLimit and never alerts', () {
      final budget = sampleBudget(BudgetFixture.october, total: Money.zero);
      final report = ComputeBudgetStatus.call(
        budget,
        _spend({'cat_a': 999999}),
      );
      expect(report.total.level, BudgetLevel.noLimit);
      expect(report.total.percentBp, isNull);
      expect(report.total.isAlert, isFalse);
    });

    test('no budget at all is noLimit', () {
      final report = ComputeBudgetStatus.call(null, _spend({'cat_a': 500}));
      expect(report.total.level, BudgetLevel.noLimit);
      expect(report.byCategory['cat_a']!.level, BudgetLevel.noLimit);
    });

    test('a category without an estimate is noLimit, never an alert', () {
      final budget = sampleBudget(
        BudgetFixture.october,
        total: const Money.paisa(100000),
        categories: const {'cat_a': Money.paisa(10000)},
      );
      final report = ComputeBudgetStatus.call(
        budget,
        _spend({'cat_a': 9000, 'cat_b': 50000}),
      );
      expect(report.byCategory['cat_a']!.level, BudgetLevel.warning);
      expect(report.byCategory['cat_b']!.level, BudgetLevel.noLimit);
      expect(report.byCategory['cat_b']!.spent, const Money.paisa(50000));
    });

    test('an estimated category with no spend is ok at 0 %', () {
      final budget = sampleBudget(
        BudgetFixture.october,
        categories: const {'cat_a': Money.paisa(10000)},
      );
      final report = ComputeBudgetStatus.call(budget, _spend({}));
      final status = report.byCategory['cat_a']!;
      expect(status.level, BudgetLevel.ok);
      expect(status.percentBp, 0);
      expect(status.remaining, const Money.paisa(10000));
    });
  });

  test('the total and each category are judged separately', () {
    final budget = sampleBudget(
      BudgetFixture.october,
      total: const Money.paisa(100000),
      categories: const {'cat_a': Money.paisa(10000)},
    );
    final report = ComputeBudgetStatus.call(budget, _spend({'cat_a': 12000}));
    expect(report.total.level, BudgetLevel.ok);
    expect(report.byCategory['cat_a']!.level, BudgetLevel.exceeded);
  });

  test('is pure: the same inputs give equal reports', () {
    final budget = sampleBudget(
      BudgetFixture.october,
      categories: const {'cat_a': Money.paisa(10000)},
    );
    final spend = _spend({'cat_a': 5000});
    expect(
      ComputeBudgetStatus.call(budget, spend),
      ComputeBudgetStatus.call(budget, spend),
    );
  });

  test('rounding never turns 79.99 % into a warning', () {
    // 7999.5 / 10000 would round to 8000 bp, but the level is exact.
    final status = ComputeBudgetStatus.statusFor(
      const Money.paisa(20001),
      const Money.paisa(16000),
      80,
      100,
    );
    expect(status.level, BudgetLevel.ok);
  });

  test('BudgetLine estimate: quantity x rate, else the typed total', () {
    expect(Budget.lineEstimate(riceLine), const Money.paisa(350000));
    expect(Budget.lineEstimate(oilLine), const Money.paisa(120000));
    // A quantity without a rate cannot be multiplied: the typed total wins.
    const noRate = BudgetLine(
      name: 'No rate',
      plannedQty: Quantity.milli(2000),
      estimatedTotal: Money.paisa(1),
    );
    expect(noRate.estimate, const Money.paisa(1));
  });
}
