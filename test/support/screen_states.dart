import 'package:family_hub/app/theme/theme_builder.dart';
import 'package:family_hub/app/theme/theme_controller.dart';
import 'package:family_hub/app/theme/theme_registry.dart';
import 'package:family_hub/core/localization/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The states every Phase 1 screen must survive (H11, CLAUDE.md rule 10).
enum ScreenState { loading, data, empty, error }

/// Builds the provider overrides that put a screen into [state].
typedef StateOverrides = List<Override> Function(ScreenState state);

/// Pumps [screen] in every [ScreenState] it supports x {modern_light,
/// modern_dark} x {bn, en} at text scale 2.0 and checks that:
///
///  * nothing overflows or throws,
///  * every tap target is >= 48dp (`androidTapTargetGuideline`),
///  * every tap target has a label (`labeledTapTargetGuideline`),
///  * text contrast is sufficient (`textContrastGuideline`).
///
/// The "no hard-coded user-visible strings" rule is enforced separately by the
/// existing l10n guard test, which scans `lib/` once for all screens.
void screenStateTests(
  String name,
  Widget Function() screen, {
  StateOverrides? overrides,
  Set<ScreenState> states = const {ScreenState.data},
}) {
  group(name, () {
    for (final state in states) {
      for (final spec in appThemes.where((s) => s.available)) {
        for (final locale in AppLocalizations.supportedLocales) {
          testWidgets('$state / ${spec.id} / ${locale.languageCode}',
              (tester) async {
            final semantics = tester.ensureSemantics();
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
                  ...?overrides?.call(state),
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
                    data: MediaQuery.of(context).copyWith(
                      textScaler: const TextScaler.linear(2),
                      disableAnimations: true,
                    ),
                    child: child!,
                  ),
                  home: screen(),
                ),
              ),
            );
            await tester.pump(const Duration(milliseconds: 100));

            expect(tester.takeException(), isNull, reason: 'overflow or error');
            await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
            await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
            await expectLater(tester, meetsGuideline(textContrastGuideline));
            semantics.dispose();
          });
        }
      }
    }
  });
}
