import 'dart:developer' as developer;

import 'package:family_hub/app/theme/theme_controller.dart';
import 'package:family_hub/core/utils/clock_provider.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/features/chores/achievements/domain/celebration_state.dart';
import 'package:family_hub/features/chores/achievements/domain/engagement_settings.dart';
import 'package:family_hub/features/chores/achievements/domain/levels/level_table.dart';
import 'package:family_hub/features/chores/achievements/domain/member_stats.dart';
import 'package:family_hub/features/chores/achievements/domain/scoring/score_calculator.dart';
import 'package:family_hub/features/chores/achievements/domain/scoring/streak_calculator.dart';
import 'package:family_hub/features/chores/achievements/presentation/celebration_prefs.dart';
import 'package:family_hub/features/chores/achievements/presentation/engagement_providers.dart';
import 'package:family_hub/features/chores/availability/domain/availability_index.dart';
import 'package:family_hub/features/chores/occurrences/domain/chore_occurrence.dart';
import 'package:family_hub/features/chores/occurrences/domain/effective_status.dart';
import 'package:family_hub/features/chores/occurrences/domain/occurrence_status.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final celebrationControllerProvider =
    NotifierProvider<CelebrationController, CelebrationState>(
      CelebrationController.new,
    );

final class CelebrationController extends Notifier<CelebrationState> {
  String? _familyId;
  String? _memberId;
  DateTime? _sessionStartedAt;
  DateKey? _observedDate;
  DateKey? _localCelebratedDate;
  bool _sawIncomplete = false;
  bool _inFlight = false;

  @override
  CelebrationState build() {
    _sessionStartedAt = ref.read(clockProvider).nowUtc();
    return const CelebrationNone();
  }

  void reset() {
    _familyId = null;
    _memberId = null;
    _sessionStartedAt = ref.read(clockProvider).nowUtc();
    _observedDate = null;
    _localCelebratedDate = null;
    _sawIncomplete = false;
    state = const CelebrationNone();
  }

  Future<void> observe({
    required String familyId,
    required String memberId,
    required DateKey today,
    required EngagementSettings settings,
    required List<ChoreOccurrence> monthItems,
    required MemberStats? stats,
    required AvailabilityIndex availability,
  }) async {
    if (_familyId != familyId || _memberId != memberId) {
      _familyId = familyId;
      _memberId = memberId;
      _sessionStartedAt = ref.read(clockProvider).nowUtc();
      _observedDate = null;
      _localCelebratedDate = null;
      _sawIncomplete = false;
      state = const CelebrationNone();
    }
    if (_observedDate != today) {
      _observedDate = today;
      _localCelebratedDate = null;
      _sawIncomplete = false;
      state = const CelebrationNone();
    }

    bool absenceNeutral(ChoreOccurrence item) =>
        availability.isUnavailable(item.assigneeId!, item.dateKey);
    final eligible = <ChoreOccurrence>[
      for (final item in monthItems)
        if (item.dateKey == today &&
            StreakCalculator.isEligible(
              item,
              startedOn: settings.startedOn,
              today: today,
              viewerId: memberId,
              absenceNeutral: absenceNeutral,
            ))
          item,
    ];
    var done = 0;
    DateTime? lastCompletedAt;
    for (final item in eligible) {
      final status = effectiveStatus(item);
      if (status != ChoreStatus.completed && status != ChoreStatus.verified) {
        continue;
      }
      done++;
      final completedAt = item.completedAt;
      if (completedAt != null &&
          (lastCompletedAt == null || completedAt.isAfter(lastCompletedAt))) {
        lastCompletedAt = completedAt;
      }
    }
    final progress = MineToday(
      done: done,
      total: eligible.length,
      lastCompletedAt: lastCompletedAt,
    );
    if (progress.total > 0 && !progress.isComplete) {
      _sawIncomplete = true;
      state = const CelebrationNone();
      return;
    }

    final now = ref.read(clockProvider).nowUtc();
    final age = lastCompletedAt == null
        ? null
        : now.difference(lastCompletedAt);
    final localDate =
        _localCelebratedDate ?? _readLocalDate(familyId, memberId);
    final decision = CelebrationEngine.decide(
      CelebrationInput(
        todayKey: today,
        mineToday: progress,
        sessionStartedAt: _sessionStartedAt!,
        sawIncompleteThisSession: _sawIncomplete,
        lastCelebratedLocal: localDate,
        lastCelebratedStats: stats?.lastCelebratedDateKey,
        engagementEnabled: settings.enabled,
        celebrationEnabled: settings.celebrationEnabled,
        nowMinusLastCompletion: age,
      ),
    );

    switch (decision) {
      case CelebrationDecision.none:
        if (!progress.isComplete) state = const CelebrationNone();
        break;
      case CelebrationDecision.quietDone:
        state = CelebrationQuietDone(today);
        break;
      case CelebrationDecision.celebrate:
        if (!_inFlight) {
          await _celebrate(
            familyId: familyId,
            memberId: memberId,
            today: today,
            settings: settings,
            monthItems: monthItems,
            stats: stats,
            eligibleItems: eligible,
            absenceNeutral: absenceNeutral,
          );
        }
        break;
    }
  }

  DateKey? _readLocalDate(String familyId, String memberId) {
    final prefs = CelebrationPrefs(ref.read(sharedPreferencesProvider));
    final date = prefs.lastCelebrated(familyId, memberId);
    _localCelebratedDate = date;
    return date;
  }

  Future<void> _celebrate({
    required String familyId,
    required String memberId,
    required DateKey today,
    required EngagementSettings settings,
    required List<ChoreOccurrence> monthItems,
    required MemberStats? stats,
    required List<ChoreOccurrence> eligibleItems,
    required bool Function(ChoreOccurrence item) absenceNeutral,
  }) async {
    _inFlight = true;
    _localCelebratedDate = today;
    try {
      var updatedStats = stats;
      try {
        final syncResult = await ref.read(syncMemberStatsProvider)(
          familyId: familyId,
          memberId: memberId,
          today: today,
          settings: settings,
          currentMonthItems: monthItems,
          absenceNeutral: absenceNeutral,
        );
        final syncFailure = syncResult.failureOrNull;
        if (syncFailure != null) {
          developer.log(
            'Could not synchronize stats before chore celebration',
            name: 'family_hub',
            error: syncFailure,
            level: 1000,
          );
        } else {
          updatedStats = syncResult.valueOrNull ?? updatedStats;
        }
      } on Object catch (error, stackTrace) {
        developer.log(
          'Could not synchronize stats before chore celebration',
          name: 'family_hub',
          error: error,
          stackTrace: stackTrace,
          level: 1000,
        );
      }

      final prefs = CelebrationPrefs(ref.read(sharedPreferencesProvider));
      try {
        final persisted = await prefs.markCelebrated(familyId, memberId, today);
        if (persisted) {
          // Persist locally before the server-side marker to guard against a
          // reopened screen replaying the animation.
          _localCelebratedDate = today;
        } else {
          developer.log(
            'Could not persist local celebration date',
            name: 'family_hub',
            level: 1000,
          );
        }
      } on Object catch (error, stackTrace) {
        developer.log(
          'Could not persist local celebration date',
          name: 'family_hub',
          error: error,
          stackTrace: stackTrace,
          level: 1000,
        );
      }

      try {
        final markResult = await ref.read(markCelebratedProvider)(
          familyId: familyId,
          memberId: memberId,
          dateKey: today,
          today: today,
          settings: settings,
        );
        final markFailure = markResult.failureOrNull;
        if (markFailure != null) {
          developer.log(
            'Could not record stats celebration date',
            name: 'family_hub',
            error: markFailure,
            level: 1000,
          );
        }
      } on Object catch (error, stackTrace) {
        developer.log(
          'Could not record stats celebration date',
          name: 'family_hub',
          error: error,
          stackTrace: stackTrace,
          level: 1000,
        );
      }

      final pointsToday = eligibleItems.fold<int>(
        0,
        (sum, item) =>
            sum +
            ScoreCalculator.pointsFor(
              item,
              settings.scoreSpec,
              viewerId: memberId,
              startedOn: settings.startedOn,
              absenceNeutral: absenceNeutral,
            ),
      );
      final beforePoints = stats?.totalPoints ?? 0;
      final afterPoints = updatedStats?.totalPoints ?? beforePoints;
      if (_familyId == familyId &&
          _memberId == memberId &&
          _observedDate == today) {
        state = CelebrationShown(
          dateKey: today,
          levelBefore: LevelTable(settings.levels).levelFor(beforePoints),
          levelAfter: LevelTable(settings.levels).levelFor(afterPoints),
          newBadges: <String>[
            for (final id in (updatedStats?.badges.keys ?? const <String>[]))
              if (stats?.badges.containsKey(id) != true) id,
          ]..sort(),
          pointsToday: pointsToday,
        );
      }
    } finally {
      _inFlight = false;
    }
  }
}
