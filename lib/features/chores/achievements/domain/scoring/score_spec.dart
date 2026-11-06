import 'package:family_hub/features/chores/templates/domain/template_enums.dart';

final class ScoreSpec {
  ScoreSpec({
    required Map<Difficulty, int> pointBases,
    required this.latePermille,
    required this.verifiedPermille,
    required this.coverBonusPermille,
    required this.graceMinutes,
    required this.version,
  }) : pointBases = Map<Difficulty, int>.unmodifiable(pointBases) {
    if (Difficulty.values.any(
      (difficulty) => !this.pointBases.containsKey(difficulty),
    )) {
      throw ArgumentError.value(
        pointBases,
        'pointBases',
        'Must include every difficulty',
      );
    }
    if (this.pointBases.values.any((points) => points < 0) ||
        latePermille < 0 ||
        verifiedPermille < 0 ||
        coverBonusPermille < 0 ||
        graceMinutes < 0 ||
        version < 1) {
      throw ArgumentError(
        'Score values must be non-negative and version positive',
      );
    }
  }

  final Map<Difficulty, int> pointBases;
  final int latePermille;
  final int verifiedPermille;
  final int coverBonusPermille;

  /// Provided from `ChoreSettings.overdueGraceMinutes`; not a second setting.
  final int graceMinutes;
  final int version;

  ScoreSpec copyWith({
    Map<Difficulty, int>? pointBases,
    int? latePermille,
    int? verifiedPermille,
    int? coverBonusPermille,
    int? graceMinutes,
    int? version,
  }) => ScoreSpec(
    pointBases: pointBases ?? this.pointBases,
    latePermille: latePermille ?? this.latePermille,
    verifiedPermille: verifiedPermille ?? this.verifiedPermille,
    coverBonusPermille: coverBonusPermille ?? this.coverBonusPermille,
    graceMinutes: graceMinutes ?? this.graceMinutes,
    version: version ?? this.version,
  );

  @override
  bool operator ==(Object other) =>
      other is ScoreSpec &&
      _sameBases(other.pointBases, pointBases) &&
      other.latePermille == latePermille &&
      other.verifiedPermille == verifiedPermille &&
      other.coverBonusPermille == coverBonusPermille &&
      other.graceMinutes == graceMinutes &&
      other.version == version;

  @override
  int get hashCode => Object.hash(
    Object.hashAllUnordered(
      pointBases.entries.map((entry) => Object.hash(entry.key, entry.value)),
    ),
    latePermille,
    verifiedPermille,
    coverBonusPermille,
    graceMinutes,
    version,
  );
}

bool _sameBases(Map<Difficulty, int> first, Map<Difficulty, int> second) {
  if (first.length != second.length) return false;
  return first.entries.every((entry) => second[entry.key] == entry.value);
}
