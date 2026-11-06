import 'package:family_hub/core/firebase/base_mapper.dart';
import 'package:family_hub/core/utils/clock.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/features/chores/achievements/data/engagement_settings_mappers.dart';
import 'package:family_hub/features/chores/achievements/data/member_stats_mappers.dart';
import 'package:family_hub/features/chores/achievements/data/public_stats_mappers.dart';
import 'package:family_hub/features/chores/achievements/domain/default_engagement_settings.dart';
import 'package:family_hub/features/chores/achievements/domain/member_stats.dart';
import 'package:family_hub/features/chores/achievements/domain/public_stats.dart';
import 'package:family_hub/features/chores/achievements/domain/scoring/streak_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final day = DateKey(2026, 10, 18);
  final metadata = BaseMapper.createMetadata(
    uid: 'member',
    clock: FakeClock(DateTime.utc(2026, 10, 18)),
  );
  final defaults = defaultEngagementSettings(startedOn: day, graceMinutes: 30);

  test('engagement settings round-trip retains its domain values', () {
    final map = EngagementSettingsMappers.toMap(defaults, metadata);
    expect(
      EngagementSettingsMappers.fromMap(map, defaults: defaults),
      defaults,
    );
  });

  test(
    'malformed engagement values fall back without losing valid settings',
    () {
      final map = EngagementSettingsMappers.toMap(defaults, metadata)
        ..['latePermille'] = 3000
        ..['levels'] = <Object>['bad'];
      final decoded = EngagementSettingsMappers.fromMap(
        map,
        defaults: defaults,
      );
      expect(decoded.scoreSpec.latePermille, defaults.scoreSpec.latePermille);
      expect(decoded.levels, defaults.levels);
      expect(decoded.enabled, defaults.enabled);
    },
  );

  test('private stats round-trip includes streak, badges and month totals', () {
    final stats = MemberStats.empty(startedOn: day).copyWith(
      totalPoints: 125,
      level: 2,
      completedTotal: 4,
      onTimeTotal: 3,
      coversTotal: 1,
      verifiedCleanTotal: 2,
      streak: StreakState(current: 3, best: 4, pausedDays: 1, asOfDateKey: day),
      badges: <String, BadgeEarned>{'fresh_start': BadgeEarned(earnedAt: day)},
      monthly: <String, MonthlyStats>{
        '2026-10': const MonthlyStats(
          points: 125,
          done: 4,
          onTime: 3,
          covers: 1,
          verifiedClean: 2,
          isFinal: false,
          specVersion: 1,
        ),
      },
      processedThrough: day,
      lastCelebratedDateKey: day,
      sharing: true,
    );
    final decoded = MemberStatsMappers.fromMap(
      MemberStatsMappers.toMap(stats, metadata),
      defaultStartedOn: day,
    );
    expect(decoded, stats);
  });

  test('public stats mapper contains only points-free card fields', () {
    final public = PublicStats(level: 3, badgeIds: const ['fresh_start']);
    final map = PublicStatsMappers.toMap(public, metadata);
    expect(PublicStatsMappers.fromMap(map), public);
    expect(map.keys, containsAll(['level', 'badgeIds']));
    expect(map.keys, isNot(contains('totalPoints')));
    expect(map.keys, isNot(contains('streak')));
    expect(map.keys, isNot(contains('monthly')));
  });
}
