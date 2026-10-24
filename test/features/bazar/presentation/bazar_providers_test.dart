import 'package:family_hub/core/permissions/permissions.dart';
import 'package:family_hub/core/utils/clock_provider.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/core/utils/money.dart';
import 'package:family_hub/features/bazar/advances/presentation/advance_providers.dart';
import 'package:family_hub/features/bazar/expenses/domain/expense_filters.dart';
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

/// P2-11: the sync layer.  Every provider reads the in-memory backend through
/// the same ports the Firestore repositories implement.
void main() {
  late BazarFixture fx;

  setUp(() => fx = BazarFixture());

  ProviderContainer makeContainer({
    String uid = 'alice',
    Role role = Role.admin,
    BazarSettings? settings,
  }) {
    final container = ProviderContainer(
      overrides: [
        clockProvider.overrideWithValue(fx.clock),
        currentFamilyIdProvider.overrideWithValue(BazarFixture.familyId),
        currentUidProvider.overrideWithValue(uid),
        currentActorProvider.overrideWithValue(
          PermissionActor(uid: uid, role: role, isActive: true),
        ),
        permissionSettingsProvider.overrideWithValue(
          PermissionSettings.defaults,
        ),
        bazarSettingsProvider.overrideWithValue(
          settings ??
              BazarSettings.defaults.copyWith(
                fundStartMonth: MonthKey(2026, 9),
              ),
        ),
        expenseRepositoryProvider.overrideWithValue(fx.backend),
        fundRepositoryProvider.overrideWithValue(fx.backend),
        advanceRepositoryProvider.overrideWithValue(fx.backend),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  Future<void> pump() async {
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
  }

  T keep<T>(ProviderContainer c, ProviderListenable<T> p) {
    final sub = c.listen<T>(p, (_, _) {});
    addTearDown(sub.close);
    return sub.read();
  }

  group('selectedMonthProvider', () {
    test('starts at the family month and moves with next/previous/reset', () {
      final c = makeContainer();
      expect(c.read(selectedMonthProvider), MonthKey(2026, 10));
      c.read(selectedMonthProvider.notifier).previous();
      expect(c.read(selectedMonthProvider), MonthKey(2026, 9));
      c.read(selectedMonthProvider.notifier).next();
      c.read(selectedMonthProvider.notifier).next();
      expect(c.read(selectedMonthProvider), MonthKey(2026, 11));
      c.read(selectedMonthProvider.notifier).reset();
      expect(c.read(selectedMonthProvider), MonthKey(2026, 10));
      c.read(selectedMonthProvider.notifier).set(MonthKey(2027, 1));
      expect(c.read(selectedMonthProvider), MonthKey(2027, 1));
    });

    test('currentDateKeyProvider follows the injected clock', () {
      final c = makeContainer();
      expect(c.read(currentDateKeyProvider), DateKey(2026, 10, 18));
    });
  });

  group('month expenses and spend', () {
    test('switching the month re-targets the listener', () async {
      fx.putExpense(id: 'oct', total: const Money.paisa(5000));
      fx.putExpense(
        id: 'sep',
        dateKey: DateKey(2026, 9, 20),
        total: const Money.paisa(7000),
      );
      final c = makeContainer();
      keep(c, monthExpensesProvider(MonthKey(2026, 10)));
      keep(c, monthExpensesProvider(MonthKey(2026, 9)));
      await pump();

      List<String> ids(MonthKey m) => c
          .read(monthExpensesProvider(m))
          .value!
          .map((e) => e.id)
          .toList();
      expect(ids(MonthKey(2026, 10)), ['oct']);
      expect(ids(MonthKey(2026, 9)), ['sep']);
      expect(
        c.read(monthSpendProvider(MonthKey(2026, 9))).total,
        const Money.paisa(7000),
      );
    });

    test('a soft-deleted expense leaves the month spend', () async {
      fx.putExpense(id: 'a', total: const Money.paisa(5000));
      final c = makeContainer();
      final month = MonthKey(2026, 10);
      keep(c, monthSpendProvider(month));
      await pump();
      expect(c.read(monthSpendProvider(month)).total, const Money.paisa(5000));

      fx.putExpense(
        id: 'a',
        total: const Money.paisa(5000),
        deletedAt: fx.clock.nowUtc(),
        deletedBy: 'alice',
      );
      await pump();
      expect(c.read(monthSpendProvider(month)).total, Money.zero);
      expect(c.read(monthSpendProvider(month)).count, 0);
    });

    test('a non-current month is released when nobody watches it', () async {
      final c = makeContainer();
      final past = monthExpensesProvider(MonthKey(2026, 8));
      final sub = c.listen(past, (_, _) {});
      await pump();
      expect(c.exists(past), isTrue);
      sub.close();
      await pump();
      expect(c.exists(past), isFalse);
    });

    test('the current month stays alive after its last listener', () async {
      final c = makeContainer();
      final now = monthExpensesProvider(MonthKey(2026, 10));
      final sub = c.listen(now, (_, _) {});
      await pump();
      sub.close();
      await pump();
      expect(c.exists(now), isTrue);
    });

    test('filters narrow the rows, the day groups and the total', () async {
      fx.putExpense(
        id: 'fish',
        categoryId: 'cat_fish',
        total: const Money.paisa(40000),
      );
      fx.putExpense(
        id: 'veg',
        categoryId: 'cat_veg',
        total: const Money.paisa(25000),
      );
      fx.putExpense(
        id: 'gone',
        categoryId: 'cat_fish',
        total: const Money.paisa(9900),
        deletedAt: fx.clock.nowUtc(),
        deletedBy: 'alice',
      );
      final c = makeContainer();
      keep(c, filteredExpensesProvider);
      keep(c, monthExpensesProvider(MonthKey(2026, 10)));
      await pump();

      var view = c.read(filteredExpensesProvider);
      expect(view.rows.map((e) => e.id).toSet(), {'fish', 'veg'});
      expect(view.total, const Money.paisa(65000));

      c
          .read(expenseFiltersProvider.notifier)
          .set(const ExpenseFilters(categoryId: 'cat_fish'));
      view = c.read(filteredExpensesProvider);
      expect(view.rows.map((e) => e.id), ['fish']);
      expect(view.total, const Money.paisa(40000));
      expect(view.byDay.keys.single, DateKey(2026, 10, 18));

      c
          .read(expenseFiltersProvider.notifier)
          .set(const ExpenseFilters(includeDeleted: true));
      view = c.read(filteredExpensesProvider);
      expect(view.rows.length, 3);
      expect(view.total, const Money.paisa(65000)); // deleted never counts

      c.read(expenseFiltersProvider.notifier).reset();
      expect(c.read(expenseFiltersProvider).includeDeleted, isFalse);
    });
  });

  group('month lock and fund window', () {
    test('a closed month is locked, an open or reopened one is not', () async {
      final c = makeContainer();
      keep(c, monthClosingsProvider);
      await pump();
      expect(c.read(monthLockedProvider(MonthKey(2026, 9))), isFalse);

      fx.putClosing(monthKey: MonthKey(2026, 9));
      await pump();
      expect(c.read(monthLockedProvider(MonthKey(2026, 9))), isTrue);
      expect(c.read(monthLockedProvider(MonthKey(2026, 10))), isFalse);

      fx.putClosing(monthKey: MonthKey(2026, 9), status: MonthStatus.open);
      await pump();
      expect(c.read(monthLockedProvider(MonthKey(2026, 9))), isFalse);
    });

    test('the fund balance follows the ledger window', () async {
      FundTransaction row(String id, int paisa, DateKey day) =>
          paisa > 0
          ? FundTransaction.forContribution(
              contributionId: id,
              amount: Money.paisa(paisa),
              dateKey: day,
              createdBy: 'alice',
              createdAt: fx.clock.nowUtc(),
            )
          : FundTransaction.forExpense(
              expenseId: id,
              total: Money.paisa(-paisa),
              dateKey: day,
              createdBy: 'alice',
              createdAt: fx.clock.nowUtc(),
            );
      fx.putFundTransaction(row('c1', 500000, DateKey(2026, 9, 5)));
      fx.putFundTransaction(row('e1', -120000, DateKey(2026, 10, 3)));
      final c = makeContainer();
      keep(c, fundBalanceProvider);
      keep(c, monthClosingsProvider);
      await pump();

      expect(c.read(fundWindowStartProvider), MonthKey(2026, 9));
      expect(c.read(fundBalanceProvider), const Money.paisa(380000));
      expect(c.read(fundSummaryProvider).received, const Money.paisa(500000));

      // Closing September moves the window to October: the September rows no
      // longer count (the next month carries an opening row instead).
      fx.putClosing(monthKey: MonthKey(2026, 9));
      await pump();
      expect(c.read(fundWindowStartProvider), MonthKey(2026, 10));
      expect(c.read(fundBalanceProvider), const Money.paisa(-120000));
      expect(c.read(fundWindowOverflowProvider), isFalse);
    });

    test('no fund start month and no closing means no fund yet', () async {
      final c = makeContainer(settings: BazarSettings.defaults);
      keep(c, fundBalanceProvider);
      await pump();
      expect(c.read(fundWindowStartProvider), isNull);
      expect(c.read(fundBalanceProvider), Money.zero);
    });
  });

  group('advances', () {
    void seed() {
      fx.putAdvance(
        expenseId: 'a1',
        memberId: 'cara',
        amount: const Money.paisa(9000),
      );
      fx.putAdvance(
        expenseId: 'a2',
        memberId: 'alice',
        amount: const Money.paisa(5000),
        settled: const Money.paisa(2000),
      );
    }

    test('a manager sees every open advance and the owed totals', () async {
      seed();
      final c = makeContainer();
      keep(c, openAdvancesProvider);
      await pump();
      expect(c.read(openAdvancesProvider).value!.length, 2);
      final summary = c.read(advanceSummaryProvider);
      expect(summary.openCount, 2);
      expect(summary.owedByMember['cara'], const Money.paisa(9000));
      expect(summary.owedByMember['alice'], const Money.paisa(3000));
      expect(summary.totalOwed, const Money.paisa(12000));
    });

    test('a plain member only queries their own advances', () async {
      seed();
      final c = makeContainer(uid: 'cara', role: Role.member);
      keep(c, openAdvancesProvider);
      await pump();
      expect(
        c.read(openAdvancesProvider).value!.map((a) => a.expenseId),
        ['a1'],
      );
    });
  });

  group('canEditExpenseProvider', () {
    test('a member edits their own rows only; a manager edits any', () {
      final own = fx.putExpense(id: 'own', createdBy: 'cara');
      final other = fx.putExpense(id: 'other', createdBy: 'alice');

      final member = makeContainer(uid: 'cara', role: Role.member);
      expect(member.read(canEditExpenseProvider(own)), isTrue);
      expect(member.read(canEditExpenseProvider(other)), isFalse);

      final manager = makeContainer(uid: 'bob', role: Role.moderator);
      expect(manager.read(canEditExpenseProvider(other)), isTrue);
    });
  });
}
