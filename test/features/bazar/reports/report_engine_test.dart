import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/core/utils/date_ranges.dart';
import 'package:family_hub/core/utils/money.dart';

import 'package:family_hub/features/bazar/budgets/domain/budget.dart';
import 'package:family_hub/features/bazar/expenses/domain/expense.dart';
import 'package:family_hub/features/bazar/expenses/domain/funding.dart';
import 'package:family_hub/features/bazar/reports/domain/report_data.dart';
import 'package:family_hub/features/bazar/reports/domain/report_engine.dart';
import 'package:family_hub/features/bazar/reports/domain/report_query.dart';
import 'package:flutter_test/flutter_test.dart';

/// P2-24: every total is exact integer paisa, and the spec's report questions
/// are each a named test.
void main() {
  final at = DateTime.utc(2026, 10, 18, 9);

  Expense expense(
    String id, {
    required DateKey day,
    String itemName = 'চাল',
    String? itemId,
    String categoryId = 'cat_food',
    int paisa = 10000,
    FundingSource funding = FundingSource.fund,
    String? payer,
    String? purchaserId,
    String? createdBy,
    DateTime? deletedAt,
  }) => Expense(
    id: id,
    dateKey: day,
    monthKey: day.monthKey,
    occurredAt: at,
    itemId: itemId,
    itemName: itemName,
    categoryId: categoryId,
    total: Money.paisa(paisa),
    funding: funding,
    paidByMemberId:
        payer ?? (funding == FundingSource.member ? 'cara' : null),
    purchaserId: purchaserId,
    createdBy: createdBy ?? 'alice',
    createdAt: at,
    deletedAt: deletedAt,
    deletedBy: deletedAt == null ? null : 'alice',
  );

  ReportQuery monthQuery(MonthKey month) => ReportQuery(
    preset: RangePreset.thisMonth,
    range: monthRange(month),
  );

  final october = MonthKey(2026, 10);
  const String normalizedEggId = 'i_egg';

  group('totals', () {
    test('a fixture totals to the paisa', () {
      final data = ReportEngine.build(
        expenses: <Expense>[
          expense('a', day: DateKey(2026, 10, 1), paisa: 12345),
          expense('b', day: DateKey(2026, 10, 1), paisa: 1),
          expense('c', day: DateKey(2026, 10, 31), paisa: 99999),
        ],
        query: monthQuery(october),
      );

      expect(data.summary.total, const Money.paisa(112345));
      expect(data.summary.count, 3);
      expect(data.categories.single.total, const Money.paisa(112345));
      expect(data.categories.single.shareBp, 10000);
    });

    test('soft-deleted rows are excluded everywhere', () {
      final data = ReportEngine.build(
        expenses: <Expense>[
          expense('a', day: DateKey(2026, 10, 2)),
          expense('gone', day: DateKey(2026, 10, 2), deletedAt: at),
        ],
        query: monthQuery(october),
      );
      expect(data.summary.count, 1);
      expect(data.days.every((d) => d.total == Money.zero || d.day.day == 2), isTrue);
    });

    test('the daily average is integer, half-up', () {
      // 31 days, 100000 paisa -> 3225.8 -> 3226.
      final data = ReportEngine.build(
        expenses: <Expense>[expense('a', day: DateKey(2026, 10, 3), paisa: 100000)],
        query: monthQuery(october),
      );
      expect(data.summary.averagePerDay, const Money.paisa(3226));
    });

    test('an empty range has zero totals and no share', () {
      final data = ReportEngine.build(expenses: const <Expense>[], query: monthQuery(october));
      expect(data.summary.total, Money.zero);
      expect(data.summary.count, 0);
      expect(data.summary.averagePerDay, Money.zero);
      expect(data.categories, isEmpty);
    });
  });

  group('boundary dates', () {
    test('the first and last day of the range are inside it', () {
      final data = ReportEngine.build(
        expenses: <Expense>[
          expense('first', day: DateKey(2026, 10, 1), paisa: 100),
          expense('last', day: DateKey(2026, 10, 31), paisa: 200),
          expense('before', day: DateKey(2026, 9, 30), paisa: 400),
          expense('after', day: DateKey(2026, 11, 1), paisa: 800),
        ],
        query: monthQuery(october),
      );
      expect(data.summary.total, const Money.paisa(300));
      expect(data.summary.count, 2);
    });

    test('a range across a year boundary includes both sides', () {
      final data = ReportEngine.build(
        expenses: <Expense>[
          expense('dec', day: DateKey(2026, 12, 31)),
          expense('jan', day: DateKey(2027, 1, 1)),
        ],
        query: ReportQuery(
          preset: RangePreset.custom,
          range: DateKeyRange(DateKey(2026, 12, 30), DateKey(2027, 1, 2)),
        ),
      );
      expect(data.summary.count, 2);
      expect(data.days.first.day, DateKey(2026, 12, 30));
      expect(data.days.last.day, DateKey(2027, 1, 2));
    });

    test('every day of the range is present, zero-filled and ascending', () {
      final data = ReportEngine.build(
        expenses: <Expense>[expense('a', day: DateKey(2026, 10, 5), paisa: 500)],
        query: monthQuery(october),
      );
      expect(data.days, hasLength(31));
      expect(data.days[4].total, const Money.paisa(500));
      expect(data.days.where((d) => d.total.isZero), hasLength(30));
      for (var i = 1; i < data.days.length; i++) {
        expect(data.days[i - 1].day.isBefore(data.days[i].day), isTrue);
      }
    });
  });

  group('comparison periods', () {
    test('March compares with a shorter February', () {
      final march = ReportEngine.build(
        expenses: <Expense>[expense('mar', day: DateKey(2027, 3, 31), paisa: 31000)],
        query: monthQuery(MonthKey(2027, 3)),
      );
      final comparison = ReportEngine.compare(
        current: march,
        previousExpenses: <Expense>[
          expense('feb', day: DateKey(2027, 2, 28), paisa: 20000),
          expense('jan', day: DateKey(2027, 1, 31), paisa: 99999),
        ],
      );
      expect(comparison.previous, const Money.paisa(20000));
      expect(comparison.delta, const Money.paisa(11000));
      expect(comparison.deltaBp, 5500); // +55 %
      expect(comparison.isUp, isTrue);
    });

    test('February 2028 includes the leap day', () {
      final leap = ReportEngine.build(
        expenses: <Expense>[
          expense('a', day: DateKey(2028, 2, 29), paisa: 2900),
        ],
        query: monthQuery(MonthKey(2028, 2)),
      );
      expect(leap.summary.count, 1);
      expect(leap.days, hasLength(29));
      final comparison = ReportEngine.compare(
        current: leap,
        previousExpenses: <Expense>[
          expense('jan', day: DateKey(2028, 1, 31), paisa: 2900),
        ],
      );
      expect(comparison.previous, const Money.paisa(2900));
      expect(comparison.isFlat, isTrue);
    });

    test('no previous spending reports no percentage', () {
      final current = ReportEngine.build(
        expenses: <Expense>[expense('a', day: DateKey(2026, 10, 3))],
        query: monthQuery(october),
      );
      final comparison = ReportEngine.compare(
        current: current,
        previousExpenses: const <Expense>[],
      );
      expect(comparison.deltaBp, isNull);
      expect(comparison.delta, current.summary.total);
    });
  });

  group('spec questions', () {
    test('eggs this month', () {
      final data = ReportEngine.build(
        expenses: <Expense>[
          expense('e1', day: DateKey(2026, 10, 2), itemName: 'ডিম', itemId: normalizedEggId, paisa: 12000),
          expense('e2', day: DateKey(2026, 10, 9), itemName: 'ডিম', itemId: normalizedEggId, paisa: 13000),
          expense('r', day: DateKey(2026, 10, 3), itemName: 'চাল', paisa: 50000),
          expense('old', day: DateKey(2026, 9, 9), itemName: 'ডিম', itemId: normalizedEggId, paisa: 99000),
        ],
        query: ReportQuery(
          preset: RangePreset.thisMonth,
          range: monthRange(october),
          itemId: normalizedEggId,
        ),
      );
      // Both October egg rows, and neither the rice nor last month's eggs.
      expect(data.summary.total, const Money.paisa(25000));
      expect(data.summary.count, 2);
      expect(data.items.single.name, 'ডিম');
    });

    test('eggs typed without an item id still group by name', () {
      final data = ReportEngine.build(
        expenses: <Expense>[
          expense('e1', day: DateKey(2026, 10, 2), itemName: 'ডিম', paisa: 12000),
          expense('e2', day: DateKey(2026, 10, 9), itemName: ' ডিম ', paisa: 13000),
        ],
        query: monthQuery(october),
      );
      expect(data.items.single.total, const Money.paisa(25000));
      expect(data.items.single.count, 2);
    });

    test('fish between two dates', () {
      final data = ReportEngine.build(
        expenses: <Expense>[
          expense('f1', day: DateKey(2026, 10, 3), itemName: 'মাছ', itemId: 'i_fish', paisa: 45000),
          expense('f2', day: DateKey(2026, 10, 10), itemName: 'মাছ', itemId: 'i_fish', paisa: 30000),
          expense('f3', day: DateKey(2026, 10, 20), itemName: 'মাছ', itemId: 'i_fish', paisa: 50000),
        ],
        query: ReportQuery(
          preset: RangePreset.custom,
          range: DateKeyRange(DateKey(2026, 10, 1), DateKey(2026, 10, 15)),
          itemId: 'i_fish',
        ),
      );
      expect(data.summary.total, const Money.paisa(75000));
      expect(data.summary.count, 2);
    });

    test('categories over budget', () {
      final budget = Budget(
        month: october,
        totalEstimate: const Money.paisa(100000),
        categoryEstimates: const <String, Money>{
          'cat_food': Money.paisa(50000),
          'cat_veg': Money.paisa(30000),
        },
      );
      final data = ReportEngine.build(
        expenses: <Expense>[
          expense('a', day: DateKey(2026, 10, 2), categoryId: 'cat_food', paisa: 60000),
          expense('b', day: DateKey(2026, 10, 3), categoryId: 'cat_veg', paisa: 10000),
        ],
        query: monthQuery(october),
        budget: budget,
      );
      final over = <String>[
        for (final category in data.categories)
          if (category.total > budget.categoryEstimates[category.categoryId]!)
            category.categoryId,
      ];
      expect(over, <String>['cat_food']);
    });

    test('spend each day sums to the month total', () {
      final data = ReportEngine.build(
        expenses: <Expense>[
          expense('a', day: DateKey(2026, 10, 2), paisa: 700),
          expense('b', day: DateKey(2026, 10, 2), paisa: 300),
          expense('c', day: DateKey(2026, 10, 9), paisa: 900),
        ],
        query: monthQuery(october),
      );
      expect(Money.sum(data.days.map((d) => d.total)), data.summary.total);
      expect(data.days[1].total, const Money.paisa(1000));
    });

    test('the dry-grocery total compares the plan with reality', () {
      final budget = Budget(
        month: october,
        totalEstimate: const Money.paisa(864000),
        lines: const <BudgetLine>[
          BudgetLine(
            name: 'চাল',
            itemId: 'i_rice',
            estimatedTotal: Money.paisa(350000),
          ),
          BudgetLine(name: 'ডাল', estimatedTotal: Money.paisa(120000)),
        ],
      );
      final data = ReportEngine.build(
        expenses: <Expense>[
          expense('a', day: DateKey(2026, 10, 2), itemName: 'চাল', itemId: 'i_rice', paisa: 360000),
          expense('b', day: DateKey(2026, 10, 3), itemName: 'ডাল ', paisa: 100000),
          expense('c', day: DateKey(2026, 10, 4), itemName: 'লবণ', paisa: 5000),
        ],
        query: monthQuery(october),
        budget: budget,
      );

      expect(data.dryGrocery.estimate, const Money.paisa(470000));
      // Rice + dal + the unplanned salt line, each counted once.
      expect(data.dryGrocery.actual, const Money.paisa(465000));
      expect(data.dryGrocery.lines, hasLength(3));
      expect(data.dryGrocery.lines.first.actual, const Money.paisa(360000));
      expect(data.dryGrocery.lines.first.delta, const Money.paisa(10000));
      expect(data.dryGrocery.lines.last.estimate, Money.zero);
    });

    test('this month against last month', () {
      final current = ReportEngine.build(
        expenses: <Expense>[
          expense('oct', day: DateKey(2026, 10, 5), paisa: 120000),
        ],
        query: monthQuery(october),
      );
      final comparison = ReportEngine.compare(
        current: current,
        previousExpenses: <Expense>[
          expense('sep', day: DateKey(2026, 9, 5), paisa: 80000),
        ],
      );
      expect(comparison.current, const Money.paisa(120000));
      expect(comparison.previous, const Money.paisa(80000));
      expect(comparison.delta, const Money.paisa(40000));
      expect(comparison.deltaBp, 5000);

      final withComparison = ReportEngine.withComparison(
        current,
        previousExpenses: <Expense>[
          expense('sep', day: DateKey(2026, 9, 5), paisa: 80000),
        ],
      );
      expect(withComparison.comparison, comparison);
      expect(withComparison.summary, current.summary);
    });
  });

  group('filters', () {
    final rows = <Expense>[
      expense('a', day: DateKey(2026, 10, 2), categoryId: 'cat_food', paisa: 1000, purchaserId: 'cara'),
      expense('b', day: DateKey(2026, 10, 3), categoryId: 'cat_veg', paisa: 2000, createdBy: 'bob'),
      expense(
        'c',
        day: DateKey(2026, 10, 4),
        categoryId: 'cat_food',
        paisa: 4000,
        funding: FundingSource.member,
        payer: 'alice',
      ),
    ];

    test('a category filter narrows every view', () {
      final data = ReportEngine.build(
        expenses: rows,
        query: ReportQuery(
          preset: RangePreset.thisMonth,
          range: monthRange(october),
          categoryId: 'cat_food',
        ),
      );
      expect(data.summary.total, const Money.paisa(5000));
      expect(data.categories.single.categoryId, 'cat_food');
      expect(data.members.map((m) => m.memberId), containsAll(<String>['cara', 'alice']));
      expect(Money.sum(data.days.map((d) => d.total)), const Money.paisa(5000));
    });

    test('a member filter matches spenderId (purchaser, else payer, else creator)', () {
      final byBob = ReportEngine.build(
        expenses: rows,
        query: ReportQuery(
          preset: RangePreset.thisMonth,
          range: monthRange(october),
          memberId: 'bob',
        ),
      );
      expect(byBob.summary.total, const Money.paisa(2000));

      final byAlice = ReportEngine.build(
        expenses: rows,
        query: ReportQuery(
          preset: RangePreset.thisMonth,
          range: monthRange(october),
          memberId: 'alice',
        ),
      );
      expect(byAlice.summary.total, const Money.paisa(4000));
    });

    test('a funding filter narrows the rows too', () {
      final data = ReportEngine.build(
        expenses: rows,
        query: ReportQuery(
          preset: RangePreset.thisMonth,
          range: monthRange(october),
          funding: FundingSource.member,
        ),
      );
      expect(data.summary.total, const Money.paisa(4000));
    });
  });

  test('5,000 expenses build in under 300 ms', () {
    final rows = <Expense>[
      for (var i = 0; i < 5000; i++)
        expense(
          'e$i',
          day: DateKey(2026, 10, (i % 31) + 1),
          categoryId: 'cat_${i % 11}',
          itemName: 'item ${i % 200}',
          itemId: 'i${i % 200}',
          paisa: 1000 + i,
          purchaserId: 'm${i % 5}',
        ),
    ];
    final watch = Stopwatch()..start();
    final data = ReportEngine.build(expenses: rows, query: monthQuery(october));
    watch.stop();

    expect(data.summary.count, 5000);
    expect(watch.elapsedMilliseconds, lessThan(300));
  });

  test('the dry-grocery empty case and a missing budget are zero', () {
    final data = ReportEngine.build(
      expenses: <Expense>[expense('a', day: DateKey(2026, 10, 2))],
      query: monthQuery(october),
    );
    expect(data.dryGrocery, DryGroceryComparison.empty);
  });

  test('a weighted average keeps the paisa exact', () {
    expect(averageMoney(const Money.paisa(1), 3), const Money.paisa(0));
    expect(averageMoney(const Money.paisa(2), 3), const Money.paisa(1));
    expect(averageMoney(const Money.paisa(1000), 7), const Money.paisa(143));
  });
}
