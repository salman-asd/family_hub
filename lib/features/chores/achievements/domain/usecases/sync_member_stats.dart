import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/core/firebase/query_limits.dart'
    hide kMaxStatsMonths;
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/features/chores/achievements/domain/engagement_settings.dart';
import 'package:family_hub/features/chores/achievements/domain/member_stats.dart';
import 'package:family_hub/features/chores/achievements/domain/member_stats_repository.dart';
import 'package:family_hub/features/chores/achievements/domain/public_stats.dart';
import 'package:family_hub/features/chores/achievements/domain/public_stats_repository.dart';
import 'package:family_hub/features/chores/achievements/domain/stats_sync.dart';
import 'package:family_hub/features/chores/occurrences/domain/chore_occurrence.dart';
import 'package:family_hub/features/family/domain/family_repository.dart';
import 'package:family_hub/features/family/domain/permission_access.dart';

typedef PreviousMonthItemsLoader =
    Future<Result<List<ChoreOccurrence>>> Function(
      String familyId,
      MonthKey month,
    );

final class SyncMemberStats {
  const SyncMemberStats({
    required this.families,
    required this.stats,
    required this.publicStats,
    required this.previousMonthItemsLoader,
  });

  final FamilyRepository families;
  final MemberStatsRepository stats;
  final PublicStatsRepository publicStats;
  final PreviousMonthItemsLoader previousMonthItemsLoader;

  Future<Result<MemberStats?>> call({
    required String familyId,
    required String memberId,
    required DateKey today,
    required EngagementSettings settings,
    required List<ChoreOccurrence> currentMonthItems,
    bool Function(ChoreOccurrence item)? absenceNeutral,
  }) async {
    final active = await requireActiveMember(
      families,
      familyId: familyId,
      actorUid: memberId,
    );
    final activeFailure = active.failureOrNull;
    if (activeFailure != null) {
      return Failure<MemberStats?>(activeFailure);
    }
    if (!settings.enabled) return const Success<MemberStats?>(null);

    if (currentMonthItems.length > kMaxOccurrencesPerMonth) {
      return const Failure<MemberStats?>(
        Validation('occurrences', 'too_many_for_stats_sync'),
      );
    }

    final previousResult = await stats.get(
      familyId,
      memberId,
      defaultStartedOn: settings.startedOn,
    );
    final previousFailure = previousResult.failureOrNull;
    if (previousFailure != null) {
      return Failure<MemberStats?>(previousFailure);
    }
    final previous =
        previousResult.valueOrNull ??
        MemberStats.empty(startedOn: settings.startedOn);
    if (previousResult.valueOrNull == null) {
      final initialized = await stats.save(
        familyId,
        memberId,
        previous,
        publicStats: null,
      );
      final initializeFailure = initialized.failureOrNull;
      if (initializeFailure != null) {
        return Failure<MemberStats?>(initializeFailure);
      }
    }
    final finalisingMonths = <MonthKey, List<ChoreOccurrence>>{};
    var firstMonth = previous.startedOn.monthKey;
    if (previous.monthly.containsKey(kLegacyStatsMonth)) {
      final retained =
          previous.monthly.keys
              .where((key) => key != kLegacyStatsMonth)
              .toList()
            ..sort();
      if (retained.isNotEmpty) {
        firstMonth = MonthKey.parse(retained.first).valueOrNull!;
      }
    }
    final settingsStart = settings.startedOn.monthKey;
    if (firstMonth.compareTo(settingsStart) < 0) firstMonth = settingsStart;
    final latestFinalisable = today.monthKey.addMonths(-1);
    var month = firstMonth;
    var scanned = 0;
    while (month.compareTo(latestFinalisable) <= 0 &&
        scanned < kMaxStatsMonths * 2 &&
        finalisingMonths.length < kMaxStatsMonths - 1) {
      scanned++;
      if (previous.monthly[month.toString()]?.isFinal == true) {
        month = month.addMonths(1);
        continue;
      }
      final loaded = await previousMonthItemsLoader(familyId, month);
      final loadFailure = loaded.failureOrNull;
      if (loadFailure != null) return Failure<MemberStats?>(loadFailure);
      final rows = loaded.valueOrNull!;
      if (rows.length >= kMaxOccurrencesPerMonth) {
        return const Failure<MemberStats?>(
          Validation('occurrences', 'month_at_limit'),
        );
      }
      finalisingMonths[month] = rows;
      month = month.addMonths(1);
    }

    final computed = StatsSync.compute(
      previous: previous,
      currentMonthItems: currentMonthItems,
      finalisingMonths: finalisingMonths,
      spec: settings,
      today: today,
      viewerId: memberId,
      absenceNeutral: absenceNeutral ?? _notNeutral,
    );
    final publicCard = _publicCard(computed, settings);
    if (computed == previous) {
      final publicResult = await publicStats.get(familyId, memberId);
      final publicFailure = publicResult.failureOrNull;
      if (publicFailure != null) {
        return Failure<MemberStats?>(publicFailure);
      }
      if (publicResult.valueOrNull == publicCard) {
        return Success<MemberStats?>(previous);
      }
    }

    final saved = await stats.save(
      familyId,
      memberId,
      computed,
      publicStats: publicCard,
    );
    final saveFailure = saved.failureOrNull;
    return saveFailure == null
        ? Success<MemberStats?>(computed)
        : Failure<MemberStats?>(saveFailure);
  }

  PublicStats? _publicCard(MemberStats stats, EngagementSettings settings) =>
      settings.statsVisibility == StatsVisibility.levels && stats.sharing
      ? PublicStats(
          level: stats.level,
          badgeIds: List<String>.unmodifiable(stats.badges.keys),
        )
      : null;
}

bool _notNeutral(ChoreOccurrence _) => false;
