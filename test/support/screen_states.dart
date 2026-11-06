import 'package:family_hub/app/theme/theme_builder.dart';
import 'package:family_hub/app/theme/theme_controller.dart';
import 'package:family_hub/app/theme/theme_registry.dart';
import 'package:family_hub/core/localization/generated/app_localizations.dart';
import 'package:family_hub/shared/widgets/sync_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The states every Phase 1 screen must survive (H11, CLAUDE.md rule 10).
///
/// `offline` (P4-23) is the state where the data has not reached the server:
/// the screen is pumped with the shell's [SyncBanner] visible, so a screen
/// that hides information behind that banner or overflows under it fails here.
enum ScreenState { loading, data, empty, error, offline }

/// Builds the provider overrides that put a screen into [state].
typedef StateOverrides = List<Override> Function(ScreenState state);

/// Builds the same app shell [screenStateTests] pumps - theme, locale, 2x text
/// scaler and the caller's [overrides] - so another test (the P4-23 semantics
/// audit) can walk exactly what the harness lays down.
Future<void> pumpAuditScreen(
  WidgetTester tester, {
  required Widget home,
  AppThemeSpec? spec,
  Locale locale = const Locale('bn'),
  List<Override> overrides = const <Override>[],
  Size surface = const Size(400, 900),
}) async {
  tester.view
    ..physicalSize = surface
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        ...overrides,
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildThemeData(spec ?? appThemes.first),
        locale: locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
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
        home: home,
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 100));
}

/// Pumps [screen] in every [ScreenState] it supports x {modern_light,
/// modern_dark} x {bn, en} at text scale 2.0 and checks that:
///
///  * nothing overflows or throws,
///  * every tap target is >= 48dp (`androidTapTargetGuideline`),
///  * every tap target has a label (`labeledTapTargetGuideline`),
///  * text contrast is sufficient (`textContrastGuideline`),
///  * in [ScreenState.offline] the sync banner is on screen (P4-23).
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
          testWidgets('$state / ${spec.id} / ${locale.languageCode}', (
            tester,
          ) async {
            final semantics = tester.ensureSemantics();
            final offline = state == ScreenState.offline;
            await pumpAuditScreen(
              tester,
              spec: spec,
              locale: locale,
              overrides: overrides?.call(state) ?? const <Override>[],
              // The shell hosts the banner in `bottomNavigationBar`; the
              // offline run copies that so screens are tested as they
              // really sit on a phone.
              home: offline
                  ? Scaffold(
                      body: screen(),
                      bottomNavigationBar: const SyncBanner(
                        pendingWrites: 2,
                        offline: true,
                      ),
                    )
                  : screen(),
            );

            expect(tester.takeException(), isNull, reason: 'overflow or error');
            if (offline) {
              expect(find.byKey(const Key('sync_banner')), findsOneWidget);
            }
            await expectLater(
              tester,
              meetsGuideline(androidTapTargetGuideline),
            );
            await expectLater(
              tester,
              meetsGuideline(labeledTapTargetGuideline),
            );
            await expectLater(tester, meetsGuideline(textContrastGuideline));
            semantics.dispose();
          });
        }
      }
    }
  });
}
