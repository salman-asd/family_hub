import 'package:family_hub/app/theme/theme_builder.dart';
import 'package:family_hub/app/theme/theme_registry.dart';
import 'package:family_hub/core/localization/generated/app_localizations.dart';
import 'package:family_hub/features/bazar/items_categories/domain/catalog_index.dart';
import 'package:family_hub/features/bazar/items_categories/domain/category.dart';
import 'package:family_hub/features/bazar/items_categories/presentation/catalog_providers.dart';
import 'package:family_hub/features/bazar/items_categories/presentation/widgets/categories_tab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('read-only categories are sorted and hidden ones are labelled', (
    tester,
  ) async {
    final categories = CatalogIndex(
      categories: [
        const Category(
          id: 'later',
          nameBn: 'পরেরটি',
          colorIndex: 0,
          sortOrder: 2,
          active: true,
        ),
        const Category(
          id: 'first',
          nameBn: 'প্রথমটি',
          colorIndex: 1,
          sortOrder: 1,
          active: true,
        ),
        const Category(
          id: 'hidden',
          nameBn: 'নিষ্ক্রিয়',
          colorIndex: 2,
          sortOrder: 3,
          active: false,
        ),
      ],
      items: const [],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [catalogIndexProvider.overrideWithValue(categories)],
        child: MaterialApp(
          theme: buildThemeData(defaultLightSpec),
          locale: const Locale('bn'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: CategoriesTab(canManage: false)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final first = tester
        .getTopLeft(find.byKey(const ValueKey('category-first')))
        .dy;
    final later = tester
        .getTopLeft(find.byKey(const ValueKey('category-later')))
        .dy;
    final hidden = tester
        .getTopLeft(find.byKey(const ValueKey('category-hidden')))
        .dy;
    expect(first, lessThan(later));
    expect(later, lessThan(hidden));
    expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
    expect(find.byType(ReorderableDragStartListener), findsNothing);
    final l10n = await AppLocalizations.delegate.load(const Locale('bn'));
    expect(find.text(l10n.catalogHidden), findsOneWidget);
  });
}
