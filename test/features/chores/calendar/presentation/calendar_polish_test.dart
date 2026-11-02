import 'package:family_hub/app/theme/heat_ramp.dart';
import 'package:family_hub/app/theme/theme_builder.dart';
import 'package:family_hub/app/theme/theme_registry.dart';
import 'package:family_hub/core/localization/app_formatters.dart';
import 'package:family_hub/core/localization/generated/app_localizations.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/features/chores/calendar/domain/calendar_enums.dart';
import 'package:family_hub/features/chores/calendar/domain/day_summary.dart';
import 'package:family_hub/features/chores/calendar/presentation/calendar_providers.dart';
import 'package:family_hub/features/chores/calendar/presentation/calendar_screen.dart';
import 'package:family_hub/features/chores/calendar/presentation/painters/hatch_painter.dart';
import 'package:family_hub/features/chores/calendar/presentation/widgets/day_cell.dart';
import 'package:family_hub/features/chores/calendar/presentation/widgets/week_view.dart';
import 'package:family_hub/features/chores/occurrences/domain/chore_occurrence.dart';
import 'package:family_hub/features/chores/settings/domain/chore_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../chores_test_helpers.dart';
import '../../presentation/chores_p3_15_support.dart';

/// P3-24: heat, hatch, corner marks, reduced motion, two-pane, landscape.
void main() {
  final day = DateKey(2026, 10, 27);

  Future<void> pumpCell(
    WidgetTester tester,
    DaySummary summary, {
    int theme = 0,
  }) async {
    final spec = appThemes[theme];
    await tester.pumpWidget(
      MaterialApp(
        theme: buildThemeData(spec),
        locale: const Locale('en'),
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SizedBox(
            width: 60,
            child: DayCell(
              summary: summary,
              selected: false,
              scope: CalendarScope.all,
              markerStyle: MarkerStyle.glyphs,
              formatters: const AppFormatters(
                languageCode: 'en',
                useBanglaDigits: false,
              ),
              minHeight: 56,
              onTap: () {},
              onLongPress: () {},
            ),
          ),
        ),
      ),
    );
  }

  final hatchFinder = find.byWidgetPredicate(
    (w) => w is CustomPaint && w.painter is HatchPainter,
  );

  group('day cell decoration', () {
    for (var i = 0; i < appThemes.length; i++) {
      testWidgets('heat level 3 tints the cell (${appThemes[i].id})', (
        tester,
      ) async {
        await pumpCell(tester, DaySummary(dateKey: day, heatLevel: 3), theme: i);

        final material = tester.widget<Material>(
          find
              .ancestor(
                of: find.byKey(ValueKey<String>('calendar_day_$day')),
                matching: find.byType(Material),
              )
              .first,
        );
        expect(material.color, HeatRamp.of(appThemes[i].tokens).tintOf(3));
      });
    }

    testWidgets('no heat, no tint and no hatch', (tester) async {
      await pumpCell(tester, DaySummary(dateKey: day));

      expect(hatchFinder, findsNothing);
      final material = tester.widget<Material>(
        find
            .ancestor(
              of: find.byKey(ValueKey<String>('calendar_day_$day')),
              matching: find.byType(Material),
            )
            .first,
      );
      expect(material.color, Colors.transparent);
    });

    testWidgets('a planned-only day and an away day are hatched', (
      tester,
    ) async {
      await pumpCell(tester, DaySummary(dateKey: day, hasProjectedOnly: true));
      expect(hatchFinder, findsOneWidget);
      final painter =
          tester.widget<CustomPaint>(hatchFinder).painter! as HatchPainter;
      expect(painter.directions, <HatchDirection>{HatchDirection.rising});

      await pumpCell(
        tester,
        DaySummary(
          dateKey: day,
          unavailableMemberIds: const <String>{'dave'},
        ),
      );
      final away =
          tester.widget<CustomPaint>(hatchFinder).painter! as HatchPainter;
      expect(away.directions, <HatchDirection>{HatchDirection.falling});
    });

    testWidgets('a day outside the month has no heat, hatch or marks', (
      tester,
    ) async {
      await pumpCell(tester, DaySummary.outside(day));

      expect(hatchFinder, findsNothing);
      expect(find.byKey(const Key('calendar_mark_needs_cover')), findsNothing);
    });

    testWidgets('corner marks show for cover and attention', (tester) async {
      await pumpCell(
        tester,
        DaySummary(
          dateKey: day,
          total: 1,
          hasNeedsCover: true,
          hasNeedsAttention: true,
        ),
      );

      expect(find.byKey(const Key('calendar_mark_needs_cover')), findsOneWidget);
      expect(
        find.byKey(const Key('calendar_mark_needs_attention')),
        findsOneWidget,
      );
    });

    testWidgets('the label names every decoration', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpCell(
        tester,
        DaySummary(
          dateKey: day,
          hasProjectedOnly: true,
          unavailableMemberIds: const <String>{'dave'},
          hasNeedsCover: true,
          hasNeedsAttention: true,
        ),
      );

      expect(
        find.bySemanticsLabel(
          RegExp(r'planned.*someone is away.*needs cover.*needs attention'),
        ),
        findsOneWidget,
      );
      handle.dispose();
    });
  });

  group('the screen', () {
    Future<ChoresFixture> pump(
      WidgetTester tester, {
      double width = 360,
      double height = 800,
      List<ChoreOccurrence> occurrences = const <ChoreOccurrence>[],
    }) {
      final fixture = ChoresFixture();
      fixture.settings.settings = ChoreSettings.defaults.copyWith(
        defaultCalendarView: CalendarViewKind.month,
      );
      return pumpP3Screen(
        tester,
        home: const Scaffold(body: CalendarScreen()),
        sharedFixture: fixture,
        occurrences: occurrences,
        width: width,
        height: height,
        languageCode: 'en',
      );
    }

    Finder cell(int d) =>
        find.byKey(ValueKey<String>('calendar_day_${DateKey(2026, 10, d)}'));

    testWidgets('a phone has the draggable panel, a tablet the pane', (
      tester,
    ) async {
      await pump(tester);
      expect(find.byKey(const Key('calendar_day_panel')), findsOneWidget);
      expect(find.byKey(const Key('calendar_day_pane')), findsNothing);

      await pump(tester, width: 900);
      expect(find.byKey(const Key('calendar_day_pane')), findsOneWidget);
      expect(find.byKey(const Key('calendar_day_panel')), findsNothing);
    });

    testWidgets('the tablet pane follows the selected day', (tester) async {
      await pump(
        tester,
        width: 900,
        occurrences: [
          anOccurrence(
            id: 'tpl_1_20261027',
            templateId: 'tpl_1',
            dateKey: DateKey(2026, 10, 27),
            assigneeId: 'cara',
          ),
        ],
      );

      await tester.tap(cell(27));
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byKey(const Key('calendar_day_pane')),
          matching: find.textContaining('1 chore'),
        ),
        findsWidgets,
      );
    });

    testWidgets('a phone held sideways gets the week, not the month', (
      tester,
    ) async {
      await pump(tester, width: 800, height: 360);

      expect(find.byType(WeekView), findsOneWidget);
      expect(find.byKey(const Key('calendar_month_narrow')), findsOneWidget);
    });

    testWidgets('reduced motion leaves no running animation', (tester) async {
      await pump(tester);

      await tester.tap(cell(27));
      await tester.pump();
      expect(SchedulerBinding.instance.transientCallbackCount, 0);

      await tester.tap(find.byKey(const Key('calendar_next')));
      await tester.pump();
      expect(SchedulerBinding.instance.transientCallbackCount, 0);

      await tester.tap(find.byKey(const Key('calendar_today_pill')));
      await tester.pump();
      expect(SchedulerBinding.instance.transientCallbackCount, 0);
    });

    testWidgets('the display sheet switches heat mode on and off', (
      tester,
    ) async {
      await pump(tester);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(CalendarScreen)),
      );
      expect(container.read(calendarHeatModeProvider), HeatMode.off);

      await tester.tap(find.byKey(const Key('calendar_display_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('calendar_heat_switch')));
      await tester.pumpAndSettle();

      expect(container.read(calendarHeatModeProvider), HeatMode.workload);
      expect(find.byKey(const Key('calendar_heat_legend')), findsOneWidget);
    });

    testWidgets('the legend sheet explains the hatch, marks and heat', (
      tester,
    ) async {
      await pump(tester);

      await tester.tap(find.byKey(const Key('calendar_legend_button')));
      await tester.pumpAndSettle();

      expect(find.text('Day cell marks'), findsOneWidget);
      expect(find.byKey(const Key('calendar_heat_legend')), findsOneWidget);
    });

    testWidgets('900 items: the month model is built once, not per tap', (
      tester,
    ) async {
      await pump(
        tester,
        occurrences: [
          for (var i = 0; i < 900; i++)
            anOccurrence(
              id: 'tpl_${i}_${DateKey(2026, 10, 1 + i % 28).compact}',
              templateId: 'tpl_$i',
              dateKey: DateKey(2026, 10, 1 + i % 28),
              assigneeId: 'cara',
            ),
        ],
      );
      final container = ProviderScope.containerOf(
        tester.element(find.byType(CalendarScreen)),
      );
      var builds = 0;
      final sub = container.listen(
        calendarMonthModelProvider(MonthKey(2026, 10)),
        (_, _) => builds++,
      );
      addTearDown(sub.close);
      await tester.pumpAndSettle();
      final settled = builds;

      // Selecting days never changes the items, scope or filters.
      await tester.tap(cell(5));
      await tester.pumpAndSettle();
      await tester.tap(cell(12));
      await tester.pumpAndSettle();

      expect(builds, settled);
      expect(tester.takeException(), isNull);
    });
  });
}
