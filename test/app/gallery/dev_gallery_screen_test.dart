import 'package:family_hub/app/gallery/dev_gallery_screen.dart';
import 'package:family_hub/app/gallery/gallery_sections.dart';
import 'package:family_hub/app/routing/app_routes.dart';
import 'package:family_hub/app/theme/theme_builder.dart';
import 'package:family_hub/app/theme/theme_controller.dart'
    show sharedPreferencesProvider;
import 'package:family_hub/app/theme/theme_registry.dart';
import 'package:family_hub/core/localization/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The debug-only component gallery (roadmap Step 11).
void main() {
  test('the gallery is a dev tool, reachable in every phase', () {
    expect(AppRoutes.devGallery, '/dev/gallery');
    expect(AppRoutes.alwaysOpen, contains(AppRoutes.devGallery));
  });

  testWidgets('renders every section of the gallery without errors', (
    tester,
  ) async {
    // Tall viewport so the whole list is laid out (a ListView only builds what
    // fits) and every section heading is found.
    tester.view
      ..physicalSize = const Size(400, 5000)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final l10n = await AppLocalizations.delegate.load(const Locale('bn'));
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
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
          home: const DevGalleryScreen(),
        ),
      ),
    );
    // Not pumpAndSettle: the gallery shows an indeterminate progress ring,
    // which never settles.
    await tester.pump(const Duration(milliseconds: 250));

    for (final section in gallerySections()) {
      expect(
        find.text(section.label(l10n)),
        findsOneWidget,
        reason: 'section ${section.id} is missing from the gallery',
      );
    }
    expect(tester.takeException(), isNull);
  });
}
