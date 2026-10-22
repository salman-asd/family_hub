import 'package:family_hub/app/theme/theme_builder.dart';
import 'package:family_hub/app/theme/theme_registry.dart';
import 'package:family_hub/core/localization/generated/app_localizations.dart';
import 'package:family_hub/shared/widgets/loading_view.dart';
import 'package:family_hub/shared/widgets/pill_bottom_bar.dart';
import 'package:family_hub/shared/widgets/progress_ring.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:family_hub/app/theme/theme_controller.dart'
    show sharedPreferencesProvider;

/// H11: every animated shared widget honours `MediaQuery.disableAnimations`.
/// With reduced motion the widget schedules no frames of its own; without it,
/// the same widget does (so the test cannot pass by never animating at all).
Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  required bool reduceMotion,
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: MaterialApp(
        theme: buildThemeData(appThemes.first),
        locale: const Locale('en'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, app) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(disableAnimations: reduceMotion),
          child: app!,
        ),
        home: Scaffold(body: child),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  group('LoadingView', () {
    testWidgets('does not pulse with reduced motion', (tester) async {
      await _pump(tester, const LoadingView(), reduceMotion: true);
      expect(tester.binding.transientCallbackCount, 0);
    });
    testWidgets('pulses without it', (tester) async {
      await _pump(tester, const LoadingView(), reduceMotion: false);
      expect(tester.binding.transientCallbackCount, greaterThan(0));
    });
  });

  group('ProgressRing', () {
    testWidgets('an indeterminate ring is static with reduced motion', (
      tester,
    ) async {
      await _pump(tester, const ProgressRing(), reduceMotion: true);
      expect(tester.binding.transientCallbackCount, 0);
    });
    testWidgets('an indeterminate ring spins without it', (tester) async {
      await _pump(tester, const ProgressRing(), reduceMotion: false);
      expect(tester.binding.transientCallbackCount, greaterThan(0));
    });
  });

  group('PillBottomBar', () {
    const items = <PillNavItem>[
      PillNavItem(key: Key('a'), icon: Icons.home_outlined, label: 'Home'),
      PillNavItem(key: Key('b'), icon: Icons.groups_outlined, label: 'Family'),
    ];
    testWidgets('switching tabs does not animate with reduced motion', (
      tester,
    ) async {
      var selected = 0;
      await _pump(
        tester,
        StatefulBuilder(
          builder: (context, setState) => PillBottomBar(
            items: items,
            selectedIndex: selected,
            onSelected: (i) => setState(() => selected = i),
          ),
        ),
        reduceMotion: true,
      );
      await tester.tap(find.byKey(const Key('b')));
      await tester.pump();
      expect(tester.binding.transientCallbackCount, 0);
    });
  });
}
