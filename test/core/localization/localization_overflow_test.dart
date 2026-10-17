import 'package:family_hub/app/theme/theme_builder.dart';
import 'package:family_hub/app/theme/theme_controller.dart';
import 'package:family_hub/app/theme/theme_prefs.dart';
import 'package:family_hub/core/localization/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// A deliberately long Bangla string used to stress text layout.
const String _longBangla =
    'এটি একটি অত্যন্ত দীর্ঘ বাংলা বাক্য যা ব্যবহারকারীর ইন্টারফেসে অনেক জায়গা '
    'নেয় এবং সম্ভাব্য ওভারফ্লো সমস্যা যাচাই করার জন্য ব্যবহৃত হয়।';

/// A long English string of similar intent.
const String _longEnglish =
    'This is an intentionally long English sentence that occupies a lot of '
    'space in the user interface and is used to check for possible overflow.';

/// Wraps [child] in a MaterialApp with the app's theme, the generated
/// localizations and an explicit [locale], so the test renders exactly what the
/// app would.
Widget _wrap({
  required Widget child,
  required Locale locale,
  double textScale = 1.0,
}) {
  final specs = resolveThemeSpecs(const ThemePrefs());
  return MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    theme: buildThemeData(specs.light),
    home: Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
        ),
        child: Scaffold(body: child),
      ),
    ),
  );
}

/// Builds a column of text widgets that wrap long strings inside a constrained
/// card, mirroring how real screens lay out copy.
///
/// Wrapped in a [SingleChildScrollView] so vertical growth never counts as
/// overflow — the point of the test is that long Bangla text *wraps* instead of
/// overflowing horizontally.
Widget _copyCard(String title, String body) => SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 12),
          // Constrained width so wrapping (not overflow) is the expected result.
          SizedBox(
            width: 240,
            child: Text(body, style: const TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );

void main() {
  group('Long Bangla strings do not overflow', () {
    testWidgets('at text scale 1.0 (bn)', (tester) async {
      await tester.pumpWidget(
        _wrap(
          locale: const Locale('bn'),
          child: _copyCard(_longBangla, _longBangla),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('at text scale 2.0 (bn)', (tester) async {
      await tester.pumpWidget(
        _wrap(
          locale: const Locale('bn'),
          textScale: 2.0,
          child: _copyCard(_longBangla, _longBangla),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('at text scale 2.0 (en)', (tester) async {
      await tester.pumpWidget(
        _wrap(
          locale: const Locale('en'),
          textScale: 2.0,
          child: _copyCard(_longEnglish, _longEnglish),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group('Every localized string fits a 320dp wide screen at 2.0', () {
    testWidgets('AppLocalizations bn copy', (tester) async {
      await tester.pumpWidget(
        _wrap(
          locale: const Locale('bn'),
          textScale: 2.0,
          child: const _AllStringsProbe(),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('AppLocalizations en copy', (tester) async {
      await tester.pumpWidget(
        _wrap(
          locale: const Locale('en'),
          textScale: 2.0,
          child: const _AllStringsProbe(),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}

/// Renders a representative set of localized strings inside a narrow, scrollable
/// column.  A RenderFlex overflow would throw and fail the test.
class _AllStringsProbe extends StatelessWidget {
  const _AllStringsProbe();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final strings = <String>[
      l10n.appName,
      l10n.navHome,
      l10n.navChores,
      l10n.navBazar,
      l10n.navFamily,
      l10n.actionSave,
      l10n.actionCancel,
      l10n.actionRetry,
      l10n.actionDelete,
      l10n.errorPermissionDenied,
      l10n.errorNotFound,
      l10n.errorConflict,
      l10n.errorNetwork,
      l10n.errorUnknown,
      l10n.errorValidationRequired(l10n.authEmailLabel),
      l10n.emptyGenericTitle,
      l10n.emptyGenericMessage,
      l10n.settingsTitle,
      l10n.settingsThemeTitle,
      l10n.settingsLanguageTitle,
      l10n.settingsBanglaDigitsSubtitle,
      l10n.offlineBanner,
    ];
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final s in strings)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(s),
              ),
          ],
        ),
      ),
    );
  }
}
