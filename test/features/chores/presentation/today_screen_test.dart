import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/features/chores/occurrences/domain/chore_occurrence.dart';
import 'package:family_hub/features/chores/occurrences/domain/occurrence_status.dart';
import 'package:family_hub/features/chores/occurrences/presentation/occurrence_providers.dart';
import 'package:family_hub/features/chores/presentation/today_screen.dart';
import 'package:family_hub/features/chores/presentation/widgets/chore_tile.dart';
import 'package:family_hub/features/chores/settings/domain/chore_catalog_entries.dart';
import 'package:family_hub/features/chores/settings/domain/chore_settings.dart';
import 'package:family_hub/features/chores/settings/presentation/chore_settings_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_test/flutter_test.dart';

import '../chores_test_helpers.dart';
import 'chores_p3_15_support.dart';

/// P3-15 / Wave R5: the Today screen (U-04 .. U-08, U-11).
///
/// The fixture clock is 2026-10-24 09:00Z = 15:00 in Dhaka, so "today" is the
/// 24th. `cara` is the acting member.
void main() {
  final day = DateKey(2026, 10, 24);
  final done = DateTime.utc(2026, 10, 24, 4);

  ChoreOccurrence completed(String id, String assignee) => anOccurrence(
    id: id,
    dateKey: day,
    assigneeId: assignee,
    plannedAssigneeId: assignee,
    status: OccurrenceStatus.completed,
    completedAt: done,
    completedBy: assignee,
  );

  ChoreOccurrence open(String id, String assignee, {String name = 'Sweep'}) =>
      anOccurrence(
        id: id,
        dateKey: day,
        assigneeId: assignee,
        plannedAssigneeId: assignee,
        nameBn: name,
        nameEn: name,
        // Due late in the evening, so it is not overdue at 15:00.
        dueAt: DateTime.utc(2026, 10, 24, 15),
        dueMinutes: 21 * 60,
      );

  testWidgets('U-06: when everything is done it says so, not "nothing today"', (
    tester,
  ) async {
    await pumpP3Screen(
      tester,
      home: const TodayScreen(),
      occurrences: <ChoreOccurrence>[completed('a_20261024', 'cara')],
    );

    expect(find.text('All done for today'), findsOneWidget);
    expect(find.text('Nothing to do today'), findsNothing);
    expect(find.text('1 of 1 done'), findsOneWidget);
  });

  testWidgets('a day with no chores shows the empty state', (tester) async {
    await pumpP3Screen(tester, home: const TodayScreen());

    expect(find.text('Nothing to do today'), findsOneWidget);
    expect(find.text('All done for today'), findsNothing);
  });

  testWidgets('U-05: the progress follows the Mine / Whole family toggle', (
    tester,
  ) async {
    await pumpP3Screen(
      tester,
      home: const TodayScreen(),
      occurrences: <ChoreOccurrence>[
        completed('a_20261024', 'cara'),
        open('b_20261024', 'dave'),
      ],
    );

    expect(find.text('1 of 1 done'), findsOneWidget);

    await tester.tap(find.text('Whole family'));
    await tester.pump();

    expect(find.text('1 of 2 done'), findsOneWidget);
  });

  testWidgets('U-07: the toggle starts at the family default scope', (
    tester,
  ) async {
    await pumpP3Screen(
      tester,
      home: const TodayScreen(),
      occurrences: <ChoreOccurrence>[
        completed('a_20261024', 'cara'),
        open('b_20261024', 'dave'),
      ],
      overrides: [
        choreSettingsProvider.overrideWithValue(
          ChoreSettings.defaults.copyWith(defaultScope: CalendarScopeKind.all),
        ),
      ],
    );

    expect(find.text('1 of 2 done'), findsOneWidget);
  });

  testWidgets('U-04: a failed month listener shows an error with Retry', (
    tester,
  ) async {
    await pumpP3Screen(
      tester,
      home: const TodayScreen(),
      overrides: [
        monthOccurrencesProvider.overrideWith(
          (ref, month) =>
              Stream<MonthOccurrences>.error(StateError('listener failed')),
        ),
      ],
    );

    expect(find.text('Retry'), findsOneWidget);
    expect(find.text('Nothing to do today'), findsNothing);
  });

  testWidgets('U-08: a finished chore has no swipe action', (tester) async {
    await pumpP3Screen(
      tester,
      home: const TodayScreen(),
      occurrences: <ChoreOccurrence>[completed('a_20261024', 'cara')],
    );
    await tester.tap(find.text('Done today (1)'));
    await tester.pump();

    final slidable = tester.widget<Slidable>(find.byType(Slidable));
    expect(slidable.startActionPane, isNull);
  });

  testWidgets('U-08: an open chore of mine can be completed by a swipe', (
    tester,
  ) async {
    await pumpP3Screen(
      tester,
      home: const TodayScreen(),
      occurrences: <ChoreOccurrence>[open('b_20261024', 'cara')],
    );

    final slidable = tester.widget<Slidable>(find.byType(Slidable));
    expect(slidable.startActionPane, isNotNull);
    expect(slidable.endActionPane, isNotNull);
  });

  testWidgets('U-11: a row offers screen-reader actions for both swipes', (
    tester,
  ) async {
    await pumpP3Screen(
      tester,
      home: const TodayScreen(),
      occurrences: <ChoreOccurrence>[open('b_20261024', 'cara')],
    );

    final tile = tester.widget<ChoreTile>(find.byType(ChoreTile));
    final labels = tile.semanticActions!.keys.map((a) => a.label).toSet();
    expect(labels, <String>{'Mark done', 'Chore'});
  });

  testWidgets('U-03: a projected row is read-only', (tester) async {
    await pumpP3Screen(
      tester,
      home: const TodayScreen(),
      occurrences: <ChoreOccurrence>[open('b_20261024', 'cara')],
    );
    // The stored row can be opened; the same item marked projected cannot.
    final tile = tester.widget<ChoreTile>(find.byType(ChoreTile));
    expect(canOpenOccurrence(tile.item), isTrue);
    expect(canOpenOccurrence(tile.item.copyWith(isProjected: true)), isFalse);
  });

  for (final scale in const [1.0, 2.0]) {
    testWidgets('no overflow at text scale $scale', (tester) async {
      await pumpP3Screen(
        tester,
        home: const TodayScreen(),
        textScale: scale,
        occurrences: <ChoreOccurrence>[
          completed('a_20261024', 'cara'),
          open('b_20261024', 'cara', name: 'Clean the fridge shelves'),
        ],
      );

      expect(tester.takeException(), isNull);
    });
  }
}
