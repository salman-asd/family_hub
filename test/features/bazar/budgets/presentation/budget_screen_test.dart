import 'package:family_hub/app/theme/theme_builder.dart';
import 'package:family_hub/app/theme/theme_controller.dart'
    show sharedPreferencesProvider;
import 'package:family_hub/app/theme/theme_registry.dart';
import 'package:family_hub/core/localization/generated/app_localizations.dart';
import 'package:family_hub/core/permissions/permissions.dart';
import 'package:family_hub/core/utils/money.dart';
import 'package:family_hub/features/bazar/budgets/presentation/budget_providers.dart';
import 'package:family_hub/features/bazar/budgets/presentation/screens/budget_screen.dart';
import 'package:family_hub/shared/widgets/progress_bar_status.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../expenses/presentation/expense_test_container.dart';
import '../budget_test_helpers.dart';
import '../../../../support/shared_preferences_test_support.dart';

Future<void> _pump(
  WidgetTester tester,
  BudgetFixture f, {
  String uid = 'alice',
  Role role = Role.admin,
  Locale locale = const Locale('en'),
  double textScale = 1,
}) async {
  tester.view
    ..physicalSize = const Size(400, 1400)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final prefs = await mockSharedPreferences();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        ...bazarOverrides(f.fx, uid: uid, role: role),
        budgetRepositoryProvider.overrideWithValue(f.repository),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildThemeData(modernLightSpec),
        locale: locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: const BudgetScreen(),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pumpAndSettle();
}

void main() {
  late BudgetFixture f;

  setUp(() {
    f = BudgetFixture();
    f.fx.putCategory();
  });

  testWidgets('empty month: a manager can plan or copy; a member cannot', (
    tester,
  ) async {
    await _pump(tester, f);
    expect(find.text('No budget for this month'), findsOneWidget);
    expect(find.text('Plan this month'), findsWidgets);
    expect(find.byKey(const ValueKey('budget-copy-last')), findsOneWidget);
    expect(
      find.text('A budget is a plan; the fund balance is real money.'),
      findsOneWidget,
    );
  });

  testWidgets('a member sees the empty state read-only', (tester) async {
    await _pump(tester, f, uid: 'cara', role: Role.member);
    expect(find.byKey(const ValueKey('budget-copy-last')), findsNothing);
    expect(find.text('Plan this month'), findsNothing);
    expect(
      find.text(
        'The Household Manager or Admin has not planned this month yet.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('copy last month without a previous budget says so', (
    tester,
  ) async {
    await _pump(tester, f);
    await tester.tap(find.byKey(const ValueKey('budget-copy-last')));
    await tester.pump(const Duration(milliseconds: 200));
    expect(
      find.text('There is no budget for last month to copy.'),
      findsOneWidget,
    );
  });

  testWidgets('copy last month fills the month', (tester) async {
    f.repository.stored[BudgetFixture.september] = sampleBudget(
      BudgetFixture.september,
      total: const Money.paisa(100000),
      categories: const {'cat_food': Money.paisa(100000)},
    );
    await _pump(tester, f);
    await tester.tap(find.byKey(const ValueKey('budget-copy-last')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const ValueKey('budget-bar-total')), findsOneWidget);
    expect(f.repository.stored.containsKey(BudgetFixture.october), isTrue);
  });

  testWidgets('bars show icon + word + percent and move with spending', (
    tester,
  ) async {
    f.repository.stored[BudgetFixture.october] = sampleBudget(
      BudgetFixture.october,
      total: const Money.paisa(10000),
      categories: const {'cat_food': Money.paisa(10000)},
    );
    await _pump(tester, f);
    final totalBar = tester.widget<ProgressBarStatus>(
      find.byKey(const ValueKey('budget-bar-total')),
    );
    expect(totalBar.basisPoints, 0);
    expect(find.textContaining('On track'), findsWidgets);

    f.fx.putExpense(id: 'e1', total: const Money.paisa(8500));
    f.fx.backend.expenseNotify();
    await tester.pump(const Duration(milliseconds: 300));
    expect(
      tester
          .widget<ProgressBarStatus>(
            find.byKey(const ValueKey('budget-bar-total')),
          )
          .basisPoints,
      8500,
    );
    expect(find.byIcon(Icons.warning_amber_rounded), findsWidgets);

    f.fx.putExpense(id: 'e2', total: const Money.paisa(3000));
    f.fx.backend.expenseNotify();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byIcon(Icons.error_outline_rounded), findsWidgets);
  });

  testWidgets('a member sees progress but no edit button', (tester) async {
    f.repository.stored[BudgetFixture.october] = sampleBudget(
      BudgetFixture.october,
      total: const Money.paisa(10000),
    );
    await _pump(tester, f, uid: 'cara', role: Role.member);
    expect(find.byKey(const ValueKey('budget-bar-total')), findsOneWidget);
    expect(find.byKey(const ValueKey('budget-edit')), findsNothing);
  });

  testWidgets('the table total recalculates and the sum is shown', (
    tester,
  ) async {
    await _pump(tester, f);
    await tester.tap(find.text('Plan this month').first);
    await tester.pump(const Duration(milliseconds: 200));

    await tester.ensureVisible(find.byKey(const ValueKey('line-add')));
    await tester.tap(find.byKey(const ValueKey('line-add')));
    await tester.pump();

    await tester.enterText(find.byKey(const ValueKey('line-name-0')), 'Rice');
    await tester.enterText(find.byKey(const ValueKey('line-qty-0')), '50');
    await tester.enterText(find.byKey(const ValueKey('line-rate-0')), '70');
    await tester.pump();

    expect(find.byKey(const ValueKey('line-calculated')), findsOneWidget);
    expect(find.byKey(const ValueKey('lines-sum')), findsOneWidget);
  });

  testWidgets('saving a planned month shows the bars', (tester) async {
    f.fx.putCategory(
      id: 'cat_dry_groceries',
      nameBn: 'শুকনা বাজার',
      nameEn: 'Dry groceries',
    );
    await _pump(tester, f);
    await tester.tap(find.text('Plan this month').first);
    await tester.pump(const Duration(milliseconds: 200));

    await tester.enterText(find.byKey(const ValueKey('budget-total')), '5000');
    await tester.ensureVisible(find.byKey(const ValueKey('budget-save')));
    await tester.tap(find.byKey(const ValueKey('budget-save')));
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      f.repository.stored[BudgetFixture.october]!.totalEstimate,
      const Money.paisa(500000),
    );
    expect(find.byKey(const ValueKey('budget-bar-total')), findsOneWidget);
    expect(find.text('Budget saved'), findsOneWidget);
  });

  testWidgets('no overflow in Bangla at text scale 2.0', (tester) async {
    f.repository.stored[BudgetFixture.october] = sampleBudget(
      BudgetFixture.october,
      total: const Money.paisa(10000),
      categories: const {'cat_food': Money.paisa(10000)},
      lines: const [riceLine],
    );
    f.fx.putExpense(id: 'e1', total: const Money.paisa(9000));
    await _pump(tester, f, locale: const Locale('bn'), textScale: 2);
    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('budget-edit')),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.byKey(const ValueKey('budget-edit')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
  });
}
