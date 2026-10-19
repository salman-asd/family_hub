@Tags(['golden'])
library;

import 'dart:io';

import 'package:family_hub/app/theme/theme_builder.dart';
import 'package:family_hub/app/theme/theme_registry.dart';
import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/localization/generated/app_localizations.dart';
import 'package:family_hub/features/auth/presentation/auth_providers.dart';
import 'package:family_hub/features/auth/presentation/screens/login_screen.dart';
import 'package:family_hub/features/auth/presentation/screens/welcome_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/fake_auth_repository.dart';

// Golden tests for the auth screens.
//
// The roadmap asks for "golden tests of Login in light/dark x bn".  They are
// written as a loop over the registered theme specs and the two locales, so
// a third theme or locale is picked up automatically without touching this
// file - the same "registry drives the screen" rule the theme tests follow.
//
// Regenerate deliberately with:
//   flutter test --update-goldens test/features/auth/presentation/screens
// and review the image diff before committing.

/// Loads the bundled Bangla font into the test renderer.
///
/// `flutter test` does **not** load fonts declared in `pubspec.yaml`; without
/// this, Bangla renders as tofu boxes and every golden would be worthless (and
/// every "no overflow" assertion would be measuring the wrong glyph widths).
/// See https://flutter.dev/to/answer/golden-fonts.
Future<void> loadBundledFonts() async {
  final loader = FontLoader(kAppFontFamily);
  for (final weight in ['Light', 'Regular', 'Medium', 'SemiBold', 'Bold']) {
    loader.addFont(
      File('assets/fonts/HindSiliguri-$weight.ttf').readAsBytes().then(
            (bytes) => ByteData.view(Uint8List.fromList(bytes).buffer),
          ),
    );
  }
  await loader.load();
}

void main() {
  late FakeAuthRepository repository;

  setUpAll(loadBundledFonts);
  setUp(() => repository = FakeAuthRepository());
  tearDown(() => repository.dispose());

  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    required AppThemeSpec spec,
    required Locale locale,
  }) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(
          theme: buildThemeData(spec),
          locale: locale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: child,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// One golden per theme x locale, named `login_<themeId>_<locale>.png`.
  for (final spec in appThemes) {
    for (final locale in const [Locale('bn'), Locale('en')]) {
      testWidgets(
        'login golden — ${spec.id} / ${locale.languageCode}',
        (tester) async {
          await pump(
            tester,
            const LoginScreen(),
            spec: spec,
            locale: locale,
          );

          await expectLater(
            find.byType(MaterialApp),
            matchesGoldenFile(
              'goldens/login_${spec.id}_${locale.languageCode}.png',
            ),
          );
        },
      );
    }
  }

  // The error state is the most layout-sensitive one (two extra text blocks),
  // so it gets its own golden on the default light theme in Bangla.
  testWidgets('login golden — failure state (bn, light)', (tester) async {
    repository.signInFailure = const InvalidCredentials();

    await pump(
      tester,
      const LoginScreen(),
      spec: defaultLightSpec,
      locale: const Locale('bn'),
    );

    await tester.enterText(find.byType(TextField).first, 'a@b.co');
    await tester.enterText(find.byType(TextField).last, 'longenough');
    await tester.pump();

    final l10n = await AppLocalizations.delegate.load(const Locale('bn'));
    await tester.tap(find.widgetWithText(FilledButton, l10n.authSignInAction));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/login_error_bn_light.png'),
    );
  });

  testWidgets('welcome golden — light / bn', (tester) async {
    await pump(
      tester,
      const WelcomeScreen(),
      spec: defaultLightSpec,
      locale: const Locale('bn'),
    );

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/welcome_light_bn.png'),
    );
  });
}
