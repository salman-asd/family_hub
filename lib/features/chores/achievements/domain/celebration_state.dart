import 'package:family_hub/core/utils/date_key.dart';

enum CelebrationDecision { none, celebrate, quietDone }

final class MineToday {
  const MineToday({
    required this.done,
    required this.total,
    this.lastCompletedAt,
  }) : assert(done >= 0),
       assert(total >= 0),
       assert(done <= total);

  final int done;
  final int total;
  final DateTime? lastCompletedAt;

  bool get isComplete => total > 0 && done == total;

  @override
  bool operator ==(Object other) =>
      other is MineToday &&
      other.done == done &&
      other.total == total &&
      other.lastCompletedAt == lastCompletedAt;

  @override
  int get hashCode => Object.hash(done, total, lastCompletedAt);
}

final class CelebrationInput {
  const CelebrationInput({
    required this.todayKey,
    required this.mineToday,
    required this.sessionStartedAt,
    required this.sawIncompleteThisSession,
    required this.lastCelebratedLocal,
    required this.lastCelebratedStats,
    required this.engagementEnabled,
    required this.celebrationEnabled,
    required this.nowMinusLastCompletion,
  });

  final DateKey todayKey;
  final MineToday mineToday;
  final DateTime sessionStartedAt;
  final bool sawIncompleteThisSession;
  final DateKey? lastCelebratedLocal;
  final DateKey? lastCelebratedStats;
  final bool engagementEnabled;
  final bool celebrationEnabled;
  final Duration? nowMinusLastCompletion;
}

abstract final class CelebrationEngine {
  static const Duration recentCompletionWindow = Duration(minutes: 30);

  static CelebrationDecision decide(CelebrationInput input) {
    if (!input.engagementEnabled ||
        !input.celebrationEnabled ||
        !input.mineToday.isComplete) {
      return CelebrationDecision.none;
    }

    if (input.lastCelebratedLocal == input.todayKey) {
      return CelebrationDecision.none;
    }
    if (input.lastCelebratedStats == input.todayKey) {
      return CelebrationDecision.quietDone;
    }

    final age = input.nowMinusLastCompletion;
    final recent =
        age != null && !age.isNegative && age <= recentCompletionWindow;
    return input.sawIncompleteThisSession || recent
        ? CelebrationDecision.celebrate
        : CelebrationDecision.quietDone;
  }
}

sealed class CelebrationState {
  const CelebrationState();
}

final class CelebrationNone extends CelebrationState {
  const CelebrationNone();
}

final class CelebrationQuietDone extends CelebrationState {
  const CelebrationQuietDone(this.dateKey);

  final DateKey dateKey;

  @override
  bool operator ==(Object other) =>
      other is CelebrationQuietDone && other.dateKey == dateKey;

  @override
  int get hashCode => dateKey.hashCode;
}

final class CelebrationShown extends CelebrationState {
  CelebrationShown({
    required this.dateKey,
    required this.levelBefore,
    required this.levelAfter,
    required Iterable<String> newBadges,
    required this.pointsToday,
  }) : newBadges = List<String>.unmodifiable(newBadges);

  final DateKey dateKey;
  final int levelBefore;
  final int levelAfter;
  final List<String> newBadges;
  final int pointsToday;

  @override
  bool operator ==(Object other) =>
      other is CelebrationShown &&
      other.dateKey == dateKey &&
      other.levelBefore == levelBefore &&
      other.levelAfter == levelAfter &&
      _sameList(other.newBadges, newBadges) &&
      other.pointsToday == pointsToday;

  @override
  int get hashCode => Object.hash(
    dateKey,
    levelBefore,
    levelAfter,
    Object.hashAll(newBadges),
    pointsToday,
  );
}

bool _sameList(List<String> first, List<String> second) {
  if (first.length != second.length) return false;
  for (var index = 0; index < first.length; index++) {
    if (first[index] != second[index]) return false;
  }
  return true;
}
