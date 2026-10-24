@Tags(['golden'])
library;

import 'dart:io';

import 'package:family_hub/app/theme/theme_builder.dart';
import 'package:family_hub/app/theme/theme_controller.dart';
import 'package:family_hub/app/theme/theme_registry.dart';
import 'package:family_hub/core/localization/generated/app_localizations.dart';
import 'package:family_hub/features/settings/presentation/language_settings_screen.dart';
import 'package:family_hub/features/settings/presentation/theme_settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../shared/widgets/shared_widgets_test_support.dart';

/// Goldens of the theme and language settings screens in 2 themes x 2
/// languages (H11, Step 4 debt).  Generated on Linux by the Update goldens
/// workflow; skipped with a reason until the images exist.
void main() {
  setUpAll(loadBundledFonts);
  final dir = Directory('test/features/settings/goldens');
  final generated = autoUpdateGoldenFiles || dir.existsSync();

  final screens = <String, Widget>{
    'theme': const ThemeSettingsScreen(),
    'language': const LanguageSettingsScreen(),
  };

  group(
    'settings screens',
    () {
      for (final entry in screens.entries) {
        for (final spec in appThemes) {
          for (final locale in sharedWidgetLocales) {
            testWidgets(
              '${entry.key} golden — ${spec.id} / ${locale.languageCode}',
              (tester) async {
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
                    ],
                    child: MaterialApp(
                      debugShowCheckedModeBanner: false,
                      theme: buildThemeData(spec),
                      locale: locale,
                      localizationsDelegates: const [
                        AppLocalizations.delegate,
                        GlobalMaterialLocalizations.delegate,
                        GlobalWidgetsLocalizations.delegate,
                      ],
                      supportedLocales: AppLocalizations.supportedLocales,
                      builder: (context, child) => MediaQuery(
                        data: MediaQuery.of(context)
                            .copyWith(disableAnimations: true),
                        child: child!,
                      ),
                      home: entry.value,
                    ),
                  ),
                );
                await tester.pump(sharedWidgetPump);
                await expectLater(
                  find.byType(MaterialApp),
                  matchesGoldenFile(
                    'goldens/${entry.key}_${spec.id}_${locale.languageCode}.png',
                  ),
                );
              },
            );
          }
        }
      }
    },
    skip: generated
        ? null
        : 'goldens not generated yet — run the Update goldens workflow',
  );
}
