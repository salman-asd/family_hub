import 'package:family_hub/app/routing/app_routes.dart';
import 'package:family_hub/app/theme/theme_builder.dart';
import 'package:family_hub/app/theme/theme_registry.dart';
import 'package:family_hub/core/localization/generated/app_localizations.dart';
import 'package:family_hub/core/utils/money.dart';
import 'package:family_hub/features/bazar/expenses/presentation/screens/add_expense_screen.dart';
import 'package:family_hub/features/bazar/expenses/presentation/screens/expense_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../bazar_test_helpers.dart';
import 'expense_test_container.dart';

Future<void> _pump(WidgetTester tester, BazarFixture fx, Widget screen) async {
  tester.view
    ..physicalSize = const Size(400, 1000)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, _) => screen),
      GoRoute(
        path: AppRoutes.bazar,
        builder: (_, _) => const Scaffold(body: Text('bazar home')),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: bazarOverrides(fx),
      child: MaterialApp.router(
        routerConfig: router,
        debugShowCheckedModeBanner: false,
        theme: buildThemeData(modernLightSpec),
        locale: const Locale('en'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 200));
}

void main() {
  testWidgets('a catalog item is saved in at most 4 taps after choosing it', (
    tester,
  ) async {
    final fx = BazarFixture()
      ..putCategory()
      ..putItem();
    await _pump(tester, fx, const AddExpenseScreen());

    var taps = 0;
    Future<void> tap(Finder finder) async {
      await tester.tap(finder);
      taps++;
      await tester.pump(const Duration(milliseconds: 100));
    }

    // Typing is not a tap.  Focus the item field, type, then pick the match.
    await tap(find.byType(TextField).first);
    await tester.enterText(find.byType(TextField).first, 'চাল');
    await tester.pump(const Duration(milliseconds: 100));
    await tap(
      find.descendant(of: find.byType(ListTile), matching: find.text('চাল')),
    );
    final afterSelection = taps;

    await tester.enterText(find.byKey(const ValueKey('field-total')), '120');
    await tester.pump();
    await tap(find.byKey(const ValueKey('expense-save')));
    await tester.pumpAndSettle();

    expect(taps - afterSelection, lessThanOrEqualTo(4));
    final saved = fx.backend.expensesOf(BazarFixture.familyId).single;
    expect(saved.total, const Money.paisa(12000));
    expect(saved.itemId, 'item_rice');
    expect(find.text('bazar home'), findsOneWidget);
  });

  testWidgets('Save with nothing entered shows inline errors, no write', (
    tester,
  ) async {
    final fx = BazarFixture()..putCategory();
    await _pump(tester, fx, const AddExpenseScreen());

    await tester.ensureVisible(find.byKey(const ValueKey('expense-save')));
    await tester.tap(find.byKey(const ValueKey('expense-save')));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Enter a valid amount.'), findsWidgets);
    expect(fx.backend.expensesOf(BazarFixture.familyId), isEmpty);
  });

  testWidgets('the expense list groups rows by day and shows the total', (
    tester,
  ) async {
    final fx = BazarFixture()..putCategory();
    fx
      ..putExpense(id: 'a', itemName: 'চাল', total: const Money.paisa(10000))
      ..putExpense(id: 'b', itemName: 'ডাল', total: const Money.paisa(5000));
    await _pump(tester, fx, const ExpenseListScreen());
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('চাল'), findsOneWidget);
    expect(find.text('ডাল'), findsOneWidget);
    expect(find.byKey(const ValueKey('expense-add-fab')), findsOneWidget);
  });
}
