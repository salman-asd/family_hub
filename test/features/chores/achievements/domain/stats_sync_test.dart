import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/features/chores/achievements/domain/default_engagement_settings.dart';
import 'package:family_hub/features/chores/achievements/domain/engagement_settings.dart';
import 'package:family_hub/features/chores/achievements/domain/member_stats.dart';
import 'package:family_hub/features/chores/achievements/domain/scoring/score_spec.dart';
import 'package:family_hub/features/chores/achievements/domain/stats_sync.dart';
import 'package:family_hub/features/chores/occurrences/domain/chore_occurrence.dart';
import 'package:family_hub/features/chores/templates/domain/template_enums.dart';
import 'package:flutter_test/flutter_test.dart';

import 'engagement_test_support.dart';

void main() {
  final start = DateKey(2026, 10, 1);

  test('sync totals current month and carries the current setting version', () {
    final settings = defaultEngagementSettings(
      startedOn: start,
      graceMinutes: 0,
    );
    final result = StatsSync.compute(
      previous: MemberStats.empty(startedOn: start),
      currentMonthItems: <ChoreOccurrence>[
        engagementOccurrence(day: DateKey(2026, 11, 5)),
      ],
      finalisingMonths: const <MonthKey, List<ChoreOccurrence>>{},
      spec: settings,
      today: DateKey(2026, 11, 5),
      viewerId: 'member',
    );
    expect(result.totalPoints, 20);
    expect(result.completedTotal, 1);
    expect(result.monthly['2026-11']!.isFinal, isFalse);
    expect(result.monthly['2026-11']!.specVersion, 1);
  });

  test('same sync is idempotent', () {
    final settings = defaultEngagementSettings(
      startedOn: start,
      graceMinutes: 0,
    );
    final items = <ChoreOccurrence>[
      engagementOccurrence(day: DateKey(2026, 11, 5)),
    ];
    final first = StatsSync.compute(
      previous: MemberStats.empty(startedOn: start),
      currentMonthItems: items,
      finalisingMonths: const <MonthKey, List<ChoreOccurrence>>{},
      spec: settings,
      today: DateKey(2026, 11, 5),
      viewerId: 'member',
    );
    final second = StatsSync.compute(
      previous: first,
      currentMonthItems: items,
      finalisingMonths: const <MonthKey, List<ChoreOccurrence>>{},
      spec: settings,
      today: DateKey(2026, 11, 5),
      viewerId: 'member',
    );
    expect(second, first);
  });

  test('total points do not decrease over a sequence of live syncs', () {
    final settings = defaultEngagementSettings(
      startedOn: start,
      graceMinutes: 0,
    );
    var previous = MemberStats.empty(startedOn: start);
    for (var completed = 0; completed <= 8; completed++) {
      final items = <ChoreOccurrence>[
        for (var index = 0; index < completed; index++)
          engagementOccurrence(id: 'item-$index', day: DateKey(2026, 11, 5)),
      ];
      final next = StatsSync.compute(
        previous: previous,
        currentMonthItems: items,
        finalisingMonths: const <MonthKey, List<ChoreOccurrence>>{},
        spec: settings,
        today: DateKey(2026, 11, 5),
        viewerId: 'member',
      );
      expect(next.totalPoints, greaterThanOrEqualTo(previous.totalPoints));
      previous = next;
    }
  });

  test('earlier month is finalised once and then never recomputed', () {
    final settings = defaultEngagementSettings(
      startedOn: start,
      graceMinutes: 0,
    );
    final first = StatsSync.compute(
      previous: MemberStats.empty(startedOn: start),
      currentMonthItems: const <ChoreOccurrence>[],
      finalisingMonths: <MonthKey, List<ChoreOccurrence>>{
        MonthKey(2026, 10): <ChoreOccurrence>[
          engagementOccurrence(day: DateKey(2026, 10, 20)),
        ],
      },
      spec: settings,
      today: DateKey(2026, 11, 5),
      viewerId: 'member',
    );
    expect(first.monthly['2026-10']!.isFinal, isTrue);
    final changedDefaults = defaultEngagementSettings(
      startedOn: start,
      graceMinutes: 0,
    );
    final changedSpec = EngagementSettings(
      enabled: changedDefaults.enabled,
      startedOn: changedDefaults.startedOn,
      celebrationEnabled: changedDefaults.celebrationEnabled,
      showHelpersHighlight: changedDefaults.showHelpersHighlight,
      statsVisibility: changedDefaults.statsVisibility,
      scoreSpec: ScoreSpec(
        pointBases: const <Difficulty, int>{
          Difficulty.easy: 100,
          Difficulty.normal: 200,
          Difficulty.hard: 300,
        },
        latePermille: 600,
        verifiedPermille: 1200,
        coverBonusPermille: 500,
        graceMinutes: 0,
        version: 2,
      ),
      levels: changedDefaults.levels,
      badgeThresholds: changedDefaults.badgeThresholds,
    );
    final second = StatsSync.compute(
      previous: first,
      currentMonthItems: const <ChoreOccurrence>[],
      finalisingMonths: <MonthKey, List<ChoreOccurrence>>{
        MonthKey(2026, 10): <ChoreOccurrence>[
          engagementOccurrence(
            id: 'new',
            day: DateKey(2026, 10, 20),
            difficulty: Difficulty.hard,
          ),
        ],
      },
      spec: changedSpec,
      today: DateKey(2026, 11, 5),
      viewerId: 'member',
    );
    expect(second.monthly['2026-10'], first.monthly['2026-10']);
  });

  test('monthly totals never decrease when live data shrinks', () {
    final settings = defaultEngagementSettings(
      startedOn: start,
      graceMinutes: 0,
    );
    final first = StatsSync.compute(
      previous: MemberStats.empty(startedOn: start),
      currentMonthItems: <ChoreOccurrence>[
        engagementOccurrence(day: DateKey(2026, 11, 5)),
      ],
      finalisingMonths: const <MonthKey, List<ChoreOccurrence>>{},
      spec: settings,
      today: DateKey(2026, 11, 5),
      viewerId: 'member',
    );
    final second = StatsSync.compute(
      previous: first,
      currentMonthItems: const <ChoreOccurrence>[],
      finalisingMonths: const <MonthKey, List<ChoreOccurrence>>{},
      spec: settings,
      today: DateKey(2026, 11, 5),
      viewerId: 'member',
    );
    expect(second.totalPoints, first.totalPoints);
    expect(second.completedTotal, first.completedTotal);
  });

  test('badge ids are a union and never lost on later sync', () {
    final settings = defaultEngagementSettings(
      startedOn: start,
      graceMinutes: 0,
    );
    final first = StatsSync.compute(
      previous: MemberStats.empty(startedOn: start),
      currentMonthItems: <ChoreOccurrence>[
        engagementOccurrence(day: DateKey(2026, 11, 5)),
      ],
      finalisingMonths: const <MonthKey, List<ChoreOccurrence>>{},
      spec: settings,
      today: DateKey(2026, 11, 5),
      viewerId: 'member',
    );
    final second = StatsSync.compute(
      previous: first,
      currentMonthItems: const <ChoreOccurrence>[],
      finalisingMonths: const <MonthKey, List<ChoreOccurrence>>{},
      spec: settings,
      today: DateKey(2026, 11, 5),
      viewerId: 'member',
    );
    expect(second.badges.keys, containsAll(first.badges.keys));
  });

  test('last celebration date is untouched', () {
    final celebrated = MemberStats.empty(startedOn: start)
        .copyWith(lastCelebratedDateKey: DateKey(2026, 11, 4));
    final result = StatsSync.compute(
      previous: celebrated,
      currentMonthItems: const <ChoreOccurrence>[],
      finalisingMonths: const <MonthKey, List<ChoreOccurrence>>{},
      spec: defaultEngagementSettings(startedOn: start, graceMinutes: 0),
      today: DateKey(2026, 11, 5),
      viewerId: 'member',
    );
    expect(result.lastCelebratedDateKey, DateKey(2026, 11, 4));
  });

  test('months beyond the cap fold into legacy', () {
    final firstDay = DateKey(2022, 1, 1);
    final finalisingMonths = <MonthKey, List<ChoreOccurrence>>{};
    for (
      var month = firstDay.monthKey;
      month.compareTo(MonthKey(2026, 1)) < 0;
      month = month.addMonths(1)
    ) {
      finalisingMonths[month] = const <ChoreOccurrence>[];
    }
    final result = StatsSync.compute(
      previous: MemberStats.empty(startedOn: firstDay),
      currentMonthItems: const <ChoreOccurrence>[],
      finalisingMonths: finalisingMonths,
      spec: defaultEngagementSettings(startedOn: firstDay, graceMinutes: 0),
      today: DateKey(2026, 1, 5),
      viewerId: 'member',
    );
    expect(result.monthly, contains('legacy'));
    expect(result.monthly.length, lessThanOrEqualTo(kMaxStatsMonths));
    final repeat = StatsSync.compute(
      previous: result,
      currentMonthItems: const <ChoreOccurrence>[],
      finalisingMonths: finalisingMonths,
      spec: defaultEngagementSettings(startedOn: firstDay, graceMinutes: 0),
      today: DateKey(2026, 1, 5),
      viewerId: 'member',
    );
    expect(repeat, result);
  });
}
