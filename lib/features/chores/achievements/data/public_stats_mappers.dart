import 'package:family_hub/core/firebase/base_mapper.dart';
import 'package:family_hub/features/chores/achievements/domain/public_stats.dart';

abstract final class PublicStatsMappers {
  static Map<String, dynamic> toMap(
    PublicStats stats,
    BaseDocumentMetadata metadata,
  ) => <String, dynamic>{
    'level': stats.level,
    'badgeIds': stats.badgeIds,
    ...BaseMapper.metadataToMap(metadata),
  };

  static PublicStats? fromMap(Map<String, dynamic>? map) {
    if (map == null || map['level'] is! int) return null;
    final badges = map['badgeIds'];
    return PublicStats(
      level: (map['level'] as int).clamp(0, 12),
      badgeIds: List<String>.unmodifiable(
        badges is List ? badges.whereType<String>().take(12) : const [],
      ),
    );
  }
}
