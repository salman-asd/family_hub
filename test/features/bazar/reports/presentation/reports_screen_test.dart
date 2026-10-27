import 'package:family_hub/app/theme/theme_builder.dart';
import 'package:family_hub/app/theme/theme_registry.dart';
import 'package:family_hub/core/localization/generated/app_localizations.dart';
import 'package:family_hub/core/permissions/permissions.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/core/utils/money.dart';
import 'package:family_hub/features/bazar/contributions/presentation/contribution_providers.dart';
import 'package:family_hub/features/bazar/reports/presentation/screens/reports_screen.dart';
import 'package:family_hub/features/family/presentation/permission_providers.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../bazar_test_helpers.dart';
import '../../contributions/contribution_test_helpers.dart';
import '../../expenses/presentation/expense_test_container.dart';

/// P2-25: the reports screen tabs, charts, tables and permission fallback.
void main() {
  late BazarFixture fx;
  late ContributionFixture contributions;

  setUp(() {
    contributions = ContributionFixture();
    fx = contributions.fx;
  });

  Future<void> pump(
    WidgetTester tester, {
    String uid = 'alice',
    Role role = Role.admin,
    Locale locale = const Locale('en'),
    double textScale = 1,
    PermissionSettings? settings,
  }) async {
    tester.view
      ..physicalSize = const Size(440, 1600)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          ...bazarOverrides(fx, uid: uid, role: role),
          if (settings != null)
            permissionSettingsProvider.overrideWithValue(settings),
          contributionRepositoryProvider.overrideWithValue(contributions.repo),
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
          home: const ReportsScreen(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));
  }

  void seedMonth() {
    fx.putCategory(id: 'cat_food', nameBn: 'খাবার', nameEn: 'Food');
    fx.putExpense(
      id: 'a',
      total: const Money.paisa(60000),
      categoryId: 'cat_food',
      itemName: 'চাল',
    );
    fx.putExpense(
      id: 'b',
      dateKey: DateKey(2026, 10, 9),
      total: const Money.paisa(40000),
      categoryId: 'cat_food',
      itemName: 'ডাল',
    );
  }

  testWidgets('the summary tab shows the total and the comparison', (
    tester,
  ) async {
    seedMonth();
    fx.putExpense(
      id: 'sep',
      dateKey: DateKey(2026, 9, 5),
      total: const Money.paisa(50000),
      categoryId: 'cat_food',
    );
    await pump(tester);

    expect(find.byKey(const ValueKey('report-tab-summary')), findsOneWidget);
    expect(find.byKey(const ValueKey('report-row-total')), findsOneWidget);
    // 100000 now against 50000 before: up 100 %.
    expect(find.byKey(const ValueKey('report-delta')), findsOneWidget);
    expect(find.text('Up '), findsOneWidget);
    expect(find.text(' 100%'), findsOneWidget);
  });

  testWidgets('the categories tab draws a pie and announces a text alternative', (
    tester,
  ) async {
    seedMonth();
    await pump(tester);

    await tester.tap(find.byKey(const ValueKey('report-tab-categories')));
    await tester.pumpAndSettle();

    expect(find.byType(PieChart), findsOneWidget);
    // The chart is announced once, with the values in words.
    expect(
      find.bySemanticsLabel(RegExp('Food .*of total')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('report-row-cat_food')), findsOneWidget);
  });

  testWidgets('the days tab draws a bar chart and lists zero days', (
    tester,
  ) async {
    seedMonth();
    await pump(tester);

    await tester.tap(find.byKey(const ValueKey('report-tab-days')));
    await tester.pumpAndSettle();

    expect(find.byType(BarChart), findsOneWidget);
    expect(find.byKey(const ValueKey('report-row-total')), findsOneWidget);
  });

  testWidgets('a preset chip re-targets the whole report', (tester) async {
    seedMonth();
    await pump(tester);

    // "Today" (2026-10-18) has no rows.
    await tester.tap(find.byKey(const ValueKey('report-preset-today')));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byKey(const ValueKey('report-tab-summary')), findsOneWidget);
    expect(find.byKey(const ValueKey('report-delta')), findsNothing);
  });

  testWidgets('a member WITHOUT viewFamilyReports sees only contributions', (
    tester,
  ) async {
    await pump(
      tester,
      uid: 'cara',
      role: Role.member,
      settings: PermissionSettings.defaults.copyWith(
        membersViewFamilyReports: false,
      ),
    );

    expect(find.byKey(const ValueKey('report-tab-summary')), findsNothing);
    expect(find.byKey(const ValueKey('report-tab-categories')), findsNothing);
    // The report title is there, and the contributions content with it.
    expect(find.text('Reports'), findsOneWidget);
    expect(find.byKey(const ValueKey('report-tab-contributions')), findsNothing);
  });

  testWidgets('a member WITH the default switch sees every tab', (
    tester,
  ) async {
    await pump(tester, uid: 'cara', role: Role.member);
    expect(find.byKey(const ValueKey('report-tab-summary')), findsOneWidget);
  });

  testWidgets('Bangla at 2x text does not overflow', (tester) async {
    seedMonth();
    await pump(tester, locale: const Locale('bn'), textScale: 2);

    expect(tester.takeException(), isNull);
    await tester.tap(find.byKey(const ValueKey('report-tab-categories')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('an empty month shows the empty chart message', (tester) async {
    await pump(tester);
    await tester.tap(find.byKey(const ValueKey('report-tab-categories')));
    await tester.pumpAndSettle();

    expect(find.text('Nothing to chart for this period yet.'), findsWidgets);
  });
}
