import 'package:flutter/material.dart';
import 'package:family_hub/core/permissions/permissions.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/features/chores/achievements/domain/default_engagement_settings.dart';
import 'package:family_hub/features/chores/achievements/domain/engagement_settings.dart';
import 'package:family_hub/features/chores/achievements/domain/member_stats.dart';
import 'package:family_hub/features/chores/achievements/domain/public_stats.dart';
import 'package:family_hub/features/chores/achievements/domain/scoring/streak_calculator.dart';
import 'package:family_hub/features/chores/achievements/presentation/engagement_providers.dart';
import 'package:family_hub/features/chores/achievements/presentation/engagement_ui_providers.dart';
import 'package:family_hub/features/chores/achievements/presentation/screens/achievements_screen.dart';
import 'package:family_hub/features/chores/achievements/presentation/screens/engagement_settings_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:family_hub/features/family/presentation/family_providers.dart';

import 'engagement_ui_test_support.dart';

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

  Future<void> pumpAchievements(
    WidgetTester tester, {
    EngagementSettings? config,
    MemberStats? memberStats,
    String languageCode = 'en',
    double textScale = 1,
    List<Override> extraOverrides = const [],
  }) {
    final selectedSettings = config ?? settings;
    final selectedStats = memberStats ?? stats;
    return pumpEngagementApp(
      tester,
      home: const AchievementsScreen(),
      uid: 'cara',
      languageCode: languageCode,
      textScale: textScale,
      overrides: [
        engagementSettingsProvider.overrideWith(
          (ref, familyId) => Stream.value(selectedSettings),
        ),
        memberStatsProvider.overrideWith(
          (ref, memberId) => Stream.value(selectedStats),
        ),
        familyPublicStatsProvider.overrideWith(
          (ref) => Stream.value(const <String, PublicStats>{}),
        ),
        membersProvider.overrideWith(
          (ref) => Stream.value(engagementTestMembers()),
        ),
        ...extraOverrides,
      ],
    );
  }

  testWidgets('achievements show private stats and hide sharing when private', (
    tester,
  ) async {
    await pumpAchievements(tester);

    expect(find.text('Achievements'), findsOneWidget);
    expect(find.text('Seedling'), findsOneWidget);
    expect(find.text('Chores completed: 8'), findsOneWidget);
    expect(find.byKey(const Key('achievement_share_switch')), findsNothing);
    expect(find.byType(CustomPaint), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sharing visibility reveals the opt-in and family strip', (
    tester,
  ) async {
    final sharedSettings = settings.copyWith(
      statsVisibility: StatsVisibility.levels,
    );
    await pumpAchievements(
      tester,
      config: sharedSettings,
      extraOverrides: [
        familyPublicStatsProvider.overrideWith(
          (ref) => Stream.value({
            'cara': PublicStats(level: 3, badgeIds: const ['fresh_start']),
            'alice': PublicStats(level: 2, badgeIds: const []),
          }),
        ),
      ],
    );

    expect(find.byKey(const Key('achievement_share_switch')), findsOneWidget);
    expect(find.text('Family achievements'), findsOneWidget);
    expect(find.text('Person alice'), findsOneWidget);
    expect(find.text('Person cara'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Person alice')).dx,
      lessThan(tester.getTopLeft(find.text('Person cara')).dx),
    );
    expect(
      find.text('Points and personal stats are never shared.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('disabled engagement has an explicit off state', (tester) async {
    await pumpAchievements(tester, config: settings.copyWith(enabled: false));

    expect(
      find.text('Achievements are turned off for this family.'),
      findsOneWidget,
    );
    expect(find.text('Chores completed: 8'), findsNothing);
  });

  testWidgets('Bangla achievements fit at 2x text scale', (tester) async {
    await pumpAchievements(tester, languageCode: 'bn', textScale: 2);

    expect(find.text('অর্জন'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('members cannot edit engagement settings', (tester) async {
    await pumpEngagementApp(
      tester,
      home: const EngagementSettingsScreen(),
      overrides: [
        engagementSettingsProvider.overrideWith(
          (ref, familyId) => Stream.value(settings),
        ),
      ],
    );

    expect(
      find.text('Only family managers can change engagement settings.'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('engagement_settings_save')), findsNothing);
  });

  testWidgets('managers see settings and read-only family visibility', (
    tester,
  ) async {
    await pumpEngagementApp(
      tester,
      home: const EngagementSettingsScreen(),
      uid: 'bob',
      role: Role.moderator,
      overrides: [
        engagementSettingsProvider.overrideWith(
          (ref, familyId) => Stream.value(settings),
        ),
      ],
    );

    expect(find.text('Enable levels and badges'), findsOneWidget);
    expect(
      find.text('Only an administrator can change family visibility.'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('engagement_settings_save')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('admin visibility changes require confirmation', (tester) async {
    await pumpEngagementApp(
      tester,
      home: const EngagementSettingsScreen(),
      uid: 'alice',
      role: Role.admin,
      overrides: [
        engagementSettingsProvider.overrideWith(
          (ref, familyId) => Stream.value(settings),
        ),
      ],
    );

    await tester.tap(find.text('Levels and badges only'));
    await tester.pumpAndSettle();
    expect(find.text('Change family visibility?'), findsOneWidget);
    expect(find.textContaining('Points are never shared.'), findsOneWidget);
  });
}
