import 'package:family_hub/app/theme/theme_builder.dart';
import 'package:family_hub/app/theme/theme_registry.dart';
import 'package:family_hub/core/localization/generated/app_localizations.dart';
import 'package:family_hub/core/permissions/permissions.dart';
import 'package:family_hub/core/utils/clock_provider.dart';
import 'package:family_hub/features/bazar/bazar_entries.dart';
import 'package:family_hub/features/bazar/items_categories/presentation/catalog_providers.dart';
import 'package:family_hub/features/bazar/presentation/bazar_home_screen.dart';
import 'package:family_hub/features/family/presentation/family_providers.dart';
import 'package:family_hub/features/family/presentation/permission_providers.dart';
import 'package:family_hub/shared/widgets/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_states.dart';
import 'bazar_test_helpers.dart';

void main() {
  // bn/en x light/dark x text scale 2.0, plus tap-target, label and contrast
  // guidelines (H11).
  screenStateTests('BazarHomeScreen (empty)', () => const BazarHomeScreen());

  testWidgets('asks an admin to set up an empty catalog', (tester) async {
    await _pump(tester, const BazarHomeScreen());
    expect(find.byType(EmptyState), findsOneWidget);
    expect(find.text('Catalog not set up'), findsOneWidget);
    expect(find.text('Ask an admin to set up the catalog.'), findsOneWidget);
  });

  testWidgets('a manager can seed the starter catalog from the screen', (
    tester,
  ) async {
    final f = BazarFixture();
    await _pump(
      tester,
      const BazarHomeScreen(entries: [], dashboardCards: []),
      actor: const PermissionActor(
        uid: 'alice',
        role: Role.admin,
        isActive: true,
      ),
      fixture: f,
    );

    expect(find.text('Set up the starter catalog'), findsOneWidget);
    await tester.tap(find.text('Set up catalog'));
    await tester.pumpAndSettle();

    expect(f.backend.categoriesOf(BazarFixture.familyId), hasLength(11));
    expect(f.backend.itemsOf(BazarFixture.familyId), hasLength(54));
    expect(find.text('Set up the starter catalog'), findsNothing);
  });

  testWidgets('hides an entry the viewer may not use', (tester) async {
    final f = BazarFixture()..putCategory();
    final entries = <BazarEntry>[
      BazarEntry(
        id: 'own-expense',
        icon: Icons.add_circle_outline,
        label: (l10n) => l10n.commonSeeAll,
        route: '/bazar/expenses',
        requires: Permission.addOwnExpense,
      ),
      BazarEntry(
        id: 'catalog',
        icon: Icons.lock_outline,
        label: (l10n) => l10n.actionConfirm,
        route: '/bazar/catalog',
        requires: Permission.manageCatalogAndBudgets,
      ),
    ];

    await _pump(
      tester,
      BazarHomeScreen(entries: entries, dashboardCards: []),
      actor: const PermissionActor(
        uid: 'member',
        role: Role.member,
        isActive: true,
      ),
      fixture: f,
    );

    expect(find.text('See all'), findsOneWidget);
    expect(find.text('Confirm'), findsNothing);
    expect(find.byIcon(Icons.add_circle_outline), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline), findsNothing);
  });
}

Future<void> _pump(
  WidgetTester tester,
  Widget home, {
  PermissionActor? actor,
  BazarFixture? fixture,
}) async {
  tester.view
    ..physicalSize = const Size(400, 900)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        if (fixture != null) ...[
          currentUidProvider.overrideWithValue('alice'),
          currentFamilyIdProvider.overrideWithValue(BazarFixture.familyId),
          familyRepositoryProvider.overrideWithValue(fixture.backend),
          catalogRepositoryProvider.overrideWithValue(fixture.backend),
          clockProvider.overrideWithValue(fixture.clock),
          idGeneratorProvider.overrideWithValue(fixture.ids.call),
        ],
        if (actor != null) currentActorProvider.overrideWithValue(actor),
        if (actor != null)
          permissionSettingsProvider.overrideWithValue(
            PermissionSettings.defaults,
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
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: home,
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 100));
}
