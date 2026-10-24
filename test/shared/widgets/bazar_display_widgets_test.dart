import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:family_hub/app/theme/theme_builder.dart';
import 'package:family_hub/app/theme/theme_registry.dart';
import 'package:family_hub/core/localization/generated/app_localizations.dart';
import 'package:family_hub/core/utils/money.dart';
import 'package:family_hub/shared/widgets/category_badge.dart';
import 'package:family_hub/shared/widgets/day_section_header.dart';
import 'package:family_hub/shared/widgets/person_picker.dart';
import 'package:family_hub/shared/widgets/progress_bar_status.dart';
import 'package:family_hub/shared/widgets/total_display.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'shared_widgets_test_support.dart';

/// Behaviour of the remaining P2-12 widgets: the total, the budget bar, a day
/// heading, the person picker and the category badge.
void main() {
  setUpAll(loadBundledFonts);

  Future<void> pumpWidgetUnderTest(WidgetTester tester, Widget child) =>
      pumpSharedWidget(
        tester,
        child: child,
        spec: defaultLightSpec,
        locale: const Locale('bn'),
      );

  group('TotalDisplay', () {
    testWidgets('shows a localized dash until an amount exists', (
      tester,
    ) async {
      final l10n = await AppLocalizations.delegate.load(const Locale('bn'));

      await pumpWidgetUnderTest(tester, const TotalDisplay(label: 'মোট'));

      expect(find.text(l10n.totalEmpty), findsOneWidget);
    });

    testWidgets('shows the money and only explains a calculated value', (
      tester,
    ) async {
      final l10n = await AppLocalizations.delegate.load(const Locale('bn'));

      await pumpWidgetUnderTest(
        tester,
        const TotalDisplay(label: 'মোট', total: Money.paisa(125050)),
      );
      expect(find.text('৳১,২৫০.৫০'), findsOneWidget);
      expect(find.text(l10n.totalCalculated), findsNothing);

      await pumpWidgetUnderTest(
        tester,
        const TotalDisplay(
          label: 'মোট',
          total: Money.paisa(125050),
          calculated: true,
        ),
      );
      expect(find.text(l10n.totalCalculated), findsOneWidget);
    });
  });

  group('ProgressBarStatus', () {
    test('clamps basis points into 0…1', () {
      expect(ProgressBarStatus.fractionFor(14000), 1.0);
      expect(ProgressBarStatus.fractionFor(-100), 0.0);
      expect(ProgressBarStatus.fractionFor(null), 0.0);
      expect(ProgressBarStatus.fractionFor(8000), 0.8);
    });

    testWidgets('clamps the fill at 100% and marks the overflow', (
      tester,
    ) async {
      await pumpWidgetUnderTest(
        tester,
        const ProgressBarStatus(
          level: ProgressLevel.exceeded,
          basisPoints: 14000,
          label: 'মাসিক বাজেট',
          trailing: '১৪০%',
        ),
      );

      final width = tester.getSize(find.byType(ProgressBarStatus)).width;
      final fill = tester.getSize(find.byKey(ProgressBarStatus.fillKey));
      expect(fill.width, width);
      expect(find.byKey(ProgressBarStatus.overflowKey), findsOneWidget);
      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
    });

    testWidgets('draws no bar when there is no limit', (tester) async {
      await pumpWidgetUnderTest(
        tester,
        const ProgressBarStatus(
          level: ProgressLevel.ok,
          label: 'কোনো সীমা নেই',
        ),
      );

      expect(find.byKey(ProgressBarStatus.fillKey), findsNothing);
      expect(find.byIcon(Icons.check_circle_outline_rounded), findsOneWidget);
    });

    testWidgets('uses the icon of its level', (tester) async {
      await pumpWidgetUnderTest(
        tester,
        const ProgressBarStatus(
          level: ProgressLevel.warning,
          basisPoints: 8000,
          label: 'মাসিক বাজেট',
        ),
      );

      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });
  });

  testWidgets('DaySectionHeader shows the label and the day total', (
    tester,
  ) async {
    await pumpWidgetUnderTest(
      tester,
      const DaySectionHeader(
        dateLabel: 'সোমবার, ১৯ অক্টোবর ২০২৬',
        total: Money.paisa(125050),
      ),
    );

    expect(find.text('সোমবার, ১৯ অক্টোবর ২০২৬'), findsOneWidget);
    expect(find.text('৳১,২৫০.৫০'), findsOneWidget);
  });

  group('PersonPicker', () {
    testWidgets('reports the chosen person', (tester) async {
      String? picked;

      await pumpWidgetUnderTest(
        tester,
        PersonPicker(
          label: 'কে টাকা দিয়েছে',
          options: const [
            PersonOption(id: 'usr_a', name: 'Ayesha'),
            PersonOption(id: 'usr_b', name: 'Bashir'),
          ],
          onChanged: (id) => picked = id,
        ),
      );

      await tester.tap(find.text('Bashir'));
      await tester.pump();

      expect(picked, 'usr_b');
    });

    testWidgets('the none target reports null', (tester) async {
      final l10n = await AppLocalizations.delegate.load(const Locale('bn'));
      var calls = 0;
      String? picked = 'not-called';

      await pumpWidgetUnderTest(
        tester,
        PersonPicker(
          label: 'কে টাকা দিয়েছে',
          options: const [PersonOption(id: 'usr_a', name: 'Ayesha')],
          selectedId: 'usr_a',
          allowNone: true,
          onChanged: (id) {
            calls++;
            picked = id;
          },
        ),
      );

      await tester.tap(find.text(l10n.personPickerNone));
      await tester.pump();

      expect(calls, 1);
      expect(picked, isNull);
    });

    testWidgets('announces each person once', (tester) async {
      final handle = tester.ensureSemantics();

      await pumpWidgetUnderTest(
        tester,
        PersonPicker(
          label: 'কে টাকা দিয়েছে',
          options: const [PersonOption(id: 'usr_a', name: 'Ayesha')],
          onChanged: (id) {},
        ),
      );

      expect(find.bySemanticsLabel('Ayesha'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('scrolls sideways with twelve options', (tester) async {
      await pumpWidgetUnderTest(
        tester,
        PersonPicker(
          label: 'কে টাকা দিয়েছে',
          options: [
            for (var index = 0; index < 12; index++)
              PersonOption(id: 'usr_$index', name: 'Person $index'),
          ],
          selectedId: 'usr_11',
          onChanged: (id) {},
        ),
      );

      await tester.drag(
        find.descendant(
          of: find.byType(PersonPicker),
          matching: find.byType(SingleChildScrollView),
        ),
        const Offset(-240, 0),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('Person 11'), findsOneWidget);
    });
  });

  group('CategoryBadge', () {
    testWidgets('paints the palette colour for its index', (tester) async {
      final tokens = buildThemeData(defaultLightSpec).extension<AppTokens>()!;

      await pumpWidgetUnderTest(
        tester,
        const CategoryBadge(name: 'সবজি', colorIndex: 3, emoji: '🥬'),
      );

      expect(find.text('সবজি'), findsOneWidget);
      expect(find.text('🥬'), findsOneWidget);

      final container = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(CategoryBadge),
              matching: find.byType(Container),
            )
            .first,
      );
      final decoration = container.decoration! as BoxDecoration;
      expect(decoration.color, tokens.placeholderPalette[3]);
    });

    testWidgets('compact is smaller than the default size', (tester) async {
      await pumpWidgetUnderTest(
        tester,
        const CategoryBadge(name: 'সবজি', colorIndex: 3),
      );
      final normal = tester.getSize(find.byType(CategoryBadge));

      await pumpWidgetUnderTest(
        tester,
        const CategoryBadge(name: 'সবজি', colorIndex: 3, compact: true),
      );
      final compact = tester.getSize(find.byType(CategoryBadge));

      expect(compact.height, lessThan(normal.height));
    });
  });
}
