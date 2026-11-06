import 'package:family_hub/app/theme/theme_controller.dart';
import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/app/theme/theme_builder.dart';
import 'package:family_hub/app/theme/theme_registry.dart';
import 'package:family_hub/core/localization/generated/app_localizations.dart';
import 'package:family_hub/core/utils/clock.dart';
import 'package:family_hub/core/utils/clock_provider.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/features/chores/achievements/domain/celebration_state.dart';
import 'package:family_hub/features/chores/achievements/domain/default_engagement_settings.dart';
import 'package:family_hub/features/chores/achievements/domain/engagement_settings.dart';
import 'package:family_hub/features/chores/achievements/domain/member_stats.dart';
import 'package:family_hub/features/chores/achievements/domain/member_stats_repository.dart';
import 'package:family_hub/features/chores/achievements/domain/public_stats.dart';
import 'package:family_hub/features/chores/achievements/domain/public_stats_repository.dart';
import 'package:family_hub/features/chores/achievements/domain/usecases/mark_celebrated.dart';
import 'package:family_hub/features/chores/achievements/domain/usecases/sync_member_stats.dart';
import 'package:family_hub/features/chores/achievements/presentation/celebration_controller.dart';
import 'package:family_hub/features/chores/achievements/presentation/celebration_host.dart';
import 'package:family_hub/features/chores/achievements/presentation/engagement_providers.dart';
import 'package:family_hub/features/chores/availability/domain/availability_index.dart';
import 'package:family_hub/features/chores/occurrences/domain/chore_occurrence.dart';
import 'package:family_hub/features/chores/occurrences/domain/occurrence_status.dart';
import 'package:family_hub/features/family/domain/member.dart';
import 'package:family_hub/features/family/domain/member_role.dart';
import 'package:family_hub/features/family/domain/membership.dart';
import 'package:family_hub/features/family/presentation/family_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../support/in_memory_backend.dart';
import '../domain/engagement_test_support.dart';

void main() {
  const familyId = 'family';
  const memberId = 'member';
  final today = DateKey(2026, 11, 6);
  final now = DateTime.utc(2026, 11, 6, 14);
  final settings = defaultEngagementSettings(
    startedOn: DateKey(2026, 11, 1),
    graceMinutes: 30,
  );

  late SharedPreferences preferences;
  late FakeClock clock;
  late InMemoryBackend families;
  late _StatsRepository stats;
  late ProviderContainer container;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    preferences = await SharedPreferences.getInstance();
    clock = FakeClock(now);
    families = InMemoryBackend()
      ..members[familyId] = <String, Member>{
        memberId: const Member(
          uid: memberId,
          role: MemberRole.member,
          status: MembershipStatus.active,
          fullName: 'Member',
          relationship: 'other',
        ),
      };
    stats = _StatsRepository();
    final publicStats = _PublicStatsRepository();
    container = _container(
      preferences: preferences,
      clock: clock,
      families: families,
      stats: stats,
      publicStats: publicStats,
    );
  });

  tearDown(() => container.dispose());

  test(
    'incomplete then complete emits one celebration with synced details',
    () async {
      final controller = container.read(celebrationControllerProvider.notifier);
      final complete = _items(today);
      final incomplete = <ChoreOccurrence>[
        ...complete.take(2),
        complete.last.copyWith(
          status: OccurrenceStatus.scheduled,
          completedAt: null,
          completedBy: null,
        ),
      ];

      await controller.observe(
        familyId: familyId,
        memberId: memberId,
        today: today,
        settings: settings,
        monthItems: incomplete,
        stats: null,
        availability: AvailabilityIndex.empty,
      );
      expect(
        container.read(celebrationControllerProvider),
        isA<CelebrationNone>(),
      );

      await controller.observe(
        familyId: familyId,
        memberId: memberId,
        today: today,
        settings: settings,
        monthItems: _items(today),
        stats: stats.current,
        availability: AvailabilityIndex.empty,
      );

      final shown = container.read(celebrationControllerProvider);
      expect(shown, isA<CelebrationShown>());
      expect((shown as CelebrationShown).pointsToday, 36);
      expect(shown.totalPoints, 36);
      expect(shown.levelBefore, 1);
      expect(stats.current?.lastCelebratedDateKey, today);
      expect(
        preferences.getString('celebrated_date:family:member'),
        '2026-11-06',
      );

      await controller.observe(
        familyId: familyId,
        memberId: memberId,
        today: today,
        settings: settings,
        monthItems: _items(today),
        stats: stats.current,
        availability: AvailabilityIndex.empty,
      );
      expect(container.read(celebrationControllerProvider), same(shown));
    },
  );

  test(
    'local date suppresses a second completion after reopening incomplete',
    () async {
      final controller = container.read(celebrationControllerProvider.notifier);
      await controller.observe(
        familyId: familyId,
        memberId: memberId,
        today: today,
        settings: settings,
        monthItems: _items(today),
        stats: null,
        availability: AvailabilityIndex.empty,
      );
      expect(
        container.read(celebrationControllerProvider),
        isA<CelebrationShown>(),
      );

      await controller.observe(
        familyId: familyId,
        memberId: memberId,
        today: today,
        settings: settings,
        monthItems: <ChoreOccurrence>[
          ..._items(today).take(2),
          _items(today).last.copyWith(
            status: OccurrenceStatus.scheduled,
            completedAt: null,
            completedBy: null,
          ),
        ],
        stats: stats.current,
        availability: AvailabilityIndex.empty,
      );
      await controller.observe(
        familyId: familyId,
        memberId: memberId,
        today: today,
        settings: settings,
        monthItems: _items(today),
        stats: stats.current,
        availability: AvailabilityIndex.empty,
      );
      expect(
        container.read(celebrationControllerProvider),
        isA<CelebrationNone>(),
      );
    },
  );

  test('two sessions racing can celebrate only once', () async {
    final first = container.read(celebrationControllerProvider.notifier);
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final otherDevicePreferences = await SharedPreferences.getInstance();
    final second = _container(
      preferences: otherDevicePreferences,
      clock: clock,
      families: families,
      stats: stats,
      publicStats: _PublicStatsRepository(),
    );
    addTearDown(second.dispose);
    await Future.wait<void>([
      first.observe(
        familyId: familyId,
        memberId: memberId,
        today: today,
        settings: settings,
        monthItems: _items(today),
        stats: null,
        availability: AvailabilityIndex.empty,
      ),
      second
          .read(celebrationControllerProvider.notifier)
          .observe(
            familyId: familyId,
            memberId: memberId,
            today: today,
            settings: settings,
            monthItems: _items(today),
            stats: null,
            availability: AvailabilityIndex.empty,
          ),
    ]);

    final firstState = container.read(celebrationControllerProvider);
    final secondState = second.read(celebrationControllerProvider);
    expect(
      [firstState, secondState].whereType<CelebrationShown>(),
      hasLength(1),
    );
    expect(
      [firstState, secondState].whereType<CelebrationQuietDone>(),
      hasLength(1),
    );
  });

  test('family day rollover permits one new celebration', () async {
    final controller = container.read(celebrationControllerProvider.notifier);
    await controller.observe(
      familyId: familyId,
      memberId: memberId,
      today: today,
      settings: settings,
      monthItems: _items(today),
      stats: null,
      availability: AvailabilityIndex.empty,
    );
    expect(
      container.read(celebrationControllerProvider),
      isA<CelebrationShown>(),
    );

    final tomorrow = today.addDays(1);
    clock.setTo(DateTime.utc(2026, 11, 7, 14));
    await controller.observe(
      familyId: familyId,
      memberId: memberId,
      today: tomorrow,
      settings: settings,
      monthItems: _items(tomorrow),
      stats: stats.current,
      availability: AvailabilityIndex.empty,
    );
    expect(
      container.read(celebrationControllerProvider),
      isA<CelebrationShown>(),
    );
    expect(
      (container.read(
        celebrationControllerProvider,
      ) as CelebrationShown).dateKey,
      tomorrow,
    );
  });

  test(
    'an offline stats write still persists the local once-per-day guard',
    () async {
      stats.failWrites = true;
      await container
          .read(celebrationControllerProvider.notifier)
          .observe(
            familyId: familyId,
            memberId: memberId,
            today: today,
            settings: settings,
            monthItems: _items(today),
            stats: null,
            availability: AvailabilityIndex.empty,
          );

      expect(
        container.read(celebrationControllerProvider),
        isA<CelebrationShown>(),
      );
      expect(
        preferences.getString('celebrated_date:family:member'),
        '2026-11-06',
      );
    },
  );

  testWidgets('queues over a dialog and presents only once', (tester) async {
    tester.view
      ..physicalSize = const Size(400, 900)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final controller = container.read(celebrationControllerProvider.notifier);
    final items = _items(today);
    await controller.observe(
      familyId: familyId,
      memberId: memberId,
      today: today,
      settings: settings,
      monthItems: [
        ...items.take(2),
        items.last.copyWith(
          status: OccurrenceStatus.scheduled,
          completedAt: null,
          completedBy: null,
        ),
      ],
      stats: null,
      availability: AvailabilityIndex.empty,
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: buildThemeData(modernLightSpec),
          locale: const Locale('en'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: CelebrationHost(
            child: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  key: const Key('open_dialog'),
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (context) => AlertDialog(
                      content: const Text('Blocking dialog'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Close dialog'),
                        ),
                      ],
                    ),
                  ),
                  child: const Text('Open dialog'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('open_dialog')));
    await tester.pumpAndSettle();
    await controller.observe(
      familyId: familyId,
      memberId: memberId,
      today: today,
      settings: settings,
      monthItems: items,
      stats: stats.current,
      availability: AvailabilityIndex.empty,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Today’s chores are complete!'), findsNothing);

    await tester.tap(find.text('Close dialog'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Today’s chores are complete!'), findsOneWidget);

    await tester.ensureVisible(find.text('Done'));
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Today’s chores are complete!'), findsNothing);
  });

  testWidgets('waits until the keyboard is closed', (tester) async {
    tester.view
      ..physicalSize = const Size(400, 2000)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final controller = container.read(celebrationControllerProvider.notifier);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: buildThemeData(modernLightSpec),
          locale: const Locale('en'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: const CelebrationHost(child: Scaffold(body: SizedBox.shrink())),
        ),
      ),
    );
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    await tester.pump();
    await controller.observe(
      familyId: familyId,
      memberId: memberId,
      today: today,
      settings: settings,
      monthItems: _items(today),
      stats: null,
      availability: AvailabilityIndex.empty,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Today’s chores are complete!'), findsNothing);

    tester.view.viewInsets = const FakeViewPadding();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Today’s chores are complete!'), findsOneWidget);

    Navigator.of(tester.element(find.text('Done'))).pop();
    await tester.pumpAndSettle();
  });
}

ProviderContainer _container({
  required SharedPreferences preferences,
  required Clock clock,
  required InMemoryBackend families,
  required _StatsRepository stats,
  required _PublicStatsRepository publicStats,
}) {
  final sync = SyncMemberStats(
    families: families,
    stats: stats,
    publicStats: publicStats,
    previousMonthItemsLoader: (_, _) async =>
        const Success<List<ChoreOccurrence>>(<ChoreOccurrence>[]),
  );
  final mark = MarkCelebrated(families: families, stats: stats);
  return ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(preferences),
      clockProvider.overrideWithValue(clock),
      currentFamilyIdProvider.overrideWithValue('family'),
      engagementSettingsProvider('family').overrideWith(
        (ref) => Stream<EngagementSettings>.value(
          defaultEngagementSettings(
            startedOn: DateKey(2026, 11, 1),
            graceMinutes: 30,
          ),
        ),
      ),
      syncMemberStatsProvider.overrideWithValue(sync),
      markCelebratedProvider.overrideWithValue(mark),
    ],
  );
}

List<ChoreOccurrence> _items(DateKey day) => <ChoreOccurrence>[
  for (var index = 0; index < 3; index++)
    engagementOccurrence(
      id: 'item-$index',
      day: day,
      completedAt: DateTime.utc(day.year, day.month, day.day, 13, 55 + index),
    ),
];

final class _StatsRepository implements MemberStatsRepository {
  MemberStats? current;
  bool failWrites = false;

  @override
  Stream<MemberStats?> watch(
    String familyId,
    String memberId, {
    required DateKey defaultStartedOn,
  }) => Stream<MemberStats?>.value(current);

  @override
  Future<Result<MemberStats?>> get(
    String familyId,
    String memberId, {
    required DateKey defaultStartedOn,
  }) async => Success<MemberStats?>(current);

  @override
  Future<Result<void>> save(
    String familyId,
    String memberId,
    MemberStats stats, {
    required PublicStats? publicStats,
  }) async {
    if (failWrites) return const Failure<void>(Network());
    current = stats;
    return const Success<void>(null);
  }

  @override
  Future<Result<bool>> claimCelebration(
    String familyId,
    String memberId, {
    required DateKey dateKey,
    required DateKey defaultStartedOn,
  }) async {
    if (failWrites) return const Failure<bool>(Network());
    final previous = current ?? MemberStats.empty(startedOn: defaultStartedOn);
    final celebrated = previous.lastCelebratedDateKey;
    if (celebrated != null && !dateKey.isAfter(celebrated)) {
      return const Success<bool>(false);
    }
    current = previous.copyWith(lastCelebratedDateKey: dateKey);
    return const Success<bool>(true);
  }
}

final class _PublicStatsRepository implements PublicStatsRepository {
  @override
  Stream<PublicStats?> watch(String familyId, String memberId) =>
      Stream<PublicStats?>.value(null);

  @override
  Stream<Map<String, PublicStats>> watchFamily(String familyId) =>
      Stream<Map<String, PublicStats>>.value(const <String, PublicStats>{});

  @override
  Future<Result<PublicStats?>> get(String familyId, String memberId) async =>
      const Success<PublicStats?>(null);
}
