import 'package:family_hub/app/theme/theme_registry.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/core/utils/money.dart';
import 'package:family_hub/shared/widgets/amount_field.dart';
import 'package:family_hub/shared/widgets/category_badge.dart';
import 'package:family_hub/shared/widgets/day_section_header.dart';
import 'package:family_hub/shared/widgets/month_switcher.dart';
import 'package:family_hub/shared/widgets/person_picker.dart';
import 'package:family_hub/shared/widgets/progress_bar_status.dart';
import 'package:family_hub/shared/widgets/total_display.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'shared_widgets_test_support.dart';

/// Behaviour of the P2-12 widgets.  Look (goldens) and fit (200 % overflow) are
/// covered by the gallery tests, because each widget is listed there.
void main() {
  setUpAll(loadBundledFonts);

  Future<void> pump(WidgetTester tester, Widget child, {String lang = 'en'}) =>
      pumpSharedWidget(
        tester,
        child: child,
        spec: appThemes.first,
        locale: Locale(lang),
      );

  group('MonthSwitcher', () {
    testWidgets('arrows step one month, across a year boundary', (
      tester,
    ) async {
      MonthKey? picked;
      await pump(
        tester,
        MonthSwitcher(month: MonthKey(2026, 1), onChanged: (m) => picked = m),
      );
      await tester.tap(find.byIcon(Icons.chevron_left_rounded));
      expect(picked, MonthKey(2025, 12));
      await tester.tap(find.byIcon(Icons.chevron_right_rounded));
      expect(picked, MonthKey(2026, 2));
    });

    testWidgets('the arrow that would leave [min, max] is disabled', (
      tester,
    ) async {
      var calls = 0;
      await pump(
        tester,
        MonthSwitcher(
          month: MonthKey(2026, 10),
          min: MonthKey(2026, 10),
          max: MonthKey(2026, 10),
          onChanged: (_) => calls++,
        ),
      );
      await tester.tap(find.byIcon(Icons.chevron_left_rounded));
      await tester.tap(find.byIcon(Icons.chevron_right_rounded));
      expect(calls, 0);
    });

    testWidgets('tapping the label opens a picker and returns the month', (
      tester,
    ) async {
      MonthKey? picked;
      await pump(
        tester,
        MonthSwitcher(
          month: MonthKey(2026, 10),
          max: MonthKey(2026, 12),
          onChanged: (m) => picked = m,
        ),
      );
      await tester.tap(find.byType(InkWell).first);
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(ChoiceChip), findsNWidgets(12));

      // A month after [max] cannot be chosen; March can.
      final chips = tester.widgetList<ChoiceChip>(find.byType(ChoiceChip));
      expect(chips.elementAt(11).onSelected, isNotNull); // December
      await tester.tap(find.byType(ChoiceChip).at(2));
      await tester.pump(const Duration(milliseconds: 400));
      expect(picked, MonthKey(2026, 3));
    });

    testWidgets('the picker disables months outside the range', (
      tester,
    ) async {
      await pump(
        tester,
        MonthSwitcher(
          month: MonthKey(2026, 10),
          min: MonthKey(2026, 8),
          max: MonthKey(2026, 11),
          onChanged: (_) {},
        ),
      );
      await tester.tap(find.byType(InkWell).first);
      await tester.pump(const Duration(milliseconds: 400));
      final chips = tester
          .widgetList<ChoiceChip>(find.byType(ChoiceChip))
          .toList();
      expect(chips[6].onSelected, isNull); // July
      expect(chips[7].onSelected, isNotNull); // August
      expect(chips[10].onSelected, isNotNull); // November
      expect(chips[11].onSelected, isNull); // December
    });
  });

  group('AmountInputFormatter', () {
    TextEditingValue run(AmountInputFormatter f, String from, String to) =>
        f.formatEditUpdate(
          TextEditingValue(text: from),
          TextEditingValue(
            text: to,
            selection: TextSelection.collapsed(offset: to.length),
          ),
        );

    test('accepts English and Bangla digits with one decimal point', () {
      const f = AmountInputFormatter(2);
      expect(run(f, '', '123.50').text, '123.50');
      expect(run(f, '', '১২৩.৫০').text, '১২৩.৫০');
      expect(run(f, '', '.5').text, '.5');
    });

    test('refuses letters, a second point and too many decimals', () {
      const f = AmountInputFormatter(2);
      expect(run(f, '12', '12a').text, '12');
      expect(run(f, '1.2', '1.2.').text, '1.2');
      expect(run(f, '1.25', '1.256').text, '1.25');
      expect(run(f, '5', '-5').text, '5');
    });

    test('quantities allow three decimals, whole numbers none', () {
      expect(run(const AmountInputFormatter(3), '1.50', '1.505').text, '1.505');
      expect(run(const AmountInputFormatter(0), '15', '15.').text, '15');
    });

    test('a comma typed as the separator becomes a point', () {
      expect(run(const AmountInputFormatter(2), '12', '12,5').text, '12.5');
    });
  });

  group('AmountField', () {
    testWidgets('types Bangla digits, shows the taka prefix and the error', (
      tester,
    ) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      String? last;
      await pump(
        tester,
        AmountField(
          controller: controller,
          label: 'Amount',
          errorText: 'Too much',
          onChanged: (v) => last = v,
        ),
      );
      await tester.enterText(find.byType(TextField), '১২৩.৫০');
      expect(controller.text, '১২৩.৫০');
      expect(last, '১২৩.৫০');
      expect(find.text('Too much'), findsOneWidget);
      expect(find.textContaining('৳'), findsOneWidget);
    });

    testWidgets('a quantity field has no taka prefix', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await pump(
        tester,
        AmountField(controller: controller, label: 'Qty', scale: 3),
      );
      expect(find.textContaining('৳'), findsNothing);
    });

    testWidgets('junk keystrokes never reach the controller', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await pump(tester, AmountField(controller: controller, label: 'Amount'));
      await tester.enterText(find.byType(TextField), 'abc');
      expect(controller.text, isEmpty);
      await tester.enterText(find.byType(TextField), '12.345');
      expect(controller.text, isEmpty); // the whole entry was refused
    });
  });

  group('TotalDisplay', () {
    testWidgets('no total shows a dash, never zero', (tester) async {
      await pump(tester, const TotalDisplay(total: null, label: 'Total'));
      expect(find.text('—'), findsOneWidget);
      expect(find.textContaining('0'), findsNothing);
    });

    testWidgets('the calculated note only shows with a value', (tester) async {
      await pump(
        tester,
        const TotalDisplay(
          total: Money.paisa(5000),
          label: 'Total',
          calculated: true,
        ),
      );
      expect(find.textContaining('quantity'), findsOneWidget);
      await pump(
        tester,
        const TotalDisplay(total: null, label: 'Total', calculated: true),
      );
      expect(find.textContaining('quantity'), findsNothing);
    });
  });

  group('ProgressBarStatus', () {
    testWidgets('level is an icon and a word, not just a colour', (
      tester,
    ) async {
      Future<void> check(ProgressLevel level, IconData icon, String word) async {
        await pump(
          tester,
          ProgressBarStatus(basisPoints: 9000, level: level, label: 'Fish'),
        );
        expect(find.byIcon(icon), findsOneWidget);
        expect(find.textContaining(word), findsOneWidget);
      }

      await check(ProgressLevel.ok, Icons.check_circle_outline_rounded, 'On');
      await check(ProgressLevel.warning, Icons.warning_amber_rounded, 'Near');
      await check(ProgressLevel.exceeded, Icons.error_outline_rounded, 'Over');
    });

    testWidgets('no limit draws an empty track and says so', (tester) async {
      await pump(
        tester,
        const ProgressBarStatus(
          basisPoints: null,
          level: ProgressLevel.ok,
          label: 'Fish',
        ),
      );
      expect(find.textContaining('No limit'), findsOneWidget);
      final fill = tester.widget<FractionallySizedBox>(
        find.byType(FractionallySizedBox),
      );
      expect(fill.widthFactor, 0);
    });

    testWidgets('the bar stops at 100 % when the value passes the limit', (
      tester,
    ) async {
      await pump(
        tester,
        const ProgressBarStatus(
          basisPoints: 14000,
          level: ProgressLevel.exceeded,
          label: 'Fish',
        ),
      );
      final fill = tester.widget<FractionallySizedBox>(
        find.byType(FractionallySizedBox),
      );
      expect(fill.widthFactor, 1);
    });

    testWidgets('is announced once, with label, percent and level', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pump(
        tester,
        const ProgressBarStatus(
          basisPoints: 8000,
          level: ProgressLevel.warning,
          label: 'Fish',
        ),
      );
      expect(
        find.bySemanticsLabel(RegExp('Fish.*Nearing the limit')),
        findsOneWidget,
      );
      handle.dispose();
    });
  });

  group('DaySectionHeader', () {
    testWidgets('shows the date and the day total', (tester) async {
      await pump(
        tester,
        const DaySectionHeader(
          dateLabel: 'Sat 17 Oct',
          total: Money.paisa(85000),
        ),
      );
      expect(find.text('Sat 17 Oct'), findsOneWidget);
      expect(find.byType(DaySectionHeader), findsOneWidget);
    });
  });

  group('PersonPicker', () {
    const people = [
      PersonOption(id: 'a', name: 'Alice'),
      PersonOption(id: 'b', name: 'Bob'),
    ];

    testWidgets('choosing a person reports its id', (tester) async {
      String? chosen = 'unset';
      await pump(
        tester,
        PersonPicker(
          options: people,
          selectedId: null,
          onChanged: (id) => chosen = id,
          label: 'Paid by',
        ),
      );
      await tester.tap(find.text('Bob'));
      expect(chosen, 'b');
    });

    testWidgets('the selected person gets a check mark', (tester) async {
      await pump(
        tester,
        PersonPicker(
          options: people,
          selectedId: 'a',
          onChanged: (_) {},
          label: 'Paid by',
        ),
      );
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    });

    testWidgets('"No one" clears the selection when allowed', (tester) async {
      String? chosen = 'unset';
      await pump(
        tester,
        PersonPicker(
          options: people,
          selectedId: 'a',
          onChanged: (id) => chosen = id,
          label: 'Paid by',
          allowNone: true,
        ),
      );
      await tester.tap(find.text('No one'));
      expect(chosen, isNull);
    });

    testWidgets('no "No one" choice unless allowed', (tester) async {
      await pump(
        tester,
        PersonPicker(
          options: people,
          selectedId: null,
          onChanged: (_) {},
          label: 'Paid by',
        ),
      );
      expect(find.text('No one'), findsNothing);
    });

    testWidgets('every choice is at least 48dp tall', (tester) async {
      await pump(
        tester,
        PersonPicker(
          options: people,
          selectedId: null,
          onChanged: (_) {},
          label: 'Paid by',
        ),
      );
      expect(tester.getSize(find.byType(InkWell).first).height, greaterThan(47));
    });
  });

  group('CategoryBadge', () {
    testWidgets('shows the emoji and name, and is announced as the name', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pump(
        tester,
        const CategoryBadge(name: 'Fish', colorIndex: 1, emoji: '🐟'),
      );
      expect(find.text('🐟'), findsOneWidget);
      expect(find.text('Fish'), findsOneWidget);
      expect(find.bySemanticsLabel('Fish'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('an out-of-range colour index wraps instead of crashing', (
      tester,
    ) async {
      await pump(tester, const CategoryBadge(name: 'X', colorIndex: 99));
      expect(tester.takeException(), isNull);
      await pump(tester, const CategoryBadge(name: 'X', colorIndex: -3));
      expect(tester.takeException(), isNull);
    });

    testWidgets('the same index gives the same colour every time', (
      tester,
    ) async {
      Color colorOf() => (tester
              .widget<Container>(
                find
                    .descendant(
                      of: find.byType(CategoryBadge),
                      matching: find.byType(Container),
                    )
                    .first,
              )
              .decoration! as BoxDecoration)
          .color!;
      await pump(tester, const CategoryBadge(name: 'A', colorIndex: 4));
      final first = colorOf();
      await pump(tester, const CategoryBadge(name: 'B', colorIndex: 4));
      expect(colorOf(), first);
    });
  });
}
