import 'package:family_hub/app/app.dart';
import 'package:family_hub/app/flavor.dart';
import 'package:family_hub/app/theme/theme_controller.dart'
    show sharedPreferencesProvider;
import 'package:family_hub/core/localization/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final flavor in Flavor.values) {
    testWidgets('shows ${flavor.name} flavor name', (tester) async {
      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: FamilyHubApp(flavor: flavor),
        ),
      );
      await tester.pumpAndSettle();
      // The home screen shows the flavor name.
      expect(find.text(flavor.name), findsOneWidget);
      // The app bar title is the localized app name (Bangla by default).
      final l10n = await AppLocalizations.delegate.load(const Locale('bn'));
      expect(find.text(l10n.appName), findsOneWidget);
    });
  }

  test('dev label differs from prod label', () {
    expect(Flavor.dev.label, 'Family Hub (dev)');
    expect(Flavor.prod.label, 'Family Hub');
  });
}
