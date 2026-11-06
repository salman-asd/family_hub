final class PublicStats {
  PublicStats({required this.level, required Iterable<String> badgeIds})
    : badgeIds = List<String>.unmodifiable(badgeIds) {
    if (level < 0 || level > 12 || this.badgeIds.length > 12) {
      throw ArgumentError('Public stats exceed their bounded shape.');
    }
  }

  final int level;
  final List<String> badgeIds;

  @override
  bool operator ==(Object other) =>
      other is PublicStats &&
      other.level == level &&
      _sameList(other.badgeIds, badgeIds);

  @override
  int get hashCode => Object.hash(level, Object.hashAll(badgeIds));
}

bool _sameList(List<String> first, List<String> second) {
  if (first.length != second.length) return false;
  for (var index = 0; index < first.length; index++) {
    if (first[index] != second[index]) return false;
  }
  return true;
}
