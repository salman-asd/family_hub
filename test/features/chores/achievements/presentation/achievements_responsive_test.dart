import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/features/chores/achievements/domain/default_engagement_settings.dart';
import 'package:family_hub/features/chores/achievements/domain/member_stats.dart';
import 'package:family_hub/features/chores/achievements/domain/public_stats.dart';
import 'package:family_hub/features/chores/achievements/domain/scoring/streak_calculator.dart';
import 'package:family_hub/features/chores/achievements/presentation/engagement_providers.dart';
import 'package:family_hub/features/chores/achievements/presentation/engagement_ui_providers.dart';
import 'package:family_hub/features/chores/achievements/presentation/screens/achievements_screen.dart';
import 'package:family_hub/features/family/presentation/family_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'engagement_ui_test_support.dart';

/// P4-24: on a wide window the badge shelf gets its own pane instead of
/// hanging below a long level card.
void main() {
  final startedOn = DateKey(2026, 10, 1);
  final settings = defaultEngagementSettings(
    startedOn: startedOn,
    graceMinutes: 0,
  );
  final stats = MemberStats.empty(startedOn: startedOn).copyWith(
    totalPoints: 250,
    completedTotal: 8,
    onTimeTotal: 6,
    coversTotal: 2,
    verifiedCleanTotal: 3,
    streak: StreakState.empty.copyWith(current: 3, best: 4),
  );

  Future<void> pumpAchievements(WidgetTester tester, Size size) =>
      pumpEngagementApp(
        tester,
        home: const AchievementsScreen(),
        uid: 'cara',
        size: size,
        overrides: [
          engagementSettingsProvider.overrideWith(
            (ref, familyId) => Stream.value(settings),
          ),
          memberStatsProvider.overrideWith(
            (ref, memberId) => Stream.value(stats),
          ),
          familyPublicStatsProvider.overrideWith(
            (ref) => Stream.value(const <String, PublicStats>{}),
          ),
          membersProvider.overrideWith(
            (ref) => Stream.value(engagementTestMembers()),
          ),
        ],
      );

  Finder badgeHeading() => find.descendant(
    of: find.byType(AchievementsScreen),
    matching: find.text('Badges'),
  );

  for (final (size, expanded) in const <(Size, bool)>[
    (Size(360, 780), false),
    (Size(600, 900), false),
    (Size(840, 1024), true),
    (Size(1024, 768), true),
  ]) {
    testWidgets('layout at ${size.width} dp', (tester) async {
      await pumpAchievements(tester, size);
      expect(tester.takeException(), isNull);
      expect(badgeHeading(), findsOneWidget);
      final headingX = tester.getTopLeft(badgeHeading()).dx;
      if (expanded) {
        expect(headingX, greaterThan(size.width / 2));
      } else {
        expect(headingX, lessThan(60));
      }
    });
  }
}
