final class EngagementLevel {
  const EngagementLevel({
    required this.id,
    required this.minPoints,
    required this.nameBn,
    required this.nameEn,
  });

  final String id;
  final int minPoints;
  final String nameBn;
  final String nameEn;

  EngagementLevel copyWith({
    String? id,
    int? minPoints,
    String? nameBn,
    String? nameEn,
  }) => EngagementLevel(
    id: id ?? this.id,
    minPoints: minPoints ?? this.minPoints,
    nameBn: nameBn ?? this.nameBn,
    nameEn: nameEn ?? this.nameEn,
  );

  @override
  bool operator ==(Object other) =>
      other is EngagementLevel &&
      other.id == id &&
      other.minPoints == minPoints &&
      other.nameBn == nameBn &&
      other.nameEn == nameEn;

  @override
  int get hashCode => Object.hash(id, minPoints, nameBn, nameEn);
}

final class LevelProgress {
  const LevelProgress({
    required this.level,
    required this.into,
    required this.needed,
    required this.fraction,
  });

  final EngagementLevel level;
  final int into;
  final int needed;

  /// Integer progress in permille, from 0 to 1000.
  final int fraction;

  LevelProgress copyWith({
    EngagementLevel? level,
    int? into,
    int? needed,
    int? fraction,
  }) => LevelProgress(
    level: level ?? this.level,
    into: into ?? this.into,
    needed: needed ?? this.needed,
    fraction: fraction ?? this.fraction,
  );

  @override
  bool operator ==(Object other) =>
      other is LevelProgress &&
      other.level == level &&
      other.into == into &&
      other.needed == needed &&
      other.fraction == fraction;

  @override
  int get hashCode => Object.hash(level, into, needed, fraction);
}

final class LevelTable {
  LevelTable(Iterable<EngagementLevel> levels)
    : levels = List<EngagementLevel>.unmodifiable(levels) {
    if (this.levels.isEmpty || this.levels.length > 12) {
      throw ArgumentError.value(
        this.levels.length,
        'levels',
        'Expected 1-12 levels',
      );
    }
    if (this.levels.first.minPoints != 0) {
      throw ArgumentError('The first level must start at zero points');
    }
    final ids = <String>{};
    for (var index = 0; index < this.levels.length; index++) {
      final level = this.levels[index];
      if (level.id.isEmpty ||
          level.nameBn.isEmpty ||
          level.nameEn.isEmpty ||
          level.minPoints < 0 ||
          !ids.add(level.id) ||
          (index > 0 && level.minPoints <= this.levels[index - 1].minPoints)) {
        throw ArgumentError(
          'Levels must have unique ids and ascending thresholds',
        );
      }
    }
  }

  final List<EngagementLevel> levels;

  int levelFor(int points) {
    if (points < 0) throw ArgumentError.value(points, 'points');
    var index = 0;
    for (var next = 1; next < levels.length; next++) {
      if (points < levels[next].minPoints) break;
      index = next;
    }
    return index + 1;
  }

  EngagementLevel definitionFor(int points) => levels[levelFor(points) - 1];

  LevelProgress progress(int points) {
    final levelIndex = levelFor(points) - 1;
    final level = levels[levelIndex];
    final into = points - level.minPoints;
    if (levelIndex == levels.length - 1) {
      return LevelProgress(level: level, into: into, needed: 0, fraction: 1000);
    }

    final needed = levels[levelIndex + 1].minPoints - level.minPoints;
    return LevelProgress(
      level: level,
      into: into,
      needed: needed,
      fraction: (into * 1000 ~/ needed).clamp(0, 1000),
    );
  }
}
