import 'package:family_hub/app/theme/theme_builder.dart';
import 'package:family_hub/app/theme/theme_registry.dart';
import 'package:family_hub/core/localization/generated/app_localizations.dart';
import 'package:family_hub/core/permissions/permissions.dart';
import 'package:family_hub/core/utils/money.dart';
import 'package:family_hub/features/bazar/advances/presentation/screens/advances_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../bazar_test_helpers.dart';
import '../../expenses/presentation/expense_test_container.dart';

/// P2-23: the Advances screen over the real providers and in-memory ports.
void main() {
  late BazarFixture fx;

  setUp(() => fx = BazarFixture());

  Future<void> pump(
    WidgetTester tester, {
    String uid = 'alice',
    Role role = Role.admin,
    Locale locale = const Locale('en'),
    double textScale = 1,
  }) async {
    tester.view
      ..physicalSize = const Size(420, 1400)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: bazarOverrides(fx, uid: uid, role: role),
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: buildThemeData(modernLightSpec),
          locale: locale,
          localizationsDelegates: const <LocalizationsDelegate<Object>>[
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
          home: const AdvancesScreen(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('groups open advances by member with the owed total', (
    tester,
  ) async {
    fx.putAdvance(expenseId: 'e1', memberId: 'cara', amount: const Money.paisa(5000));
    fx.putAdvance(expenseId: 'e2', memberId: 'cara', amount: const Money.paisa(7000));
    fx.putAdvance(expenseId: 'e3', memberId: 'bob', amount: const Money.paisa(1000));
    await pump(tester);

    expect(find.byKey(const ValueKey('advance-group-cara')), findsOneWidget);
    expect(find.byKey(const ValueKey('advance-group-bob')), findsOneWidget);
    expect(find.byKey(const ValueKey('advance-owed-cara')), findsOneWidget);
    expect(find.byKey(const ValueKey('advances-total')), findsOneWidget);
  });

  testWidgets('a member sees only their own rows and no settle action', (
    tester,
  ) async {
    fx.putAdvance(expenseId: 'e1', memberId: 'cara', amount: const Money.paisa(5000));
    fx.putAdvance(expenseId: 'e2', memberId: 'bob', amount: const Money.paisa(1000));
    await pump(tester, uid: 'cara', role: Role.member);

    expect(find.byKey(const ValueKey('advance-group-cara')), findsOneWidget);
    expect(find.byKey(const ValueKey('advance-group-bob')), findsNothing);
    expect(find.byKey(const ValueKey('advance-settle-e1')), findsNothing);
  });

  testWidgets('a manager settles in two instalments', (tester) async {
    fx.putAdvance(expenseId: 'e1', memberId: 'cara', amount: const Money.paisa(10000));
    await pump(tester);

    await tester.tap(find.byKey(const ValueKey('advance-settle-e1')));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.enterText(find.byKey(const ValueKey('settle-amount')), '4000');
    await tester.tap(find.byKey(const ValueKey('settle-save')));
    await tester.pump(const Duration(milliseconds: 400));

    expect(
      fx.backend.advances[BazarFixture.familyId]!['e1']!.settled,
      const Money.paisa(4000),
    );
  });

  testWidgets('an overpayment shows inline and does not save', (tester) async {
    fx.putAdvance(expenseId: 'e1', memberId: 'cara', amount: const Money.paisa(5000));
    await pump(tester);

    await tester.tap(find.byKey(const ValueKey('advance-settle-e1')));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.enterText(find.byKey(const ValueKey('settle-amount')), '9000');
    await tester.tap(find.byKey(const ValueKey('settle-save')));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byKey(const ValueKey('settle-error')), findsOneWidget);
    expect(fx.backend.writes, 0);
  });

  testWidgets('an empty list shows the empty state (Bangla at 2x)', (
    tester,
  ) async {
    await pump(tester, locale: const Locale('bn'), textScale: 2);
    expect(tester.takeException(), isNull);
    expect(find.text('ফেরত দেওয়ার কিছু নেই'), findsOneWidget);
  });
}
