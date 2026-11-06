import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/features/chores/achievements/domain/default_engagement_settings.dart';
import 'package:family_hub/features/chores/achievements/domain/scoring/score_calculator.dart';
import 'package:family_hub/features/chores/achievements/domain/scoring/score_spec.dart';
import 'package:family_hub/features/chores/occurrences/domain/occurrence_parts.dart';
import 'package:family_hub/features/chores/occurrences/domain/occurrence_status.dart';
import 'package:family_hub/features/chores/templates/domain/template_enums.dart';
import 'package:flutter_test/flutter_test.dart';

import 'engagement_test_support.dart';

void main() {
  final spec = defaultEngagementSettings(
    startedOn: DateKey(2026, 11, 1),
    graceMinutes: 5,
  ).scoreSpec;

  test('base score table for every difficulty', () {
    const expected = <Difficulty, int>{
      Difficulty.easy: 10,
      Difficulty.normal: 20,
      Difficulty.hard: 30,
    };
    for (final entry in expected.entries) {
      final item = engagementOccurrence(
        difficulty: entry.key,
        completedAt: DateTime.utc(2026, 11, 5, 12),
      );
      expect(
        ScoreCalculator.pointsFor(
          item,
          spec,
          viewerId: 'member',
          startedOn: DateKey(2026, 11, 1),
        ),
        entry.value,
      );
    }
  });

  test('verified on-time table for all difficulties', () {
    const expected = <Difficulty, int>{
      Difficulty.easy: 12,
      Difficulty.normal: 24,
      Difficulty.hard: 36,
    };
    for (final entry in expected.entries) {
      final item = engagementOccurrence(
        difficulty: entry.key,
        completedAt: DateTime.utc(2026, 11, 5, 12),
        verifiedAt: DateTime.utc(2026, 11, 5, 13),
      );
      expect(
        ScoreCalculator.pointsFor(
          item,
          spec,
          viewerId: 'member',
          startedOn: DateKey(2026, 11, 1),
        ),
        entry.value,
      );
    }
  });

  test('late score table includes half-up rounding', () {
    const expected = <Difficulty, int>{
      Difficulty.easy: 6,
      Difficulty.normal: 12,
      Difficulty.hard: 18,
    };
    for (final entry in expected.entries) {
      final item = engagementOccurrence(
        difficulty: entry.key,
        completedAt: DateTime.utc(2026, 11, 5, 12, 6),
      );
      expect(
        ScoreCalculator.pointsFor(
          item,
          spec,
          viewerId: 'member',
          startedOn: DateKey(2026, 11, 1),
        ),
        entry.value,
      );
    }
  });

  test('late verified score rounds half-up for all difficulties', () {
    const expected = <Difficulty, int>{
      Difficulty.easy: 7,
      Difficulty.normal: 14,
      Difficulty.hard: 22,
    };
    for (final entry in expected.entries) {
      final item = engagementOccurrence(
        difficulty: entry.key,
        completedAt: DateTime.utc(2026, 11, 5, 12, 6),
        verifiedAt: DateTime.utc(2026, 11, 5, 13),
      );
      expect(
        ScoreCalculator.pointsFor(
          item,
          spec,
          viewerId: 'member',
          startedOn: DateKey(2026, 11, 1),
        ),
        entry.value,
      );
    }
  });

  test('completion exactly at due plus grace is on time', () {
    final item = engagementOccurrence(
      completedAt: DateTime.utc(2026, 11, 5, 12, 5),
    );
    final result = ScoreCalculator.calculate(
      item,
      spec,
      viewerId: 'member',
      startedOn: DateKey(2026, 11, 1),
    );
    expect(result.onTime, isTrue);
    expect(result.points, 20);
  });

  test('one instant after grace is late', () {
    final item = engagementOccurrence(
      completedAt: DateTime.utc(2026, 11, 5, 12, 5, 1),
    );
    expect(
      ScoreCalculator.calculate(
        item,
        spec,
        viewerId: 'member',
        startedOn: DateKey(2026, 11, 1),
      ).onTime,
      isFalse,
    );
  });

  test('reopened verified completion gets no verified multiplier', () {
    final item = engagementOccurrence(
      difficulty: Difficulty.normal,
      completedAt: DateTime.utc(2026, 11, 5, 12),
      verifiedAt: DateTime.utc(2026, 11, 5, 13),
      reopenCount: 1,
    );
    expect(
      ScoreCalculator.pointsFor(
        item,
        spec,
        viewerId: 'member',
        startedOn: DateKey(2026, 11, 1),
      ),
      20,
    );
  });

  test('cover bonus is additional for each base difficulty', () {
    const expected = <Difficulty, int>{
      Difficulty.easy: 15,
      Difficulty.normal: 30,
      Difficulty.hard: 45,
    };
    for (final entry in expected.entries) {
      final item = engagementOccurrence(
        difficulty: entry.key,
        coverForId: 'covered-member',
        completedAt: DateTime.utc(2026, 11, 5, 12),
      );
      expect(
        ScoreCalculator.pointsFor(
          item,
          spec,
          viewerId: 'member',
          startedOn: DateKey(2026, 11, 1),
        ),
        entry.value,
      );
    }
  });

  test('late cover still receives its cover bonus', () {
    final item = engagementOccurrence(
      difficulty: Difficulty.normal,
      coverForId: 'covered-member',
      completedAt: DateTime.utc(2026, 11, 5, 12, 6),
    );
    expect(
      ScoreCalculator.pointsFor(
        item,
        spec,
        viewerId: 'member',
        startedOn: DateKey(2026, 11, 1),
      ),
      22,
    );
  });

  test('points belong to the completing member', () {
    final item = engagementOccurrence(completedBy: 'someone-else');
    expect(
      ScoreCalculator.pointsFor(
        item,
        spec,
        viewerId: 'member',
        startedOn: DateKey(2026, 11, 1),
      ),
      0,
    );
  });

  test('points stay with the completing member when a cover is assigned', () {
    final item = engagementOccurrence(
      completedBy: 'member',
      assigneeId: 'covering-member',
      coverForId: 'original-assignee',
    );
    final coveringAward = ScoreCalculator.calculate(
      item,
      spec,
      viewerId: 'covering-member',
      startedOn: DateKey(2026, 11, 1),
    );
    expect(coveringAward.cover, isFalse);
    expect(coveringAward.points, 0);
  });

  test('items before startedOn do not earn points', () {
    final item = engagementOccurrence(day: DateKey(2026, 10, 31));
    expect(
      ScoreCalculator.pointsFor(
        item,
        spec,
        viewerId: 'member',
        startedOn: DateKey(2026, 11, 1),
      ),
      0,
    );
  });

  test('approved-absence neutral items earn no points', () {
    final item = engagementOccurrence();
    expect(
      ScoreCalculator.pointsFor(
        item,
        spec,
        viewerId: 'member',
        startedOn: DateKey(2026, 11, 1),
        absenceNeutral: (_) => true,
      ),
      0,
    );
  });

  test('skipped chores are neutral', () {
    final item = engagementOccurrence(
      status: OccurrenceStatus.skipped,
      skipReason: SkipReason.absence,
    );
    expect(
      ScoreCalculator.calculate(
        item,
        spec,
        viewerId: 'member',
        startedOn: DateKey(2026, 11, 1),
      ).completed,
      isFalse,
    );
  });

  test('unassigned chores are neutral', () {
    final item = engagementOccurrence(assigneeId: null);
    expect(
      ScoreCalculator.pointsFor(
        item,
        spec,
        viewerId: 'member',
        startedOn: DateKey(2026, 11, 1),
      ),
      0,
    );
  });

  test('soft-deleted chores are neutral', () {
    final item = engagementOccurrence(deleted: true);
    expect(
      ScoreCalculator.pointsFor(
        item,
        spec,
        viewerId: 'member',
        startedOn: DateKey(2026, 11, 1),
      ),
      0,
    );
  });

  test('a clean verified chore ticks every subtask including optional', () {
    final subtasks = engagementSubtasks();
    final allTicks = engagementTicks(const <String>['first', 'second']);
    final clean = ScoreCalculator.calculate(
      engagementOccurrence(
        subtasks: subtasks,
        subtaskDone: allTicks,
        verifiedAt: DateTime.utc(2026, 11, 5, 13),
      ),
      spec,
      viewerId: 'member',
      startedOn: DateKey(2026, 11, 1),
    );
    final incomplete = ScoreCalculator.calculate(
      engagementOccurrence(
        subtasks: subtasks,
        subtaskDone: engagementTicks(const <String>['first']),
        verifiedAt: DateTime.utc(2026, 11, 5, 13),
      ),
      spec,
      viewerId: 'member',
      startedOn: DateKey(2026, 11, 1),
    );
    expect(clean.verifiedClean, isTrue);
    expect(incomplete.verifiedClean, isFalse);
  });

  test('reopened chores are never verified-clean', () {
    final subtasks = engagementSubtasks();
    final item = engagementOccurrence(
      subtasks: subtasks,
      subtaskDone: engagementTicks(const <String>['first', 'second']),
      verifiedAt: DateTime.utc(2026, 11, 5, 13),
      reopenCount: 1,
    );
    expect(
      ScoreCalculator.calculate(
        item,
        spec,
        viewerId: 'member',
        startedOn: DateKey(2026, 11, 1),
      ).verifiedClean,
      isFalse,
    );
  });

  test('a zero verified factor is handled with integer arithmetic', () {
    final zeroFactor = ScoreSpec(
      pointBases: spec.pointBases,
      latePermille: spec.latePermille,
      verifiedPermille: 0,
      coverBonusPermille: 0,
      graceMinutes: spec.graceMinutes,
      version: spec.version,
    );
    final item = engagementOccurrence(
      verifiedAt: DateTime.utc(2026, 11, 5, 13),
    );
    expect(
      ScoreCalculator.pointsFor(
        item,
        zeroFactor,
        viewerId: 'member',
        startedOn: DateKey(2026, 11, 1),
      ),
      0,
    );
  });
}
