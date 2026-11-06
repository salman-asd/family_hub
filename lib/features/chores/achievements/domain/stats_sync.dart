import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/features/chores/achievements/domain/badges/badge_evaluator.dart';
import 'package:family_hub/features/chores/achievements/domain/engagement_settings.dart';
import 'package:family_hub/features/chores/achievements/domain/levels/level_table.dart';
import 'package:family_hub/features/chores/achievements/domain/member_stats.dart';
import 'package:family_hub/features/chores/achievements/domain/scoring/score_calculator.dart';
import 'package:family_hub/features/chores/achievements/domain/scoring/streak_calculator.dart';
import 'package:family_hub/features/chores/occurrences/domain/chore_occurrence.dart';

const int kMaxStatsMonths = 40;
const String kLegacyStatsMonth = 'legacy';

abstract final class StatsSync {
  static MemberStats compute({
    required MemberStats previous,
    required List<ChoreOccurrence> currentMonthItems,

    /// Include each successfully loaded month, even when it contains no items.
    required Map<MonthKey, List<ChoreOccurrence>> finalisingMonths,
    required EngagementSettings spec,
    required DateKey today,
    required String viewerId,
    bool Function(ChoreOccurrence item) absenceNeutral = _notNeutral,
  }) {
    final startedOn = previous.startedOn.isAfter(spec.startedOn)
        ? previous.startedOn
        : spec.startedOn;
    final monthly = Map<String, MonthlyStats>.of(previous.monthly);
    final firstMonth = startedOn.monthKey;
    final lastFinalisable = today.monthKey.addMonths(-1);
    final retainedMonths =
        monthly.keys.where((key) => key != kLegacyStatsMonth).toList()..sort();
    final oldestRetainedMonth = retainedMonths.firstOrNull;

    final monthsToFinalise = finalisingMonths.keys.toList()
      ..sort((first, second) => first.compareTo(second));
    for (final month in monthsToFinalise) {
      if (month.compareTo(firstMonth) < 0 ||
          month.compareTo(lastFinalisable) > 0 ||
          (monthly.containsKey(kLegacyStatsMonth) &&
              oldestRetainedMonth != null &&
              month.toString().compareTo(oldestRetainedMonth) < 0)) {
        continue;
      }
      final key = month.toString();
      final stored = monthly[key];
      if (stored?.isFinal == true) continue;
      final computed = _computeMonth(
        finalisingMonths[month] ?? const <ChoreOccurrence>[],
        month,
        spec,
        viewerId,
        startedOn,
        absenceNeutral,
      );
      monthly[key] = (stored ?? _zeroMonth(spec.scoreSpec.version)).maxWith(
        computed,
        finalized: true,
      );
    }

    final currentMonth = today.monthKey;
    final currentKey = currentMonth.toString();
    final storedCurrent = monthly[currentKey];
    if (storedCurrent?.isFinal != true) {
      final computedCurrent = _computeMonth(
        currentMonthItems,
        currentMonth,
        spec,
        viewerId,
        startedOn,
        absenceNeutral,
        finalized: false,
      );
      monthly[currentKey] =
          (storedCurrent ?? _zeroMonth(spec.scoreSpec.version)).maxWith(
            computedCurrent,
            finalized: false,
          );
    }

    _foldOldMonths(monthly);
    final totals = _totals(monthly);
    final streakFacts = StreakDayFacts.fromOccurrences(
      startedOn: startedOn,
      today: today,
      items: <ChoreOccurrence>[
        ...finalisingMonths.values.expand((items) => items),
        ...currentMonthItems,
      ],
      viewerId: viewerId,
      absenceNeutral: absenceNeutral,
    );
    final streak = StreakCalculator.advance(previous.streak, streakFacts);
    final levelTable = LevelTable(spec.levels);
    final statsWithoutBadges = MemberStats(
      totalPoints: totals.points,
      level: levelTable.levelFor(totals.points),
      completedTotal: totals.done,
      onTimeTotal: totals.onTime,
      coversTotal: totals.covers,
      verifiedCleanTotal: totals.verifiedClean,
      streak: streak,
      badges: previous.badges,
      monthly: monthly,
      processedThrough: today,
      lastCelebratedDateKey: previous.lastCelebratedDateKey,
      startedOn: previous.startedOn,
      sharing: previous.sharing,
    );
    final badgeIds = BadgeEvaluator.evaluate(
      statsWithoutBadges,
      spec.badgeThresholds,
    );
    final badges = Map<String, BadgeEarned>.of(previous.badges);
    for (final id in badgeIds) {
      badges.putIfAbsent(id, () => BadgeEarned(earnedAt: today));
    }

    return statsWithoutBadges.copyWith(badges: badges);
  }

  static MonthlyStats _computeMonth(
    Iterable<ChoreOccurrence> items,
    MonthKey month,
    EngagementSettings spec,
    String viewerId,
    DateKey startedOn,
    bool Function(ChoreOccurrence item) absenceNeutral, {
    bool finalized = true,
  }) {
    var points = 0;
    var done = 0;
    var onTime = 0;
    var covers = 0;
    var verifiedClean = 0;
    for (final item in items) {
      if (item.monthKey != month) continue;
      if (!item.isDeleted &&
          item.coverForId != null &&
          item.assigneeId == viewerId) {
        covers++;
      }
      final award = ScoreCalculator.calculate(
        item,
        spec.scoreSpec,
        viewerId: viewerId,
        startedOn: startedOn,
        absenceNeutral: absenceNeutral,
      );
      points += award.points;
      if (!award.completed) continue;
      done++;
      if (award.onTime) onTime++;
      if (award.verifiedClean) verifiedClean++;
    }
    return MonthlyStats(
      points: points,
      done: done,
      onTime: onTime,
      covers: covers,
      verifiedClean: verifiedClean,
      isFinal: finalized,
      specVersion: spec.scoreSpec.version,
    );
  }

  static void _foldOldMonths(Map<String, MonthlyStats> monthly) {
    final realMonths =
        monthly.keys.where((key) => key != kLegacyStatsMonth).toList()..sort();
    final keepCount = kMaxStatsMonths - 1;
    if (realMonths.length <= keepCount) return;

    var legacy = monthly[kLegacyStatsMonth] ?? _zeroMonth(1).copyWithFinal();
    final foldedCount = realMonths.length - keepCount;
    for (final key in realMonths.take(foldedCount)) {
      legacy = _addMonths(legacy, monthly.remove(key)!);
    }
    monthly[kLegacyStatsMonth] = legacy;
  }

  static MonthlyStats _addMonths(MonthlyStats first, MonthlyStats second) =>
      MonthlyStats(
        points: first.points + second.points,
        done: first.done + second.done,
        onTime: first.onTime + second.onTime,
        covers: first.covers + second.covers,
        verifiedClean: first.verifiedClean + second.verifiedClean,
        isFinal: true,
        specVersion: first.specVersion,
      );

  static MonthlyStats _zeroMonth(int version) => MonthlyStats(
    points: 0,
    done: 0,
    onTime: 0,
    covers: 0,
    verifiedClean: 0,
    isFinal: false,
    specVersion: version,
  );

  static ({int points, int done, int onTime, int covers, int verifiedClean})
  _totals(Map<String, MonthlyStats> monthly) {
    var points = 0;
    var done = 0;
    var onTime = 0;
    var covers = 0;
    var verifiedClean = 0;
    for (final value in monthly.values) {
      points += value.points;
      done += value.done;
      onTime += value.onTime;
      covers += value.covers;
      verifiedClean += value.verifiedClean;
    }
    return (
      points: points,
      done: done,
      onTime: onTime,
      covers: covers,
      verifiedClean: verifiedClean,
    );
  }
}

extension on MonthlyStats {
  MonthlyStats copyWithFinal() => MonthlyStats(
    points: points,
    done: done,
    onTime: onTime,
    covers: covers,
    verifiedClean: verifiedClean,
    isFinal: true,
    specVersion: specVersion,
  );
}

bool _notNeutral(ChoreOccurrence _) => false;
