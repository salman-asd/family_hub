import 'package:family_hub/app/theme/theme_builder.dart';
import 'package:family_hub/app/theme/theme_controller.dart'
    show sharedPreferencesProvider;
import 'package:family_hub/app/theme/theme_registry.dart';
import 'package:family_hub/core/localization/generated/app_localizations.dart';
import 'package:family_hub/core/permissions/permissions.dart';
import 'package:family_hub/core/utils/clock.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/core/utils/family_date_keys.dart';
import 'package:family_hub/core/utils/money.dart';
import 'package:family_hub/features/bazar/budgets/domain/budget.dart';
import 'package:family_hub/features/bazar/budgets/domain/budget_alert.dart';
import 'package:family_hub/features/bazar/budgets/domain/budget_status.dart';
import 'package:family_hub/features/bazar/budgets/presentation/budget_providers.dart';
import 'package:family_hub/features/bazar/bazar_entries.dart';
import 'package:family_hub/features/bazar/contributions/domain/contribution.dart';
import 'package:family_hub/features/bazar/contributions/domain/contribution_status.dart';
import 'package:family_hub/features/bazar/contributions/presentation/contribution_providers.dart';
import 'package:family_hub/features/bazar/expenses/domain/expense.dart';
import 'package:family_hub/features/bazar/expenses/domain/funding.dart';
import 'package:family_hub/features/bazar/expenses/presentation/expense_providers.dart';
import 'package:family_hub/features/bazar/fund/domain/fund_transaction.dart';
import 'package:family_hub/features/bazar/fund/presentation/fund_providers.dart';
import 'package:family_hub/features/bazar/items_categories/domain/category.dart';
import 'package:family_hub/features/bazar/items_categories/presentation/catalog_providers.dart';
import 'package:family_hub/features/bazar/presentation/bazar_home_screen.dart';
import 'package:family_hub/features/bazar/presentation/widgets/dashboard/bazar_month_card.dart';
import 'package:family_hub/features/bazar/presentation/widgets/dashboard/budget_alert_card.dart';
import 'package:family_hub/features/bazar/presentation/widgets/dashboard/fund_balance_card.dart';
import 'package:family_hub/features/dashboard/presentation/home_screen.dart';
import 'package:family_hub/features/family/domain/member.dart';
import 'package:family_hub/features/family/domain/module_flags.dart';
import 'package:family_hub/features/family/presentation/family_providers.dart';
import 'package:family_hub/features/family/presentation/permission_providers.dart';
import 'package:family_hub/modules/module_providers.dart';
import 'package:family_hub/shared/widgets/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../support/screen_states.dart';

final _month = MonthKey(2026, 10);
const _category = Category(
  id: 'cat-food',
  nameBn: 'খাবার',
  nameEn: 'Food',
  colorIndex: 0,
  sortOrder: 0,
);
const _status = MemberContributionStatus(
  memberId: 'member',
  expected: Money.paisa(50000),
  received: Money.paisa(20000),
  remaining: Money.paisa(30000),
  credit: Money.zero,
  pendingTotal: Money.paisa(10000),
);
const _alert = BudgetAlert(
  categoryId: 'cat-food',
  status: CategoryBudgetStatus(
    limit: Money.paisa(10000),
    spent: Money.paisa(12000),
    remaining: Money.paisa(-2000),
    percentBp: 12000,
    level: BudgetLevel.exceeded,
  ),
);
final _pending = Contribution(
  id: 'pending-1',
  memberId: 'member',
  monthKey: _month,
  dateKey: DateKey(2026, 10, 12),
  amount: Money.paisa(10000),
  status: ContributionApproval.pending,
  requestedBy: 'member',
  createdAt: DateTime.utc(2026, 10, 12),
);

void main() {
  screenStateTests(
    'Bazar dashboard cards',
    () => const Column(
      children: [
        BazarMonthCard(),
        FundBalanceCard(),
        BudgetAlertCard(),
      ],
    ),
    overrides: (_) => _readyOverrides(),
  );

  testWidgets('month card shows live month spend and its top category', (
    tester,
  ) async {
    await _pump(
      tester,
      const BazarMonthCard(),
      overrides: _readyOverrides(expenses: [_expense()]),
    );

    expect(find.byKey(const ValueKey('dashboard-bazar-month')), findsOneWidget);
    expect(find.text('Food'), findsOneWidget);
    expect(find.text('Total'), findsOneWidget);
  });

  testWidgets('month card has empty and error states', (tester) async {
    await _pump(
      tester,
      const BazarMonthCard(),
      overrides: _readyOverrides(expenses: const []),
    );
    expect(find.text('No expenses this month'), findsOneWidget);

    await _pump(
      tester,
      const BazarMonthCard(),
      overrides: _readyOverrides(expenseLoading: true),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await _pump(
      tester,
      const BazarMonthCard(),
      overrides: _readyOverrides(expenseError: true),
    );
    expect(
      find.text('No internet connection. Check your connection and try again.'),
      findsOneWidget,
    );
  });

  testWidgets('fund and budget cards surface read errors', (tester) async {
    await _pump(
      tester,
      const FundBalanceCard(),
      overrides: _readyOverrides(fundError: true),
    );
    expect(
      find.text('No internet connection. Check your connection and try again.'),
      findsOneWidget,
    );

    await _pump(
      tester,
      const BudgetAlertCard(),
      overrides: _readyOverrides(budgetError: true),
    );
    expect(
      find.text('No internet connection. Check your connection and try again.'),
      findsOneWidget,
    );
  });

  testWidgets('fund card shows family figures and managers pending count', (
    tester,
  ) async {
    await _pump(
      tester,
      const FundBalanceCard(),
      actor: const PermissionActor(
        uid: 'admin',
        role: Role.admin,
        isActive: true,
      ),
      overrides: _readyOverrides(),
    );

    expect(find.byKey(const ValueKey('dashboard-fund-value')), findsOneWidget);
    expect(find.text('Received:'), findsOneWidget);
    expect(
      find.textContaining('contributions awaiting approval'),
      findsOneWidget,
    );
  });

  testWidgets('plain members do not see the approvals action', (tester) async {
    await _pump(
      tester,
      const FundBalanceCard(),
      actor: const PermissionActor(
        uid: 'member',
        role: Role.member,
        isActive: true,
      ),
      overrides: _readyOverrides(),
    );

    expect(find.byKey(const ValueKey('dashboard-fund-pending')), findsNothing);
  });

  testWidgets('budget card shows the first (worst) alert and hides when clear', (
    tester,
  ) async {
    await _pump(
      tester,
      const BudgetAlertCard(),
      overrides: _readyOverrides(alerts: [_alert]),
    );
    expect(find.byKey(const ValueKey('dashboard-budget-alert')), findsOneWidget);
    expect(find.text('Food'), findsOneWidget);

    await _pump(
      tester,
      const BudgetAlertCard(),
      overrides: _readyOverrides(alerts: const []),
    );
    expect(find.byKey(const ValueKey('dashboard-budget-alert')), findsNothing);
  });

  testWidgets('home only includes dashboard cards from visible modules', (
    tester,
  ) async {
    await _pump(
      tester,
      const HomeScreen(),
      fullScreen: true,
      overrides: [
        ..._readyOverrides(alerts: const []),
        moduleFlagsProvider.overrideWithValue(
          const ModuleFlags({'bazar': false}),
        ),
      ],
    );
    expect(find.byKey(const ValueKey('dashboard-bazar-month')), findsNothing);
    expect(find.byType(EmptyState), findsOneWidget);

    await _pump(
      tester,
      const HomeScreen(),
      fullScreen: true,
      overrides: [
        ..._readyOverrides(alerts: const []),
        moduleFlagsProvider.overrideWithValue(ModuleFlags.allOn),
      ],
    );
    expect(find.byKey(const ValueKey('dashboard-bazar-month')), findsOneWidget);
    expect(find.byKey(const ValueKey('dashboard-fund-balance')), findsOneWidget);
  });

  testWidgets('Bazar home places its summary above the budget entry and badge', (
    tester,
  ) async {
    final budget = BazarEntry(
      id: 'budget',
      icon: Icons.savings_outlined,
      label: (l10n) => l10n.budgetTitle,
      route: '/bazar/budget',
    );
    await _pump(
      tester,
      BazarHomeScreen(
        entries: [budget],
      ),
      fullScreen: true,
      overrides: _readyOverrides(alerts: [_alert]),
    );

    final monthCard = find.byKey(const ValueKey('dashboard-bazar-month'));
    final fundCard = find.byKey(const ValueKey('dashboard-fund-balance'));
    final budgetTile = find.text('Budget');
    expect(monthCard, findsOneWidget);
    expect(fundCard, findsOneWidget);
    expect(
      tester.getTopLeft(monthCard).dy,
      lessThan(tester.getTopLeft(budgetTile).dy),
    );
    expect(find.byIcon(Icons.warning_amber_rounded), findsWidgets);
  });
}

List<Override> _readyOverrides({
  List<Expense> expenses = const [],
  List<BudgetAlert> alerts = const [_alert],
  bool expenseError = false,
  bool expenseLoading = false,
  bool fundError = false,
  bool budgetError = false,
}) => [
  familyDateKeysProvider.overrideWithValue(
    FamilyDateKeys(clock: FakeClock(DateTime.utc(2026, 10, 18))),
  ),
  monthExpensesProvider.overrideWith(
    (ref, month) {
      if (expenseError) return Stream<List<Expense>>.error(StateError('offline'));
      if (expenseLoading) return const Stream<List<Expense>>.empty();
      return Stream.value(expenses);
    },
  ),
  categoriesProvider.overrideWith((ref) => Stream.value([_category])),
  fundTransactionsProvider.overrideWith(
    (ref) => fundError
        ? Stream<List<FundTransaction>>.error(StateError('offline'))
        : Stream.value(const <FundTransaction>[]),
  ),
  contributionPlansProvider.overrideWith(
    (ref, month) => Stream.value(const <ContributionPlan>[]),
  ),
  contributionsProvider.overrideWith(
    (ref, month) => Stream.value(<Contribution>[_pending]),
  ),
  membersProvider.overrideWith((ref) => Stream.value(const <Member>[])),
  monthBudgetProvider.overrideWith(
    (ref, month) => budgetError
        ? Stream<Budget?>.error(StateError('offline'))
        : Stream.value(null),
  ),
  fundBalanceProvider.overrideWithValue(const Money.paisa(100000)),
  contributionStatusProvider.overrideWith((ref, month) => const [_status]),
  pendingContributionsProvider.overrideWith(
    (ref, month) => <Contribution>[_pending, _pending],
  ),
  budgetAlertsProvider.overrideWith((ref) => alerts),
  permissionSettingsProvider.overrideWithValue(PermissionSettings.defaults),
];

Expense _expense() => Expense(
  id: 'expense-1',
  dateKey: DateKey(2026, 10, 12),
  monthKey: _month,
  occurredAt: DateTime.utc(2026, 10, 12),
  itemName: 'Rice',
  categoryId: _category.id,
  total: const Money.paisa(12000),
  funding: FundingSource.fund,
  createdBy: 'member',
  createdAt: DateTime.utc(2026, 10, 12),
);

Future<void> _pump(
  WidgetTester tester,
  Widget screen, {
  required List<Override> overrides,
  bool fullScreen = false,
  PermissionActor? actor,
}) async {
  tester.view
    ..physicalSize = const Size(400, 900)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        ...overrides,
        currentActorProvider.overrideWithValue(
          actor ??
              const PermissionActor(
                uid: 'member',
                role: Role.member,
                isActive: true,
              ),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildThemeData(modernLightSpec),
        locale: const Locale('en'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: fullScreen
            ? screen
            : Scaffold(
                body: ListView(
                  padding: const EdgeInsets.all(8),
                  children: [screen],
                ),
              ),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 100));
}
