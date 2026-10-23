import 'package:family_hub/app/theme/theme_registry.dart';
import 'package:family_hub/core/localization/generated/app_localizations.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/shared/widgets/month_switcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'shared_widgets_test_support.dart';

/// Behaviour of the P2-12 [MonthSwitcher]: it clamps at [min]/[max], reports
/// the neighbouring month and opens a picker for a distant month.
void main() {
  setUpAll(loadBundledFonts);

  const enPrefs = <String, Object>{
    'language_code': 'en',
    'use_bangla_digits': false,
  };

  Future<void> pumpSwitcher(
    WidgetTester tester,
    Widget child, {
    Locale locale = const Locale('bn'),
    Map<String, Object> prefs = const <String, Object>{},
  }) => pumpSharedWidget(
    tester,
    child: SizedBox(width: 320, child: child),
    spec: defaultLightSpec,
    locale: locale,
    prefsValues: prefs,
  );

  testWidgets('labels the month through AppFormatters', (tester) async {
    await pumpSwitcher(
      tester,
      MonthSwitcher(month: MonthKey(2026, 10), onChanged: (value) {}),
      locale: const Locale('en'),
      prefs: enPrefs,
    );

    expect(find.text('October 2026'), findsOneWidget);
  });

  testWidgets('the previous arrow is disabled at min', (tester) async {
    final month = MonthKey(2026, 10);
    final l10n = await AppLocalizations.delegate.load(const Locale('bn'));
    MonthKey? changed;

    await pumpSwitcher(
      tester,
      MonthSwitcher(
        month: month,
        min: month,
        max: MonthKey(2027, 3),
        onChanged: (value) => changed = value,
      ),
    );

    final previous = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.chevron_left_rounded),
    );
    expect(previous.onPressed, isNull);

    await tester.tap(find.byTooltip(l10n.monthSwitcherPrevious));
    await tester.pump();
    expect(changed, isNull);
  });

  testWidgets('the next arrow is disabled at max', (tester) async {
    final month = MonthKey(2027, 3);
    final l10n = await AppLocalizations.delegate.load(const Locale('bn'));
    MonthKey? changed;

    await pumpSwitcher(
      tester,
      MonthSwitcher(
        month: month,
        min: MonthKey(2026, 10),
        max: month,
        onChanged: (value) => changed = value,
      ),
    );

    final next = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.chevron_right_rounded),
    );
    expect(next.onPressed, isNull);

    await tester.tap(find.byTooltip(l10n.monthSwitcherNext));
    await tester.pump();
    expect(changed, isNull);
  });

  testWidgets('moves one month at a time between the bounds', (tester) async {
    final l10n = await AppLocalizations.delegate.load(const Locale('bn'));
    final changes = <MonthKey>[];

    await pumpSwitcher(
      tester,
      _SwitcherHarness(
        initial: MonthKey(2026, 10),
        min: MonthKey(2026, 10),
        max: MonthKey(2026, 12),
        onChanged: changes.add,
      ),
    );

    await tester.tap(find.byTooltip(l10n.monthSwitcherNext));
    await tester.pump();
    await tester.tap(find.byTooltip(l10n.monthSwitcherPrevious));
    await tester.pump();

    expect(changes, [MonthKey(2026, 11), MonthKey(2026, 10)]);
  });

  testWidgets('opens a picker and reports the chosen month', (tester) async {
    final l10n = await AppLocalizations.delegate.load(const Locale('bn'));
    MonthKey? picked;

    await pumpSwitcher(
      tester,
      MonthSwitcher(
        month: MonthKey(2026, 10),
        onChanged: (value) => picked = value,
      ),
    );

    await tester.tap(find.text('অক্টোবর ২০২৬'));
    await tester.pumpAndSettle();

    expect(find.text(l10n.monthSwitcherSelectTitle), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, 'নভেম্বর'));
    await tester.pumpAndSettle();

    expect(picked, MonthKey(2026, 11));
  });
}

/// A controlled [MonthSwitcher] parent, the way a screen uses it: it stores the
/// month it was given, so the next tap starts from the new month.
class _SwitcherHarness extends StatefulWidget {
  const _SwitcherHarness({
    required this.initial,
    required this.onChanged,
    this.min,
    this.max,
  });

  final MonthKey initial;
  final MonthKey? min;
  final MonthKey? max;
  final ValueChanged<MonthKey> onChanged;

  @override
  State<_SwitcherHarness> createState() => _SwitcherHarnessState();
}

class _SwitcherHarnessState extends State<_SwitcherHarness> {
  late MonthKey _month = widget.initial;

  @override
  Widget build(BuildContext context) {
    return MonthSwitcher(
      month: _month,
      min: widget.min,
      max: widget.max,
      onChanged: (month) {
        setState(() => _month = month);
        widget.onChanged(month);
      },
    );
  }
}
