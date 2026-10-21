import 'package:family_hub/app/theme/theme_builder.dart';
import 'package:family_hub/app/theme/theme_controller.dart';
import 'package:family_hub/app/theme/theme_registry.dart';
import 'package:family_hub/app/theme/themes/modern_light.dart';
import 'package:family_hub/core/localization/generated/app_localizations.dart';
import 'package:family_hub/features/settings/presentation/theme_settings_screen.dart';
import 'package:family_hub/features/settings/presentation/widgets/theme_settings_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A host that rebuilds the theme like `FamilyHubApp` does.
class _Host extends ConsumerWidget {
  const _Host({this.specs});
  final List<AppThemeSpec>? specs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(themeControllerProvider);
    final spec = themeById(prefs.themeId);
    return MaterialApp(
      theme: buildThemeData(spec),
      themeMode: ThemeMode.light,
      locale: const Locale('en'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: ThemeSettingsScreen(specs: specs),
    );
  }
}

Future<void> _pumpHost(WidgetTester tester, {List<AppThemeSpec>? specs}) async {
  tester.view
    ..physicalSize = const Size(400, 900)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({
    'theme_mode': 'light',
    'theme_id': 'modern_light',
  });
  final prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: _Host(specs: specs),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('one card per available theme', (tester) async {
    await _pumpHost(tester);
    expect(
      find.byType(ThemeCard),
      findsNWidgets(appThemes.where((s) => s.available).length),
    );
  });

  testWidgets('tapping the dark card changes the scaffold background',
      (tester) async {
    await _pumpHost(tester);
    Color? bg() => tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor;
    expect(bg(), modernLightSpec.tokens.background);

    await tester.tap(find.text('Modern Dark'));
    await tester.pump();
    await tester.pumpAndSettle();
    expect(bg(), modernDarkSpec.tokens.background);
  });

  testWidgets('the selected card shows a check icon, not colour alone',
      (tester) async {
    await _pumpHost(tester);
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
  });

  testWidgets('a third registered theme appears with no screen change',
      (tester) async {
    final third = AppThemeSpec(
      id: 'test_third',
      labelBn: '',
      labelEn: 'Third',
      brightness: Brightness.light,
      tokens: modernLightTokens,
    );
    await _pumpHost(tester, specs: [...appThemes, third]);
    expect(find.byType(ThemeCard), findsNWidgets(appThemes.length + 1));
    expect(find.text('Third'), findsOneWidget);
  });
}
