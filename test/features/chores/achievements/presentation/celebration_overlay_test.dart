import 'package:family_hub/app/theme/theme_builder.dart';
import 'package:family_hub/app/theme/theme_registry.dart';
import 'package:family_hub/core/localization/generated/app_localizations.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/features/chores/achievements/domain/celebration_state.dart';
import 'package:family_hub/features/chores/achievements/domain/default_engagement_settings.dart';
import 'package:family_hub/features/chores/achievements/presentation/celebration_overlay.dart';
import 'package:family_hub/features/chores/achievements/presentation/painters/confetti_painter.dart';
import 'package:family_hub/shared/widgets/badge_medal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final date = DateKey(2026, 11, 6);
  final settings = defaultEngagementSettings(
    startedOn: DateKey(2026, 11, 1),
    graceMinutes: 30,
  );
  final celebration = CelebrationShown(
    dateKey: date,
    levelBefore: 1,
    levelAfter: 2,
    totalPoints: 250,
    newBadges: const <String>['fresh_start'],
    pointsToday: 36,
  );

  testWidgets('renders localized content, badge and semantics at 2x', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(320, 900)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    for (final locale in const <Locale>[Locale('bn'), Locale('en')]) {
      await tester.pumpWidget(
        _app(
          locale: locale,
          child: CelebrationOverlay(
            celebration: celebration,
            settings: settings,
            formatNumber: (value) => value.toString(),
          ),
          textScale: 2,
        ),
      );
      await tester.pump(const Duration(seconds: 2));
      final l10n = lookupAppLocalizations(locale);

      expect(find.text(l10n.celebrationTitle), findsOneWidget);
      expect(find.text(l10n.celebrationNewBadges), findsOneWidget);
      expect(find.byType(BadgeMedal), findsOneWidget);
      expect(find.bySemanticsLabel(l10n.celebrationSemantics), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('reduced motion is static and keeps all celebration content', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(360, 900)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      _app(
        locale: const Locale('en'),
        child: CelebrationOverlay(
          celebration: celebration,
          settings: settings,
          formatNumber: (value) => value.toString(),
        ),
        textScale: 2,
        reducedMotion: true,
        dark: true,
      ),
    );
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('Today’s chores are complete!'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) => widget is CustomPaint && widget.painter is ConfettiPainter,
      ),
      findsNothing,
    );
    expect(find.byType(BadgeMedal), findsOneWidget);
    expect(tester.binding.transientCallbackCount, 0);
    expect(tester.takeException(), isNull);
  });

  test('confetti particles are capped and seeded deterministically', () {
    final first = ConfettiPainter(
      seed: date.epochDay,
      progress: 0.4,
      colors: const <Color>[Colors.red, Colors.blue],
    );
    final same = ConfettiPainter(
      seed: date.epochDay,
      progress: 0.4,
      colors: const <Color>[Colors.red, Colors.blue],
    );
    final nextFrame = ConfettiPainter(
      seed: date.epochDay,
      progress: 0.5,
      colors: const <Color>[Colors.red, Colors.blue],
    );

    expect(ConfettiPainter.particleCount, lessThanOrEqualTo(80));
    expect(first.shouldRepaint(same), isFalse);
    expect(first.shouldRepaint(nextFrame), isTrue);
  });
}

Widget _app({
  required Locale locale,
  required Widget child,
  required double textScale,
  bool reducedMotion = false,
  bool dark = false,
}) {
  final theme = dark ? modernDarkSpec : modernLightSpec;
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: buildThemeData(theme),
    locale: locale,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
          disableAnimations: reducedMotion,
        ),
        child: Scaffold(body: Center(child: child)),
      ),
    ),
  );
}
