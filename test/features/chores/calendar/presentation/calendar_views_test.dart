import 'package:family_hub/core/permissions/permissions.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/features/chores/calendar/domain/calendar_enums.dart';
import 'package:family_hub/features/chores/calendar/presentation/calendar_screen.dart';
import 'package:family_hub/features/chores/calendar/presentation/widgets/day_cell.dart';
import 'package:family_hub/features/chores/calendar/presentation/widgets/quick_actions_sheet.dart';
import 'package:family_hub/features/chores/occurrences/domain/chore_item.dart';
import 'package:family_hub/features/chores/occurrences/domain/chore_occurrence.dart';
import 'package:family_hub/features/chores/occurrences/domain/occurrence_status.dart';
import 'package:family_hub/features/chores/presentation/widgets/today_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../chores_test_helpers.dart';
import '../../presentation/chores_p3_15_support.dart';

/// P3-23: day panel, Agenda, Week, filters, quick actions, legend.
/// "Today" is Saturday 2026-10-24 (fixture clock); the family default view is
/// the agenda.
void main() {
  Future<ChoresFixture> pump(
    WidgetTester tester, {
    List<ChoreOccurrence> occurrences = const <ChoreOccurrence>[],
    CalendarView? view,
    double width = 360,
    Role role = Role.member,
  }) {
    final fixture = ChoresFixture();
    if (view != null) {
      fixture.settings.settings = fixture.settings.settings.copyWith(
        defaultCalendarView: view,
      );
    }
    return pumpP3Screen(
      tester,
      home: const Scaffold(body: CalendarScreen()),
      sharedFixture: fixture,
      occurrences: occurrences,
      width: width,
      role: role,
    );
  }

  ChoreOccurrence on(int index, DateKey day, {String assignee = 'cara'}) =>
      anOccurrence(
        id: 'tpl_${index}_${day.compact}',
        templateId: 'tpl_$index',
        dateKey: day,
        assigneeId: assignee,
      );

  group('Agenda', () {
    testWidgets('is the default and starts with today', (tester) async {
      await pump(tester);

      expect(
        find.byKey(const ValueKey<String>('calendar_agenda_day_2026-10-24')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('calendar_view_switcher')), findsOneWidget);
    });

    testWidgets('pins an overdue chore of last month at the top', (
      tester,
    ) async {
      await pump(tester, occurrences: [on(1, DateKey(2026, 9, 30))]);

      expect(find.byKey(const Key('calendar_agenda_overdue')), findsOneWidget);
      expect(find.byType(TodayRow), findsOneWidget);
    });

    testWidgets('collapses days without chores into a free-days chip', (
      tester,
    ) async {
      await pump(tester);

      expect(find.byKey(const Key('calendar_free_days')), findsWidgets);
    });

    testWidgets('scrolls up to earlier weeks and offers to load more', (
      tester,
    ) async {
      await pump(tester);

      await tester.fling(find.byType(CustomScrollView), const Offset(0, 1500), 3000);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('calendar_load_earlier')), findsOneWidget);
      expect(find.byKey(const Key('calendar_jump_today')), findsOneWidget);

      await tester.tap(find.byKey(const Key('calendar_jump_today')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('calendar_jump_today')), findsNothing);
    });

    testWidgets('900 chores scroll without errors', (tester) async {
      await pump(
        tester,
        occurrences: [
          for (var i = 0; i < 900; i++)
            on(i, DateKey(2026, 10, 25).addDays(i % 20)),
        ],
      );

      await tester.fling(find.byType(CustomScrollView), const Offset(0, -2000), 3000);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('a long press offers the allowed actions', (tester) async {
      await pump(tester, occurrences: [on(1, DateKey(2026, 10, 24))]);

      await tester.longPress(find.byType(TodayRow).first);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('calendar_quick_complete')), findsOneWidget);
      expect(find.byKey(const Key('calendar_quick_details')), findsOneWidget);
    });
  });

  group('views share one state', () {
    testWidgets('switching to Week keeps the selected day', (tester) async {
      await pump(tester, view: CalendarViewKind.month);

      await tester.tap(
        find.byKey(const ValueKey<String>('calendar_day_2026-10-27')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Week'));
      await tester.pumpAndSettle();

      expect(find.textContaining('27 October 2026'), findsWidgets);
      expect(find.byType(DayCell), findsNWidgets(7));
    });

    testWidgets('a narrow screen shows the week and says why', (tester) async {
      await pump(tester, view: CalendarViewKind.month, width: 320);

      expect(find.byKey(const Key('calendar_month_narrow')), findsOneWidget);
      expect(find.byType(DayCell), findsNWidgets(7));
    });

    testWidgets('a tablet shows the week as seven columns', (tester) async {
      await pump(tester, view: CalendarViewKind.week, width: 900);

      expect(find.byType(DayCell), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('day panel', () {
    testWidgets('lists the day and offers Add chore to a manager', (
      tester,
    ) async {
      await pump(
        tester,
        view: CalendarViewKind.month,
        role: Role.admin,
        occurrences: [on(1, DateKey(2026, 10, 24))],
      );

      expect(find.byKey(const Key('calendar_day_panel')), findsOneWidget);
      expect(find.byType(TodayRow), findsOneWidget);
      expect(find.byKey(const Key('calendar_add_chore')), findsOneWidget);
    });

    testWidgets('a plain member gets no Add chore', (tester) async {
      await pump(tester, view: CalendarViewKind.month);

      expect(find.byKey(const Key('calendar_add_chore')), findsNothing);
    });
  });

  group('filters and legend', () {
    testWidgets('a status filter shows as a removable chip', (tester) async {
      await pump(tester, occurrences: [on(1, DateKey(2026, 10, 24))]);

      await tester.tap(find.byKey(const Key('calendar_filter_button')));
      await tester.pumpAndSettle();
      final status = find.byKey(const Key('calendar_filter_status_overdue'));
      await tester.ensureVisible(status);
      await tester.tap(status);
      await tester.pumpAndSettle();

      final chip = find.byKey(const Key('calendar_chip_status_overdue'));
      expect(chip, findsOneWidget);

      await tester.tap(
        find.descendant(of: chip, matching: find.byIcon(Icons.cancel)),
      );
      await tester.pumpAndSettle();
      expect(chip, findsNothing);
    });

    testWidgets('a search shows as a chip', (tester) async {
      await pump(tester);

      await tester.tap(find.byKey(const Key('calendar_filter_button')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('calendar_search_field')),
        'zzz',
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('calendar_chip_query')), findsOneWidget);
    });

    testWidgets('the legend names every status', (tester) async {
      await pump(tester);

      await tester.tap(find.byKey(const Key('calendar_legend_button')));
      await tester.pumpAndSettle();

      expect(find.text('What the symbols mean'), findsOneWidget);
      expect(find.text('Overdue'), findsWidgets);
    });
  });

  group('quickActionsFor', () {
    ChoreItem item(ChoreStatus status, {bool projected = false}) {
      final base = ChoreItem.fromOccurrence(
        anOccurrence(id: 'tpl_1_20261024', dateKey: DateKey(2026, 10, 24)),
      );
      return base.copyWith(status: status, isProjected: projected);
    }

    test('an open chore offers complete and details to who may complete', () {
      expect(
        quickActionsFor(item(ChoreStatus.scheduled), mayComplete: true),
        <QuickAction>[QuickAction.complete, QuickAction.details],
      );
    });

    test('somebody who may not complete only gets details', () {
      expect(
        quickActionsFor(item(ChoreStatus.scheduled), mayComplete: false),
        <QuickAction>[QuickAction.details],
      );
    });

    test('a finished chore is not completed again', () {
      expect(
        quickActionsFor(item(ChoreStatus.completed), mayComplete: true),
        <QuickAction>[QuickAction.details],
      );
    });

    test('a planned chore offers nothing', () {
      expect(
        quickActionsFor(
          item(ChoreStatus.scheduled, projected: true),
          mayComplete: true,
        ),
        isEmpty,
      );
    });
  });
}
