import 'dart:io';

import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:family_hub/app/theme/theme_builder.dart';
import 'package:family_hub/app/theme/theme_controller.dart'
    show sharedPreferencesProvider;
import 'package:family_hub/app/theme/theme_registry.dart';
import 'package:family_hub/core/localization/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Shared harness for the Step 11 widget tests (goldens and overflow).
///
/// The golden test and the overflow test must render a widget *exactly* the way
/// a screen does — same theme, same locale, same text scale — or they prove
/// nothing about the app.  Keeping that setup in one place means the two tests
/// cannot drift apart.

/// The two languages the app ships.  Bangla is the default, so it comes first.
const List<Locale> sharedWidgetLocales = [Locale('bn'), Locale('en')];

/// Capture width: a narrow phone, where layout problems show up first.
const double sharedWidgetWidth = 320;

/// Tall enough that a whole gallery section fits in the viewport, so nothing
/// is clipped out of a golden image.
const double sharedWidgetViewHeight = 2400;

/// Key on the captured subtree, so a golden contains the widget and its
/// background only — not the Scaffold, not the window.
const Key sharedWidgetGoldenKey = ValueKey('shared-widget-golden');

/// How long the pump advances the clock.  A fixed duration keeps every running
/// animation on the same frame in every run.
const Duration sharedWidgetPump = Duration(milliseconds: 250);

/// Loads the bundled Bangla font into the test renderer.
///
/// `flutter test` does **not** load fonts declared in `pubspec.yaml`; without
/// this, Bangla renders as tofu boxes and every golden and overflow assertion
/// measures the wrong glyph widths.
Future<void> loadBundledFonts() async {
  final loader = FontLoader(kAppFontFamily);
  for (final weight in ['Light', 'Regular', 'Medium', 'SemiBold', 'Bold']) {
    loader.addFont(
      File('assets/fonts/HindSiliguri-$weight.ttf')
          .readAsBytes()
          .then((bytes) => ByteData.view(Uint8List.fromList(bytes).buffer)),
    );
  }
  await loader.load();
}

/// Renders [child] exactly as the app would, with a deterministic frame.
///
/// `disableAnimations` is forced on: the skeleton pulse, the indeterminate
/// ring and the pill bar's expansion must not depend on when the frame was
/// taken, or a golden would flake.  The widgets' animated paths are covered by
/// their own widget tests, which pump explicit durations.
Future<void> pumpSharedWidget(
  WidgetTester tester, {
  required Widget child,
  required AppThemeSpec spec,
  required Locale locale,
  double textScale = 1.0,
  double width = sharedWidgetWidth,
}) async {
  tester.view
    ..physicalSize = Size(width, sharedWidgetViewHeight)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  // MoneyText and the progress ring read the active locale through Riverpod,
  // which reads the language preference from SharedPreferences.  In the app
  // bootstrap overrides that provider; here the test does.
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildThemeData(spec),
        locale: locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            final tokens = context.tokens;
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(textScale),
                disableAnimations: true,
              ),
              child: Scaffold(
                backgroundColor: tokens.background,
                body: SingleChildScrollView(
                  child: SizedBox(
                    width: width,
                    child: RepaintBoundary(
                      key: sharedWidgetGoldenKey,
                      child: ColoredBox(
                        color: tokens.background,
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: child,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    ),
  );

  // A fixed advance, never pumpAndSettle: the skeleton and the indeterminate
  // ring never settle, so pumpAndSettle would time out.
  await tester.pump(sharedWidgetPump);
}
