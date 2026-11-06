import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/features/chores/achievements/domain/scoring/streak_calculator.dart';
import 'package:family_hub/features/chores/occurrences/domain/chore_occurrence.dart';
import 'package:family_hub/features/chores/occurrences/domain/occurrence_status.dart';
import 'package:flutter_test/flutter_test.dart';

import 'engagement_test_support.dart';

void main() {
  test('six completed days, a pause and a completed day yield seven', () {
    final start = DateKey(2026, 11, 1);
    final occurrences = <DateKey, List<ChoreOccurrence>>{
      for (var day = 1; day <= 6; day++)
        DateKey(2026, 11, day): [
          engagementOccurrence(id: 'day-$day', day: DateKey(2026, 11, day)),
        ],
      DateKey(2026, 11, 8): [
        engagementOccurrence(id: 'day-8', day: DateKey(2026, 11, 8)),
      ],
    };
    final all = occurrences.values.expand((items) => items);
    final facts = StreakDayFacts.fromOccurrences(
      startedOn: start,
      today: DateKey(2026, 11, 9),
      items: all,
      viewerId: 'member',
    );
    final result = StreakCalculator.advance(StreakState.empty, facts);
    expect(result.current, 7);
    expect(result.best, 7);
    expect(result.pausedDays, 1);
    expect(result.asOfDateKey, DateKey(2026, 11, 8));
  });

  test('unfinished eligible day breaks the current streak', () {
    final prev = StreakState(
      current: 4,
      best: 6,
      pausedDays: 2,
      asOfDateKey: DateKey(2026, 11, 4),
    );
    final facts = StreakDayFacts(
      startedOn: DateKey(2026, 11, 1),
      today: DateKey(2026, 11, 7),
      days: <DateKey, StreakDay>{
        DateKey(2026, 11, 5): const StreakDay(eligible: 2, completed: 1),
      },
    );
    final result = StreakCalculator.advance(prev, facts);
    expect(result.current, 0);
    expect(result.best, 6);
  });

  test('a no-eligible day pauses without extending or breaking', () {
    final prev = StreakState(
      current: 3,
      best: 5,
      pausedDays: 0,
      asOfDateKey: DateKey(2026, 11, 4),
    );
    final facts = StreakDayFacts(
      startedOn: DateKey(2026, 11, 1),
      today: DateKey(2026, 11, 6),
      days: <DateKey, StreakDay>{},
    );
    final result = StreakCalculator.advance(prev, facts);
    expect(result.current, 3);
    expect(result.best, 5);
    expect(result.pausedDays, 1);
  });

  test('today counts only when all eligible chores are done', () {
    final start = DateKey(2026, 11, 5);
    final complete = StreakDayFacts(
      startedOn: start,
      today: DateKey(2026, 11, 5),
      days: <DateKey, StreakDay>{
        DateKey(2026, 11, 5): const StreakDay(eligible: 2, completed: 2),
      },
    );
    final incomplete = StreakDayFacts(
      startedOn: start,
      today: DateKey(2026, 11, 5),
      days: <DateKey, StreakDay>{
        DateKey(2026, 11, 5): const StreakDay(eligible: 2, completed: 1),
      },
    );
    expect(
      StreakCalculator.advance(StreakState.empty, complete).asOfDateKey,
      DateKey(2026, 11, 5),
    );
    expect(
      StreakCalculator.advance(StreakState.empty, incomplete).asOfDateKey,
      isNull,
    );
  });

  test('completed chores neutralized by an approved absence are excluded', () {
    final item = engagementOccurrence();
    final facts = StreakDayFacts.fromOccurrences(
      startedOn: DateKey(2026, 11, 1),
      today: DateKey(2026, 11, 6),
      items: <ChoreOccurrence>[item],
      viewerId: 'member',
      absenceNeutral: (_) => true,
    );
    expect(facts.days, isEmpty);
  });

  test('skipped chores are not eligible for a streak day', () {
    final item = engagementOccurrence(
      status: OccurrenceStatus.skipped,
      skipReason: SkipReason.absence,
    );
    final facts = StreakDayFacts.fromOccurrences(
      startedOn: DateKey(2026, 11, 1),
      today: DateKey(2026, 11, 6),
      items: <ChoreOccurrence>[item],
      viewerId: 'member',
    );
    expect(facts.days, isEmpty);
  });

  test('chores assigned to another member are not eligible', () {
    final item = engagementOccurrence(assigneeId: 'other');
    final facts = StreakDayFacts.fromOccurrences(
      startedOn: DateKey(2026, 11, 1),
      today: DateKey(2026, 11, 6),
      items: <ChoreOccurrence>[item],
      viewerId: 'member',
    );
    expect(facts.days, isEmpty);
  });

  test('an unfinished today does not prematurely break the streak', () {
    final facts = StreakDayFacts(
      startedOn: DateKey(2026, 11, 1),
      today: DateKey(2026, 11, 6),
      days: <DateKey, StreakDay>{
        DateKey(2026, 11, 6): const StreakDay(eligible: 1, completed: 0),
      },
    );
    final previous = StreakState(
      current: 3,
      best: 3,
      pausedDays: 0,
      asOfDateKey: DateKey(2026, 11, 5),
    );
    final result = StreakCalculator.advance(previous, facts);
    expect(result.current, 3);
    expect(result.asOfDateKey, DateKey(2026, 11, 5));
  });
}
