import 'package:family_hub/app/theme/theme_builder.dart';
import 'package:family_hub/app/theme/theme_registry.dart';
import 'package:family_hub/core/localization/generated/app_localizations.dart';
import 'package:family_hub/core/permissions/permissions.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/core/utils/money.dart';
import 'package:family_hub/features/bazar/contributions/presentation/contribution_providers.dart';
import 'package:family_hub/features/bazar/fund/domain/fund_transaction.dart';
import 'package:family_hub/features/bazar/fund/domain/month_closing.dart';
import 'package:family_hub/features/bazar/fund/presentation/screens/month_close_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../bazar_test_helpers.dart';
import '../../contributions/contribution_test_helpers.dart';
import '../../expenses/presentation/expense_test_container.dart';

/// P2-23: closing and reopening a month from the screen.
void main() {
  late ContributionFixture fixture;

  setUp(() => fixture = ContributionFixture());

  Future<void> pump(
    WidgetTester tester, {
    String uid = 'alice',
    Role role = Role.admin,
    Locale locale = const Locale('en'),
    double textScale = 1,
  }) async {
    tester.view
      ..physicalSize = const Size(420, 1800)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          ...bazarOverrides(fx, uid: uid, role: role),
          contributionRepositoryProvider.overrideWithValue(fixture.repo),
        ],
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
          home: const MonthCloseScreen(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
  }

  FundTransaction contribution(String id, int paisa) =>
      FundTransaction.forContribution(
        contributionId: id,
        amount: Money.paisa(paisa),
        dateKey: DateKey(2026, 10, 5),
        createdBy: 'alice',
        createdAt: fixture.fx.clock.nowUtc(),
      );

  testWidgets('a plain member never sees the Close month action', (
    tester,
  ) async {
    await pump(tester, uid: 'cara', role: Role.member);
    expect(find.byKey(const ValueKey('month-close-action')), findsNothing);
    expect(
      find.text('Only the Household Manager or Admin can close or reopen a month.'),
      findsOneWidget,
    );
  });

  testWidgets('the preview shows the closing balance and open advances', (
    tester,
  ) async {
    fixture.fx.putFundTransaction(contribution('c1', 100000));
    fixture.fx.putAdvance(expenseId: 'e1', memberId: 'cara', amount: const Money.paisa(4000));
    await pump(tester);

    expect(find.byKey(const ValueKey('close-open-advances')), findsOneWidget);
    expect(find.text('1'), findsWidgets);
  });

  testWidgets('closing asks for confirmation and locks the month', (tester) async {
    fixture.fx.putFundTransaction(contribution('c1', 100000));
    await pump(tester);

    await tester.tap(find.byKey(const ValueKey('month-close-action')));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byKey(const ValueKey('month-close-confirm')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('month-close-confirm')));
    await tester.pump(const Duration(milliseconds: 500));

    final closing = fixture.fx.backend.closings[BazarFixture.familyId]![MonthKey(2026, 10)];
    expect(closing!.status, MonthStatus.closed);
    expect(closing.closingBalance, const Money.paisa(100000));
    // The action flips to Reopen.
    expect(find.text('Reopen month'), findsOneWidget);
  });

  testWidgets('reopening requires a note of at least three characters', (
    tester,
  ) async {
    fixture.fx.putClosing(monthKey: MonthKey(2026, 10));
    await pump(tester);

    await tester.tap(find.byKey(const ValueKey('month-close-action')));
    await tester.pump(const Duration(milliseconds: 200));

    await tester.enterText(find.byKey(const ValueKey('reopen-note')), 'ab');
    await tester.tap(find.byKey(const ValueKey('reopen-note-send')));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Write why the month is being reopened.'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('reopen-note')),
      'wrong total',
    );
    await tester.tap(find.byKey(const ValueKey('reopen-note-send')));
    await tester.pump(const Duration(milliseconds: 500));

    final reopened = fixture.fx.backend.closings[BazarFixture.familyId]![MonthKey(2026, 10)]!;
    expect(reopened.status, MonthStatus.open);
    expect(reopened.reopenNote, 'wrong total');
  });

  testWidgets('Bangla at 2x text does not overflow', (tester) async {
    await pump(tester, locale: const Locale('bn'), textScale: 2);
    expect(tester.takeException(), isNull);
  });
}
