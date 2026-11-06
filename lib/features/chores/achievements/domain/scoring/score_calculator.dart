import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/features/chores/achievements/domain/scoring/score_spec.dart';
import 'package:family_hub/features/chores/occurrences/domain/chore_occurrence.dart';
import 'package:family_hub/features/chores/occurrences/domain/effective_status.dart';
import 'package:family_hub/features/chores/occurrences/domain/occurrence_status.dart';

final class ScoreAward {
  const ScoreAward({
    required this.points,
    required this.completed,
    required this.onTime,
    required this.cover,
    required this.verifiedClean,
  });

  const ScoreAward.neutral()
    : points = 0,
      completed = false,
      onTime = false,
      cover = false,
      verifiedClean = false;

  final int points;
  final bool completed;
  final bool onTime;
  final bool cover;
  final bool verifiedClean;

  ScoreAward copyWith({
    int? points,
    bool? completed,
    bool? onTime,
    bool? cover,
    bool? verifiedClean,
  }) => ScoreAward(
    points: points ?? this.points,
    completed: completed ?? this.completed,
    onTime: onTime ?? this.onTime,
    cover: cover ?? this.cover,
    verifiedClean: verifiedClean ?? this.verifiedClean,
  );

  @override
  bool operator ==(Object other) =>
      other is ScoreAward &&
      other.points == points &&
      other.completed == completed &&
      other.onTime == onTime &&
      other.cover == cover &&
      other.verifiedClean == verifiedClean;

  @override
  int get hashCode =>
      Object.hash(points, completed, onTime, cover, verifiedClean);
}

abstract final class ScoreCalculator {
  static int pointsFor(
    ChoreOccurrence item,
    ScoreSpec spec, {
    required String viewerId,
    required DateKey startedOn,
    bool Function(ChoreOccurrence item) absenceNeutral = _notNeutral,
  }) => calculate(
    item,
    spec,
    viewerId: viewerId,
    startedOn: startedOn,
    absenceNeutral: absenceNeutral,
  ).points;

  static ScoreAward calculate(
    ChoreOccurrence item,
    ScoreSpec spec, {
    required String viewerId,
    required DateKey startedOn,
    bool Function(ChoreOccurrence item) absenceNeutral = _notNeutral,
  }) {
    if (item.isDeleted ||
        item.skipReason != null ||
        item.status == OccurrenceStatus.skipped ||
        item.assigneeId == null ||
        item.completedAt == null ||
        item.completedBy != viewerId ||
        item.dateKey.isBefore(startedOn) ||
        absenceNeutral(item)) {
      return const ScoreAward.neutral();
    }

    final status = effectiveStatus(item);
    if (status != ChoreStatus.completed && status != ChoreStatus.verified) {
      return const ScoreAward.neutral();
    }

    final base = spec.pointBases[item.difficulty]!;
    final onTime = !item.completedAt!.isAfter(
      item.dueAt.add(Duration(minutes: spec.graceMinutes)),
    );
    final verifiedClean =
        item.verifiedAt != null &&
        item.reopenCount == 0 &&
        item.subtasks.isNotEmpty &&
        item.subtasks.every(
          (subtask) => item.subtaskDone.containsKey(subtask.id),
        );
    final points = _roundHalfUp(
      base *
          (onTime ? 1000 : spec.latePermille) *
          (item.verifiedAt != null && item.reopenCount == 0
              ? spec.verifiedPermille
              : 1000),
      1000000,
    );
    final cover = item.coverForId != null && item.assigneeId == viewerId;
    final coverBonus = item.coverForId != null && item.completedBy == viewerId
        ? _roundHalfUp(base * spec.coverBonusPermille, 1000)
        : 0;

    return ScoreAward(
      points: points + coverBonus,
      completed: true,
      onTime: onTime,
      cover: cover,
      verifiedClean: verifiedClean,
    );
  }

  static int _roundHalfUp(int numerator, int denominator) =>
      (numerator + denominator ~/ 2) ~/ denominator;
}

bool _notNeutral(ChoreOccurrence _) => false;
