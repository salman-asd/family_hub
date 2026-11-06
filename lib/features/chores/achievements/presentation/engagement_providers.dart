import 'dart:developer' as developer;

import 'package:family_hub/app/routing/session_phase.dart';
import 'package:family_hub/app/routing/session_providers.dart';
import 'package:family_hub/core/firebase/query_limits.dart';
import 'package:family_hub/core/utils/clock_provider.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/features/chores/achievements/domain/levels/level_table.dart';
import 'package:family_hub/features/chores/achievements/domain/default_engagement_settings.dart';
import 'package:family_hub/features/chores/achievements/domain/engagement_settings.dart';
import 'package:family_hub/features/chores/achievements/domain/engagement_settings_repository.dart';
import 'package:family_hub/features/chores/achievements/domain/member_stats.dart';
import 'package:family_hub/features/chores/achievements/domain/member_stats_repository.dart';
import 'package:family_hub/features/chores/achievements/domain/public_stats.dart';
import 'package:family_hub/features/chores/achievements/domain/public_stats_repository.dart';
import 'package:family_hub/features/chores/achievements/domain/usecases/mark_celebrated.dart';
import 'package:family_hub/features/chores/achievements/domain/usecases/set_stats_sharing.dart';
import 'package:family_hub/features/chores/achievements/domain/usecases/sync_member_stats.dart';
import 'package:family_hub/features/chores/achievements/domain/usecases/update_engagement_settings.dart';
import 'package:family_hub/features/chores/availability/domain/availability_index.dart';
import 'package:family_hub/features/chores/availability/presentation/availability_providers.dart';
import 'package:family_hub/features/chores/occurrences/presentation/occurrence_providers.dart';
import 'package:family_hub/features/chores/occurrences/presentation/today_providers.dart';
import 'package:family_hub/features/chores/settings/presentation/chore_settings_providers.dart';
import 'package:family_hub/features/chores/achievements/presentation/stats_sync_controller.dart';
import 'package:family_hub/features/family/presentation/family_providers.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final engagementSettingsRepositoryProvider =
    Provider<EngagementSettingsRepository>(
      (ref) => throw UnimplementedError(
        'engagementSettingsRepositoryProvider must be overridden in bootstrap.dart.',
      ),
    );

final memberStatsRepositoryProvider = Provider<MemberStatsRepository>(
  (ref) => throw UnimplementedError(
    'memberStatsRepositoryProvider must be overridden in bootstrap.dart.',
  ),
);

final publicStatsRepositoryProvider = Provider<PublicStatsRepository>(
  (ref) => throw UnimplementedError(
    'publicStatsRepositoryProvider must be overridden in bootstrap.dart.',
  ),
);

final engagementSettingsProvider = StreamProvider.autoDispose
    .family<EngagementSettings, String>((ref, familyId) {
      final today = ref.watch(familyDateKeysProvider).today();
      final defaults = defaultEngagementSettings(
        startedOn: today,
        graceMinutes: ref.watch(choreSettingsProvider).overdueGraceMinutes,
      );
      return ref
          .watch(engagementSettingsRepositoryProvider)
          .watch(familyId, defaults: defaults);
    });

final memberStatsProvider = StreamProvider.autoDispose
    .family<MemberStats?, String>((ref, memberId) {
      final familyId = ref.watch(currentFamilyIdProvider);
      if (familyId == null) return Stream.value(null);
      final settings = ref.watch(engagementSettingsProvider(familyId)).value;
      final today = ref.watch(familyDateKeysProvider).today();
      final defaults =
          settings ??
          defaultEngagementSettings(
            startedOn: today,
            graceMinutes: ref.watch(choreSettingsProvider).overdueGraceMinutes,
          );
      return ref
          .watch(memberStatsRepositoryProvider)
          .watch(familyId, memberId, defaultStartedOn: defaults.startedOn);
    });

final publicStatsProvider = StreamProvider.autoDispose
    .family<PublicStats?, String>((ref, memberId) {
      final familyId = ref.watch(currentFamilyIdProvider);
      if (familyId == null) return Stream.value(null);
      final settings = ref.watch(engagementSettingsProvider(familyId)).value;
      if (settings?.statsVisibility != StatsVisibility.levels) {
        return Stream.value(null);
      }
      return ref.watch(publicStatsRepositoryProvider).watch(familyId, memberId);
    });

final levelProvider = Provider.autoDispose.family<int?, String>(
  (ref, memberId) => ref.watch(memberStatsProvider(memberId)).value?.level,
);

final badgesProvider = Provider.autoDispose
    .family<Map<String, BadgeEarned>, String>(
      (ref, memberId) =>
          ref.watch(memberStatsProvider(memberId)).value?.badges ??
          const <String, BadgeEarned>{},
    );

final hubLevelViewProvider = Provider.autoDispose
    .family<LevelProgress?, String>((ref, memberId) {
      final familyId = ref.watch(currentFamilyIdProvider);
      if (familyId == null) return null;
      final stats = ref.watch(memberStatsProvider(memberId)).value;
      final settings = ref.watch(engagementSettingsProvider(familyId)).value;
      if (stats == null || settings == null) return null;
      return LevelTable(settings.levels).progress(stats.totalPoints);
    });

final previousMonthItemsLoader = Provider<PreviousMonthItemsLoader>((ref) {
  final occurrences = ref.watch(occurrenceRepositoryProvider);
  return (familyId, month) {
    final range = monthRange(month);
    return occurrences.listRangeOnce(
      familyId,
      from: range.start,
      to: range.end,
      limit: kMaxOccurrencesPerMonth,
    );
  };
});

final syncMemberStatsProvider = Provider<SyncMemberStats>(
  (ref) => SyncMemberStats(
    families: ref.watch(familyRepositoryProvider),
    stats: ref.watch(memberStatsRepositoryProvider),
    publicStats: ref.watch(publicStatsRepositoryProvider),
    previousMonthItemsLoader: ref.watch(previousMonthItemsLoader),
  ),
);

final markCelebratedProvider = Provider<MarkCelebrated>(
  (ref) => MarkCelebrated(
    families: ref.watch(familyRepositoryProvider),
    stats: ref.watch(memberStatsRepositoryProvider),
  ),
);

final setStatsSharingProvider = Provider<SetStatsSharing>(
  (ref) => SetStatsSharing(
    families: ref.watch(familyRepositoryProvider),
    stats: ref.watch(memberStatsRepositoryProvider),
  ),
);

final updateEngagementSettingsProvider = Provider<UpdateEngagementSettings>(
  (ref) => UpdateEngagementSettings(
    families: ref.watch(familyRepositoryProvider),
    settingsRepository: ref.watch(engagementSettingsRepositoryProvider),
    clock: ref.watch(clockProvider),
    newId: ref.watch(idGeneratorProvider),
  ),
);

final class _StatsLifecycleObserver extends WidgetsBindingObserver {
  _StatsLifecycleObserver(this.onResumed);

  final VoidCallback onResumed;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) onResumed();
  }
}

/// Starts a sync after the live month and family settings are available, and
/// debounces every chore-progress change. Older months are queried once each.
final statsSyncControllerProvider = Provider<StatsSyncController>((ref) {
  Future<void> sync() async {
    final familyId = ref.read(currentFamilyIdProvider);
    final memberId = ref.read(currentUidProvider);
    if (familyId == null ||
        memberId == null ||
        ref.read(sessionPhaseProvider) != SessionPhase.active) {
      return;
    }
    final settings = ref.read(engagementSettingsProvider(familyId)).value;
    if (settings == null || !settings.enabled) return;
    final absences = ref.read(availabilityProvider);
    if (!absences.hasValue) return;
    final availability = AvailabilityIndex.fromRecords(absences.requireValue);
    final today = ref.read(familyDateKeysProvider).today();
    final month = ref.read(monthOccurrencesProvider(today.monthKey));
    if (!month.hasValue || month.requireValue.truncated) return;

    final result = await ref.read(syncMemberStatsProvider)(
      familyId: familyId,
      memberId: memberId,
      today: today,
      settings: settings,
      currentMonthItems: month.requireValue.items,
      absenceNeutral: (item) =>
          item.assigneeId != null &&
          availability.isUnavailable(item.assigneeId!, item.dateKey),
    );
    final failure = result.failureOrNull;
    if (failure != null) {
      throw StateError('Could not synchronize member stats: $failure');
    }
  }

  final controller = StatsSyncController(
    sync: sync,
    onError: (error, stackTrace) => developer.log(
      'Engagement stats synchronization failed',
      name: 'family_hub',
      error: error,
      stackTrace: stackTrace,
      level: 1000,
    ),
  );
  ref.onDispose(controller.dispose);
  return controller;
});

final statsSyncOrchestrationProvider = Provider<void>((ref) {
  final controller = ref.watch(statsSyncControllerProvider);
  final observer = _StatsLifecycleObserver(
    () => controller.onResumed(ref.read(clockProvider).nowUtc()),
  );
  WidgetsBinding.instance.addObserver(observer);
  ref.onDispose(() => WidgetsBinding.instance.removeObserver(observer));

  final phase = ref.watch(sessionPhaseProvider);
  final familyId = ref.watch(currentFamilyIdProvider);
  final memberId = ref.watch(currentUidProvider);
  final today = ref.watch(familyDateKeysProvider).today();
  ref.watch(todayProgressProvider);
  if (phase == SessionPhase.active && familyId != null && memberId != null) {
    ref.watch(engagementSettingsProvider(familyId));
    ref.watch(monthOccurrencesProvider(today.monthKey));
    ref.watch(availabilityProvider);
    controller.schedule();
  }
});
