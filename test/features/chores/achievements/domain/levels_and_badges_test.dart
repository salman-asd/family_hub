import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/features/chores/achievements/domain/badges/badge_catalog.dart';
import 'package:family_hub/features/chores/achievements/domain/badges/badge_evaluator.dart';
import 'package:family_hub/features/chores/achievements/domain/default_engagement_settings.dart';
import 'package:family_hub/features/chores/achievements/domain/levels/level_table.dart';
import 'package:family_hub/features/chores/achievements/domain/member_stats.dart';
import 'package:family_hub/features/chores/achievements/domain/scoring/streak_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final settings = defaultEngagementSettings(
    startedOn: DateKey(2026, 11, 1),
    graceMinutes: 0,
  );
  final table = LevelTable(settings.levels);

  test('level boundaries at 99, 100, 249 and 250', () {
    expect(table.levelFor(99), 1);
    expect(table.levelFor(100), 2);
    expect(table.levelFor(249), 2);
    expect(table.levelFor(250), 3);
  });

  test('level progress uses integer permille', () {
    final progress = table.progress(150);
    expect(progress.level.id, 'sprout');
    expect(progress.into, 50);
    expect(progress.needed, 150);
    expect(progress.fraction, 333);
  });

  test('highest level has no required next threshold', () {
    final progress = table.progress(4000);
    expect(progress.level.id, 'grand_tree');
    expect(progress.needed, 0);
    expect(progress.fraction, 1000);
  });

  test('level thresholds must start at zero and ascend', () {
    expect(
      () => LevelTable(const <EngagementLevel>[
        EngagementLevel(id: 'one', minPoints: 1, nameBn: 'এক', nameEn: 'One'),
      ]),
      throwsArgumentError,
    );
    expect(
      () => LevelTable(const <EngagementLevel>[
        EngagementLevel(id: 'one', minPoints: 0, nameBn: 'এক', nameEn: 'One'),
        EngagementLevel(id: 'two', minPoints: 0, nameBn: 'দুই', nameEn: 'Two'),
      ]),
      throwsArgumentError,
    );
  });

  test('level table rejects more than twelve entries', () {
    expect(
      () => LevelTable(
        List<EngagementLevel>.generate(
          13,
          (index) => EngagementLevel(
            id: 'level_$index',
            minPoints: index,
            nameBn: 'স্তর',
            nameEn: 'Level',
          ),
        ),
      ),
      throwsArgumentError,
    );
  });

  test('fresh start requires at least one completed chore', () {
    expect(
      BadgeEvaluator.evaluate(
        MemberStats.empty(startedOn: DateKey(2026, 11, 1)),
        settings.badgeThresholds,
      ),
      isNot(contains(BadgeCatalog.freshStart)),
    );
    final stats = MemberStats.empty(startedOn: DateKey(2026, 11, 1))
        .copyWith(completedTotal: 1);
    expect(
      BadgeEvaluator.evaluate(stats, settings.badgeThresholds),
      contains(BadgeCatalog.freshStart),
    );
  });

  test('consistent badge uses the streak threshold', () {
    final stats = MemberStats.empty(startedOn: DateKey(2026, 11, 1)).copyWith(
      streak: StreakState(
        current: 7,
        best: 7,
        pausedDays: 0,
        asOfDateKey: DateKey(2026, 11, 7),
      ),
    );
    expect(
      BadgeEvaluator.evaluate(stats, settings.badgeThresholds),
      contains(BadgeCatalog.consistent),
    );
  });

  test('reliable badge requires a final month and exact percentage', () {
    final base = MemberStats.empty(startedOn: DateKey(2026, 1, 1));
    final incompleteMonth = const MonthlyStats(
      points: 100,
      done: 10,
      onTime: 9,
      covers: 0,
      verifiedClean: 0,
      isFinal: false,
      specVersion: 1,
    );
    expect(
      BadgeEvaluator.evaluate(
        base.copyWith(
          monthly: <String, MonthlyStats>{'2026-01': incompleteMonth},
        ),
        settings.badgeThresholds,
      ),
      isNot(contains(BadgeCatalog.reliable)),
    );
    final finalMonth = const MonthlyStats(
      points: 100,
      done: 10,
      onTime: 9,
      covers: 0,
      verifiedClean: 0,
      isFinal: true,
      specVersion: 1,
    );
    expect(
      BadgeEvaluator.evaluate(
        base.copyWith(monthly: <String, MonthlyStats>{'2026-01': finalMonth}),
        settings.badgeThresholds,
      ),
      contains(BadgeCatalog.reliable),
    );
  });

  test('reliable badge rejects less than the configured percentage', () {
    final stats = MemberStats.empty(startedOn: DateKey(2026, 1, 1)).copyWith(
      monthly: const <String, MonthlyStats>{
        '2026-01': MonthlyStats(
          points: 100,
          done: 10,
          onTime: 8,
          covers: 0,
          verifiedClean: 0,
          isFinal: true,
          specVersion: 1,
        ),
      },
    );
    expect(
      BadgeEvaluator.evaluate(stats, settings.badgeThresholds),
      isNot(contains(BadgeCatalog.reliable)),
    );
  });

  test('reliable badge requires the minimum completed count', () {
    final stats = MemberStats.empty(startedOn: DateKey(2026, 1, 1)).copyWith(
      monthly: const <String, MonthlyStats>{
        '2026-01': MonthlyStats(
          points: 100,
          done: 9,
          onTime: 9,
          covers: 0,
          verifiedClean: 0,
          isFinal: true,
          specVersion: 1,
        ),
      },
    );
    expect(
      BadgeEvaluator.evaluate(stats, settings.badgeThresholds),
      isNot(contains(BadgeCatalog.reliable)),
    );
  });

  test('helper badge uses the covers threshold', () {
    final stats = MemberStats.empty(startedOn: DateKey(2026, 1, 1))
        .copyWith(coversTotal: 3);
    expect(
      BadgeEvaluator.evaluate(stats, settings.badgeThresholds),
      contains(BadgeCatalog.helper),
    );
  });

  test('detail champion uses verified clean total', () {
    final stats = MemberStats.empty(startedOn: DateKey(2026, 1, 1))
        .copyWith(verifiedCleanTotal: 10);
    expect(
      BadgeEvaluator.evaluate(stats, settings.badgeThresholds),
      contains(BadgeCatalog.detailChampion),
    );
  });
}
