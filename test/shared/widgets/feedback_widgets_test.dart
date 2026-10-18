import 'dart:ui' as ui;

import 'package:family_hub/app/theme/theme_builder.dart';
import 'package:family_hub/app/theme/theme_controller.dart'
    show sharedPreferencesProvider;
import 'package:family_hub/app/theme/theme_registry.dart';
import 'package:family_hub/core/localization/generated/app_localizations.dart';
import 'package:family_hub/core/utils/money.dart';
import 'package:family_hub/shared/widgets/app_avatar.dart';
import 'package:family_hub/shared/widgets/error_view.dart';
import 'package:family_hub/shared/widgets/item_thumb.dart';
import 'package:family_hub/shared/widgets/loading_view.dart';
import 'package:family_hub/shared/widgets/money_text.dart';
import 'package:family_hub/shared/widgets/progress_ring.dart';
import 'package:family_hub/shared/widgets/status_chip.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Behaviour of the shared widgets added in Step 11: the loading skeleton, the
/// error state and the progress ring — plus the details of the widgets that
/// existed already but only became testable here (image fallbacks, one
/// announcement per widget).
///
/// Goldens prove the *look*; these tests prove the *rules*.

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  Locale locale = const Locale('en'),
  AppThemeSpec? spec,
  bool reduceMotion = false,
  double textScale = 1,
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: MaterialApp(
        theme: buildThemeData(spec ?? defaultLightSpec),
        locale: locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
            disableAnimations: reduceMotion,
          ),
          child: child!,
        ),
        home: Scaffold(body: child),
      ),
    ),
  );
}

/// Counts the placeholder shapes [LoadingView] draws (bars plus avatar).
int _skeletons(WidgetTester tester) => tester
    .widgetList(
      find.descendant(
        of: find.byType(LoadingView),
        matching: find.byType(Container),
      ),
    )
    .length;

/// An [ImageProvider] that completes with one already-decoded image, so the
/// "image is present" path can be tested without any network or codec timing.
class _SyncImageProvider extends ImageProvider<_SyncImageProvider> {
  const _SyncImageProvider(this.image);

  final ui.Image image;

  @override
  Future<_SyncImageProvider> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture<_SyncImageProvider>(this);

  @override
  ImageStreamCompleter loadImage(
    _SyncImageProvider key,
    ImageDecoderCallback decode,
  ) =>
      OneFrameImageStreamCompleter(
        SynchronousFuture<ImageInfo>(ImageInfo(image: image)),
      );
}

void main() {
  group('LoadingView', () {
    testWidgets('is announced once, with the localized loading label',
        (tester) async {
      final handle = tester.ensureSemantics();
      final l10n = await AppLocalizations.delegate.load(const Locale('bn'));

      await _pump(tester, const LoadingView(), locale: const Locale('bn'));

      expect(find.bySemanticsLabel(l10n.loadingSemantics), findsOneWidget);
      handle.dispose();
    });

    testWidgets('accepts a caller-supplied label', (tester) async {
      final handle = tester.ensureSemantics();

      await _pump(tester, const LoadingView(semanticLabel: 'Members'));

      expect(find.bySemanticsLabel('Members'), findsOneWidget);
      expect(find.bySemanticsLabel('Loading'), findsNothing);
      handle.dispose();
    });

    testWidgets('draws one bar per line, plus an avatar when asked',
        (tester) async {
      await _pump(tester, const LoadingView(lines: 5), reduceMotion: true);
      expect(_skeletons(tester), 5);

      await _pump(
        tester,
        const LoadingView(lines: 2, showAvatar: true),
        reduceMotion: true,
      );
      expect(_skeletons(tester), 3);
    });

    testWidgets('pulses when motion is allowed, and holds one frame when not',
        (tester) async {
      final opacity = find.descendant(
        of: find.byType(LoadingView),
        matching: find.byType(Opacity),
      );

      await _pump(tester, const LoadingView());
      final first = tester.widget<Opacity>(opacity).opacity;
      await tester.pump(const Duration(milliseconds: 200));
      final second = tester.widget<Opacity>(opacity).opacity;
      expect(second, isNot(first), reason: 'the skeleton should pulse');

      await _pump(tester, const LoadingView(), reduceMotion: true);
      expect(opacity, findsNothing, reason: 'reduced motion draws one frame');
    });

    testWidgets('works inside an unbounded parent', (tester) async {
      // A horizontal list gives the skeleton unbounded width; it must still
      // lay out (with its fallback width) instead of asserting.
      await _pump(
        tester,
        const SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: LoadingView(lines: 1, showAvatar: true),
        ),
        reduceMotion: true,
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('ErrorView', () {
    testWidgets('headings and message are localized', (tester) async {
      final l10n = await AppLocalizations.delegate.load(const Locale('bn'));

      await _pump(
        tester,
        ErrorView(message: l10n.errorNetwork, onRetry: () {}),
        locale: const Locale('bn'),
      );

      expect(find.text(l10n.errorViewTitle), findsOneWidget);
      expect(find.text(l10n.errorNetwork), findsOneWidget);
      expect(find.text(l10n.actionRetry), findsOneWidget);
    });

    testWidgets('retry calls back exactly once', (tester) async {
      var taps = 0;
      await _pump(
        tester,
        ErrorView(message: 'boom', onRetry: () => taps++),
      );

      await tester.tap(find.byType(FilledButton));
      await tester.pump();

      expect(taps, 1);
    });

    testWidgets('a permanent failure shows no button', (tester) async {
      await _pump(tester, const ErrorView(message: 'not allowed'));

      expect(find.byType(FilledButton), findsNothing);
      expect(find.text('not allowed'), findsOneWidget);
    });

    testWidgets('a caller can override the heading', (tester) async {
      await _pump(
        tester,
        const ErrorView(message: 'boom', title: 'Import failed'),
      );

      expect(find.text('Import failed'), findsOneWidget);
      expect(find.text('boom'), findsOneWidget);
    });
  });

  group('ProgressRing', () {
    testWidgets('clamps the value into 0..1', (tester) async {
      await _pump(tester, const ProgressRing(value: 1.5));
      expect(
        tester
            .widget<CircularProgressIndicator>(
              find.byType(CircularProgressIndicator),
            )
            .value,
        1.0,
      );

      await _pump(tester, const ProgressRing(value: -0.5));
      expect(
        tester
            .widget<CircularProgressIndicator>(
              find.byType(CircularProgressIndicator),
            )
            .value,
        0.0,
      );
    });

    testWidgets('is indeterminate when no value is given', (tester) async {
      await _pump(tester, const ProgressRing());

      expect(
        tester
            .widget<CircularProgressIndicator>(
              find.byType(CircularProgressIndicator),
            )
            .value,
        isNull,
      );
    });

    testWidgets('draws a centre child', (tester) async {
      await _pump(
        tester,
        const ProgressRing(value: 0.5, center: Text('৫০')),
      );

      expect(find.text('৫০'), findsOneWidget);
    });

    testWidgets('a semantic label replaces the platform announcement',
        (tester) async {
      final handle = tester.ensureSemantics();

      await _pump(
        tester,
        const ProgressRing(value: 0.5, semanticLabel: 'Half done'),
      );

      expect(find.bySemanticsLabel('Half done'), findsOneWidget);
      handle.dispose();
    });
  });

  group('AppAvatar', () {
    test('the same id always resolves to the same colour', () {
      expect(AppAvatar.colorIndex('usr_1'), AppAvatar.colorIndex('usr_1'));
      expect(AppAvatar.colorIndex('usr_1'), lessThan(12));
      expect(AppAvatar.colorIndex('usr_1'), greaterThanOrEqualTo(0));
    });

    test('a preset key wins over the id', () {
      expect(AppAvatar.presetIndex('p3'), 3);
      expect(AppAvatar.colorIndex('usr_1', avatarKey: 'p3'), 3);
    });

    test('an unknown preset key falls back to the id', () {
      expect(AppAvatar.presetIndex('p99'), isNull);
      expect(AppAvatar.presetIndex('nope'), isNull);
      expect(
        AppAvatar.colorIndex('usr_1', avatarKey: 'p99'),
        AppAvatar.colorIndex('usr_1'),
      );
    });

    testWidgets('shows the first grapheme cluster of a Bangla name',
        (tester) async {
      await _pump(tester, const AppAvatar(id: 'usr_1', name: 'করিম'));

      expect(find.text('ক'), findsOneWidget);
    });

    testWidgets('a failed image load keeps the initials and reports nothing',
        (tester) async {
      await _pump(
        tester,
        const AppAvatar(
          id: 'usr_1',
          name: 'Karim',
          imageUrl: 'https://invalid.invalid/a.png',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('K'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('paints a supplied image over the initials', (tester) async {
      // createTestImage talks to the engine, so it has to run outside the fake
      // async zone the widget tests use.
      final image = await tester.runAsync(
        () => createTestImage(width: 4, height: 4),
      );
      if (image == null) fail('createTestImage returned null');

      await _pump(
        tester,
        AppAvatar(
          id: 'usr_1',
          name: 'Karim',
          imageProvider: _SyncImageProvider(image),
        ),
      );
      await tester.pump();

      expect(find.byType(Image), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('is announced with its label when one is given',
        (tester) async {
      final handle = tester.ensureSemantics();

      await _pump(
        tester,
        const AppAvatar(id: 'usr_1', name: 'Karim', semanticLabel: 'Karim'),
      );

      expect(find.bySemanticsLabel('Karim'), findsOneWidget);
      handle.dispose();
    });
  });

  group('ItemThumb', () {
    testWidgets('falls back to the item initial when no image loads',
        (tester) async {
      await _pump(
        tester,
        const ItemThumb(
          id: 'item_potato',
          name: 'Potato',
          imageUrl: 'https://invalid.invalid/p.png',
          categoryImageUrl: 'https://invalid.invalid/c.png',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('P'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('paints a supplied image', (tester) async {
      final image = await tester.runAsync(
        () => createTestImage(width: 4, height: 4),
      );
      if (image == null) fail('createTestImage returned null');

      await _pump(
        tester,
        ItemThumb(
          id: 'item_potato',
          name: 'আলু',
          imageProvider: _SyncImageProvider(image),
        ),
      );
      await tester.pump();

      expect(find.byType(Image), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('StatusChip', () {
    testWidgets('uses the localized label for its status', (tester) async {
      final l10n = await AppLocalizations.delegate.load(const Locale('bn'));

      await _pump(
        tester,
        const StatusChip(status: WidgetStatus.overdue),
        locale: const Locale('bn'),
      );

      expect(find.text(l10n.statusOverdue), findsOneWidget);
    });

    testWidgets('a caller-supplied label wins', (tester) async {
      await _pump(
        tester,
        const StatusChip(status: WidgetStatus.completed, label: '2 of 3'),
      );

      expect(find.text('2 of 3'), findsOneWidget);
    });

    testWidgets('compact is smaller than the default size', (tester) async {
      await _pump(tester, const StatusChip(status: WidgetStatus.scheduled));
      final normal = tester.getSize(find.byType(StatusChip));

      await _pump(
        tester,
        const StatusChip(status: WidgetStatus.scheduled, compact: true),
      );
      final compact = tester.getSize(find.byType(StatusChip));

      expect(compact.height, lessThan(normal.height));
    });

    testWidgets('is announced once, with its label', (tester) async {
      final handle = tester.ensureSemantics();

      await _pump(tester, const StatusChip(status: WidgetStatus.completed));

      expect(find.bySemanticsLabel('Completed'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('renders in every registered theme', (tester) async {
      for (final spec in appThemes) {
        await _pump(
          tester,
          const StatusChip(status: WidgetStatus.verified),
          spec: spec,
        );
        expect(tester.takeException(), isNull, reason: spec.id);
      }
    });
  });

  group('MoneyText', () {
    testWidgets('is announced once, with its label', (tester) async {
      final handle = tester.ensureSemantics();

      await _pump(
        tester,
        const MoneyText(
          value: Money.paisa(125050),
          semanticsLabel: 'Total',
        ),
      );

      expect(find.bySemanticsLabel('Total'), findsOneWidget);
      handle.dispose();
    });
  });
}
