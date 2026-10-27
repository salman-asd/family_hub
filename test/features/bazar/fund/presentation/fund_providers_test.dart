import 'package:family_hub/core/permissions/permissions.dart';
import 'package:family_hub/core/utils/clock_provider.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/core/utils/money.dart';
import 'package:family_hub/features/bazar/contributions/presentation/contribution_providers.dart';
import 'package:family_hub/features/bazar/expenses/presentation/expense_providers.dart';
import 'package:family_hub/features/bazar/fund/domain/fund_transaction.dart';
import 'package:family_hub/features/bazar/fund/presentation/fund_providers.dart';
import 'package:family_hub/features/bazar/settings/domain/bazar_settings.dart';
import 'package:family_hub/features/bazar/settings/presentation/bazar_settings_providers.dart';
import 'package:family_hub/features/family/presentation/family_providers.dart';
import 'package:family_hub/features/family/presentation/permission_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../bazar_test_helpers.dart';
import '../../contributions/contribution_test_helpers.dart';

/// P2-22: the providers the Fund screen reads.
void main() {
  late ContributionFixture fx;

  setUp(() => fx = ContributionFixture());

  ProviderContainer makeContainer() {
    final container = ProviderContainer(
      overrides: <Override>[
        clockProvider.overrideWithValue(fx.fx.clock),
        currentFamilyIdProvider.overrideWithValue(BazarFixture.familyId),
        currentUidProvider.overrideWithValue('alice'),
        currentActorProvider.overrideWithValue(
          const PermissionActor(uid: 'alice', role: Role.admin, isActive: true),
        ),
        permissionSettingsProvider.overrideWithValue(
          PermissionSettings.defaults,
        ),
        bazarSettingsProvider.overrideWithValue(
          BazarSettings.defaults.copyWith(fundStartMonth: MonthKey(2026, 9)),
        ),
        expenseRepositoryProvider.overrideWithValue(fx.fx.backend),
        fundRepositoryProvider.overrideWithValue(fx.fx.backend),
        fundOpeningLedgerProvider.overrideWithValue(fx.fx.backend),
        contributionRepositoryProvider.overrideWithValue(fx.repo),
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

  test('balance and summary come from the ledger window', () async {
    fx.fx.putFundTransaction(
      FundTransaction.forContribution(
        contributionId: 'c1',
        amount: const Money.paisa(100000),
        dateKey: DateKey(2026, 10, 5),
        createdBy: 'alice',
        createdAt: fx.fx.clock.nowUtc(),
      ),
    );
    final c = makeContainer();
    keep(c, fundTransactionsProvider);
    await pump();

    expect(c.read(fundBalanceProvider), const Money.paisa(100000));
    expect(c.read(fundSummaryProvider).received, const Money.paisa(100000));
    expect(c.read(fundWindowOverflowProvider), isFalse);
  });

  test('the month rows only include the selected month', () async {
    final backend = fx.fx.backend;
    (backend.fundTransactions[BazarFixture.familyId] ??=
            <String, FundTransaction>{})['open_2026-09'] =
        FundTransaction.opening(
          monthKey: MonthKey(2026, 9),
          amount: const Money.paisa(5000),
          createdBy: 'alice',
          createdAt: fx.fx.clock.nowUtc(),
        );
    backend.expenseNotify();
    final c = makeContainer();
    keep(c, fundTransactionsProvider);
    await pump();

    expect(
      c.read(monthFundTransactionsProvider(MonthKey(2026, 9))),
      hasLength(1),
    );
    expect(c.read(monthFundTransactionsProvider(MonthKey(2026, 10))), isEmpty);
  });

  test('ledgerIntegrityProvider reports a broken expense', () async {
    fx.fx.putExpense(id: 'e1', total: const Money.paisa(12000));
    final c = makeContainer();
    keep(c, monthExpensesProvider(MonthKey(2026, 10)));
    keep(c, fundTransactionsProvider);
    await pump();

    final issues = c.read(ledgerIntegrityProvider(MonthKey(2026, 10)));
    expect(issues, hasLength(1));
    expect(issues.single.refId, 'e1');
  });

  test('no drift while the stored balance and the ledger agree', () async {
    final c = makeContainer();
    keep(c, fundTransactionsProvider);
    await pump();
    expect(c.read(balanceDriftProvider), isNull);
  });

  test('the use-case providers build without a repository call', () {
    final c = makeContainer();
    expect(c.read(closeMonthProvider), isA<Object>());
    expect(c.read(reopenMonthProvider), isA<Object>());
  });
}
