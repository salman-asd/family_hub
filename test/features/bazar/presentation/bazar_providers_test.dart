import 'package:family_hub/core/permissions/permissions.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/core/utils/family_date_keys.dart';
import 'package:family_hub/core/utils/money.dart';
import 'package:family_hub/features/bazar/advances/presentation/advance_providers.dart';
import 'package:family_hub/features/bazar/expenses/domain/expense.dart';
import 'package:family_hub/features/bazar/expenses/domain/expense_filters.dart';
import 'package:family_hub/features/bazar/expenses/domain/funding.dart';
import 'package:family_hub/features/bazar/expenses/presentation/expense_providers.dart';
import 'package:family_hub/features/bazar/fund/domain/fund_transaction.dart';
import 'package:family_hub/features/bazar/fund/domain/month_closing.dart';
import 'package:family_hub/features/bazar/fund/presentation/fund_providers.dart';
import 'package:family_hub/features/bazar/presentation/bazar_providers.dart';
import 'package:family_hub/features/bazar/settings/domain/bazar_settings.dart';
import 'package:family_hub/features/bazar/settings/presentation/bazar_settings_providers.dart';
import 'package:family_hub/features/family/presentation/family_providers.dart';
import 'package:family_hub/features/family/presentation/permission_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../bazar_test_helpers.dart';
import '../settings/bazar_settings_test_helpers.dart';

/// The Bazar provider graph (P2-11): one listener per data set, everything else
/// derived, and the derived numbers agree with the pure calculators.
void main() {
  final october = MonthKey(2026, 10);
  final september = MonthKey(2026, 9);

  late BazarFixture fixture;

  setUp(() => fixture = BazarFixture());

  ProviderContainer containerFor({BazarSettings? settings}) {
    final container = ProviderContainer(
      overrides: [
        currentFamilyIdProvider.overrideWithValue(BazarFixture.familyId),
        currentUidProvider.overrideWithValue('alice'),
        familyDateKeysProvider.overrideWithValue(
          FamilyDateKeys(clock: fixture.clock),
        ),
        expenseRepositoryProvider.overrideWithValue(fixture.backend),
        fundRepositoryProvider.overrideWithValue(fixture.backend),
        advanceRepositoryProvider.overrideWithValue(fixture.backend),
        bazarSettingsRepositoryProvider.overrideWithValue(
          FakeBazarSettingsRepository(settings ?? BazarSettings.defaults),
        ),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  Expense seedExpense({
    required String id,
    required DateKey date,
    int paisa = 10000,
    String createdBy = 'alice',
    String categoryId = 'c1',
    DateTime? deletedAt,
  }) {
    final expense = Expense(
      id: id,
      dateKey: date,
      monthKey: date.monthKey,
      occurredAt: DateTime.utc(date.year, date.month, date.day, 6),
      itemName: 'চাল',
      categoryId: categoryId,
      total: Money.paisa(paisa),
      funding: FundingSource.fund,
      createdBy: createdBy,
      createdAt: DateTime.utc(2026, 10, 1, 6),
      deletedAt: deletedAt,
      deletedBy: deletedAt == null ? null : 'alice',
    );
    (fixture.backend.expenses[BazarFixture.familyId] ??=
            <String, Expense>{})[id] =
        expense;
    fixture.backend.expenseNotify();
    return expense;
  }

  List<String> idsOf(List<Expense> expenses) => <String>[
    for (final expense in expenses) expense.id,
  ];

  test(
    'selectedMonthProvider starts on the family month and moves by month',
    () {
      final container = containerFor();

      expect(container.read(selectedMonthProvider), october);

      container.read(selectedMonthProvider.notifier)
        ..previous()
        ..previous();
      expect(container.read(selectedMonthProvider), MonthKey(2026, 8));

      container.read(selectedMonthProvider.notifier).next();
      expect(container.read(selectedMonthProvider), september);

      container.read(selectedMonthProvider.notifier).set(MonthKey(2027, 1));
      expect(container.read(selectedMonthProvider), MonthKey(2027, 1));

      container.read(selectedMonthProvider.notifier).reset();
      expect(container.read(selectedMonthProvider), october);
    },
  );

  test('currentDateKeyProvider is "today" in the family time zone', () {
    final container = containerFor();

    expect(container.read(currentDateKeyProvider), DateKey(2026, 10, 18));
  });

  test('changing the selected month re-targets the expense list', () async {
    final container = containerFor();
    seedExpense(id: 'sep', date: DateKey(2026, 9, 10));
    seedExpense(id: 'oct', date: DateKey(2026, 10, 10));

    final subscription = container.listen(filteredExpensesProvider, (_, _) {});
    addTearDown(subscription.close);
    await pumpEventQueue();
    expect(idsOf(container.read(filteredExpensesProvider)), <String>['oct']);

    container.read(selectedMonthProvider.notifier).previous();
    await pumpEventQueue();
    expect(idsOf(container.read(filteredExpensesProvider)), <String>['sep']);

    container.read(selectedMonthProvider.notifier).next();
    await pumpEventQueue();
    expect(idsOf(container.read(filteredExpensesProvider)), <String>['oct']);
  });

  test('expenseFiltersProvider narrows the selected month', () async {
    final container = containerFor();
    seedExpense(id: 'rice', date: DateKey(2026, 10, 10), categoryId: 'c1');
    seedExpense(id: 'soap', date: DateKey(2026, 10, 11), categoryId: 'c2');

    final subscription = container.listen(filteredExpensesProvider, (_, _) {});
    addTearDown(subscription.close);
    await pumpEventQueue();
    expect(idsOf(container.read(filteredExpensesProvider)), hasLength(2));

    container
        .read(expenseFiltersProvider.notifier)
        .set(const ExpenseFilters(categoryId: 'c2'));
    await pumpEventQueue();
    expect(idsOf(container.read(filteredExpensesProvider)), <String>['soap']);

    container.read(expenseFiltersProvider.notifier).clear();
    await pumpEventQueue();
    expect(idsOf(container.read(filteredExpensesProvider)), hasLength(2));
  });

  test(
    'a soft-deleted expense leaves the month spend, and returns on restore',
    () async {
      final container = containerFor();
      seedExpense(id: 'live', date: DateKey(2026, 10, 3), paisa: 30000);
      seedExpense(
        id: 'gone',
        date: DateKey(2026, 10, 4),
        paisa: 20000,
        deletedAt: DateTime.utc(2026, 10, 5),
      );

      final subscription = container.listen(
        monthSpendProvider(october),
        (_, _) {},
      );
      addTearDown(subscription.close);
      await pumpEventQueue();

      final before = container.read(monthSpendProvider(october));
      expect(before.total, const Money.paisa(30000));
      expect(before.count, 1);

      final rows = fixture.backend.expenses[BazarFixture.familyId]!;
      rows['gone'] = rows['gone']!.copyWith(deletedAt: null, deletedBy: null);
      fixture.backend.expenseNotify();
      await pumpEventQueue();

      final after = container.read(monthSpendProvider(october));
      expect(after.total, const Money.paisa(50000));
      expect(after.count, 2);
    },
  );

  test('monthLockedProvider follows the closing document', () async {
    final container = containerFor();
    final subscription = container.listen(
      monthLockedProvider(september),
      (_, _) {},
    );
    addTearDown(subscription.close);
    await pumpEventQueue();
    expect(container.read(monthLockedProvider(september)), isFalse);

    fixture.backend.closings[BazarFixture.familyId] = <MonthKey, MonthClosing>{
      september: MonthClosing(monthKey: september, status: MonthStatus.closed),
    };
    fixture.backend.expenseNotify();
    await pumpEventQueue();
    expect(container.read(monthLockedProvider(september)), isTrue);
    expect(container.read(monthLockedProvider(october)), isFalse);

    // A reopened month is open again (P2-21), so the form unlocks.
    fixture.backend.closings[BazarFixture.familyId] = <MonthKey, MonthClosing>{
      september: MonthClosing(
        monthKey: september,
        status: MonthStatus.open,
        reopenCount: 1,
      ),
    };
    fixture.backend.expenseNotify();
    await pumpEventQueue();
    expect(container.read(monthLockedProvider(september)), isFalse);
  });

  test('fundBalanceProvider follows contributions and expenses', () async {
    final container = containerFor(
      settings: BazarSettings.defaults.copyWith(
        fundStartMonth: MonthKey(2026, 1),
      ),
    );
    final day = DateKey(2026, 10, 2);
    fixture.backend.fundTransactions[BazarFixture.familyId] =
        <String, FundTransaction>{
          'con_1': FundTransaction.forContribution(
            contributionId: '1',
            amount: const Money.paisa(100000),
            dateKey: day,
            createdBy: 'alice',
            createdAt: DateTime.utc(2026, 10, 2),
          ),
          'exp_x': FundTransaction.forExpense(
            expenseId: 'x',
            total: const Money.paisa(25000),
            dateKey: day,
            createdBy: 'alice',
            createdAt: DateTime.utc(2026, 10, 2),
          ),
        };
    fixture.backend.expenseNotify();

    final subscription = container.listen(fundBalanceProvider, (_, _) {});
    addTearDown(subscription.close);
    await pumpEventQueue();

    expect(container.read(fundBalanceProvider), const Money.paisa(75000));
    expect(
      container.read(fundSummaryProvider).received,
      const Money.paisa(100000),
    );
    expect(container.read(fundSummaryProvider).spent, const Money.paisa(25000));
    expect(container.read(fundWindowOverflowProvider), isFalse);

    fixture.backend.fundTransactions[BazarFixture.familyId]!['con_2'] =
        FundTransaction.forContribution(
          contributionId: '2',
          amount: const Money.paisa(5000),
          dateKey: day,
          createdBy: 'bob',
          createdAt: DateTime.utc(2026, 10, 2),
        );
    fixture.backend.expenseNotify();
    await pumpEventQueue();

    expect(container.read(fundBalanceProvider), const Money.paisa(80000));
  });

  test('fundWindowStartProvider moves after the latest closed month', () async {
    final container = containerFor(
      settings: BazarSettings.defaults.copyWith(
        fundStartMonth: MonthKey(2026, 8),
      ),
    );
    final subscription = container.listen(fundWindowStartProvider, (_, _) {});
    addTearDown(subscription.close);
    await pumpEventQueue();
    expect(container.read(fundWindowStartProvider), MonthKey(2026, 8));

    fixture.backend.closings[BazarFixture.familyId] = <MonthKey, MonthClosing>{
      september: MonthClosing(monthKey: september, status: MonthStatus.closed),
    };
    fixture.backend.expenseNotify();
    await pumpEventQueue();

    expect(container.read(fundWindowStartProvider), october);
  });

  test(
    'a non-current month listener is released when its last watcher leaves',
    () async {
      final container = containerFor();
      final subscription = container.listen(
        monthExpensesProvider(september),
        (_, _) {},
      );
      await pumpEventQueue();
      expect(fixture.backend.hasExpenseListeners, isTrue);

      subscription.close();
      await container.pump();
      await pumpEventQueue();
      expect(container.exists(monthExpensesProvider(september)), isFalse);
      expect(fixture.backend.hasExpenseListeners, isFalse);
    },
  );

  test('the current month stays warm after its last watcher leaves', () async {
    final container = containerFor();
    final subscription = container.listen(
      monthExpensesProvider(october),
      (_, _) {},
    );
    await pumpEventQueue();

    subscription.close();
    await container.pump();
    await pumpEventQueue();
    expect(container.exists(monthExpensesProvider(october)), isTrue);
    expect(fixture.backend.hasExpenseListeners, isTrue);
  });

  test('an advance summary counts only what is still owed', () {
    final container = containerFor();

    expect(container.read(advanceSummaryProvider).openCount, 0);
    expect(container.read(advanceSummaryProvider).remaining, Money.zero);
  });

  test(
    'canEditExpenseProvider asks about own rows and other people\'s rows',
    () {
      final container = ProviderContainer(
        overrides: [
          currentUidProvider.overrideWithValue('alice'),
          canProvider.overrideWith(
            (ref, query) =>
                query.permission == Permission.addOwnExpense &&
                query.ownerId == 'alice',
          ),
        ],
      );
      addTearDown(container.dispose);

      final own = seedExpense(id: 'own', date: DateKey(2026, 10, 6));
      final other = seedExpense(
        id: 'other',
        date: DateKey(2026, 10, 6),
        createdBy: 'bob',
      );

      expect(container.read(canEditExpenseProvider(own)), isTrue);
      expect(container.read(canEditExpenseProvider(other)), isFalse);
    },
  );
}
