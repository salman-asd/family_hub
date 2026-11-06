import 'package:family_hub/core/firebase/base_mapper.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/features/chores/achievements/domain/badges/badge_catalog.dart';
import 'package:family_hub/features/chores/achievements/domain/engagement_settings.dart';
import 'package:family_hub/features/chores/achievements/domain/levels/level_table.dart';
import 'package:family_hub/features/chores/achievements/domain/scoring/score_spec.dart';
import 'package:family_hub/features/chores/templates/domain/template_enums.dart';

abstract final class EngagementSettingsMappers {
  static Map<String, dynamic> toMap(
    EngagementSettings settings,
    BaseDocumentMetadata metadata,
  ) {
    return <String, dynamic>{
      'enabled': settings.enabled,
      'startedOn': settings.startedOn.toString(),
      'celebrationEnabled': settings.celebrationEnabled,
      'showHelpersHighlight': settings.showHelpersHighlight,
      'statsVisibility': settings.statsVisibility.id,
      'pointBases': <String, int>{
        for (final entry in settings.scoreSpec.pointBases.entries)
          entry.key.name: entry.value,
      },
      'latePermille': settings.scoreSpec.latePermille,
      'verifiedPermille': settings.scoreSpec.verifiedPermille,
      'coverBonusPermille': settings.scoreSpec.coverBonusPermille,
      'levels': <Map<String, Object?>>[
        for (final level in settings.levels)
          <String, Object?>{
            'id': level.id,
            'minPoints': level.minPoints,
            'nameBn': level.nameBn,
            'nameEn': level.nameEn,
          },
      ],
      'badgeThresholds': <String, int>{
        'consistentDays': settings.badgeThresholds.consistentDays,
        'reliablePercent': settings.badgeThresholds.reliablePercent,
        'reliableMinDone': settings.badgeThresholds.reliableMinDone,
        'helperCovers': settings.badgeThresholds.helperCovers,
        'detailCount': settings.badgeThresholds.detailCount,
      },
      'specVersion': settings.scoreSpec.version,
      ...BaseMapper.metadataToMap(metadata),
    };
  }

  static EngagementSettings fromMap(
    Map<String, dynamic>? map, {
    required EngagementSettings defaults,
  }) {
    if (map == null) return defaults;
    final bases = _map(map['pointBases']);
    final thresholds = _map(map['badgeThresholds']);
    final levels = _levels(map['levels'], defaults.levels);
    return EngagementSettings(
      enabled: _bool(map['enabled'], defaults.enabled),
      startedOn: _date(map['startedOn']) ?? defaults.startedOn,
      celebrationEnabled: _bool(
        map['celebrationEnabled'],
        defaults.celebrationEnabled,
      ),
      showHelpersHighlight: _bool(
        map['showHelpersHighlight'],
        defaults.showHelpersHighlight,
      ),
      statsVisibility: StatsVisibility.fromId(map['statsVisibility']),
      scoreSpec: ScoreSpec(
        pointBases: <Difficulty, int>{
          for (final difficulty in Difficulty.values)
            difficulty: _boundedInt(
              bases[difficulty.name],
              0,
              1000,
              defaults.scoreSpec.pointBases[difficulty]!,
            ),
        },
        latePermille: _boundedInt(
          map['latePermille'],
          0,
          2000,
          defaults.scoreSpec.latePermille,
        ),
        verifiedPermille: _boundedInt(
          map['verifiedPermille'],
          0,
          2000,
          defaults.scoreSpec.verifiedPermille,
        ),
        coverBonusPermille: _boundedInt(
          map['coverBonusPermille'],
          0,
          2000,
          defaults.scoreSpec.coverBonusPermille,
        ),
        graceMinutes: defaults.scoreSpec.graceMinutes,
        version: _boundedInt(map['specVersion'], 1, 999999, 1),
      ),
      levels: levels,
      badgeThresholds: BadgeThresholds(
        consistentDays: _boundedInt(
          thresholds['consistentDays'],
          1,
          365,
          defaults.badgeThresholds.consistentDays,
        ),
        reliablePercent: _boundedInt(
          thresholds['reliablePercent'],
          0,
          100,
          defaults.badgeThresholds.reliablePercent,
        ),
        reliableMinDone: _boundedInt(
          thresholds['reliableMinDone'],
          1,
          1000,
          defaults.badgeThresholds.reliableMinDone,
        ),
        helperCovers: _boundedInt(
          thresholds['helperCovers'],
          1,
          1000,
          defaults.badgeThresholds.helperCovers,
        ),
        detailCount: _boundedInt(
          thresholds['detailCount'],
          1,
          1000,
          defaults.badgeThresholds.detailCount,
        ),
      ),
    );
  }

  static Map<String, dynamic> _map(Object? value) =>
      value is Map<String, dynamic> ? value : const <String, dynamic>{};

  static bool _bool(Object? value, bool fallback) =>
      value is bool ? value : fallback;

  static int _boundedInt(Object? value, int min, int max, int fallback) =>
      value is int && value >= min && value <= max ? value : fallback;

  static DateKey? _date(Object? value) {
    if (value is! String) return null;
    return DateKey.parse(value).valueOrNull;
  }

  static List<EngagementLevel> _levels(
    Object? raw,
    List<EngagementLevel> fallback,
  ) {
    if (raw is! List || raw.isEmpty || raw.length > 12) return fallback;
    final parsed = <EngagementLevel>[];
    for (final item in raw) {
      if (item is! Map<String, dynamic> ||
          item['id'] is! String ||
          item['minPoints'] is! int ||
          item['nameBn'] is! String ||
          item['nameEn'] is! String) {
        return fallback;
      }
      parsed.add(
        EngagementLevel(
          id: item['id'] as String,
          minPoints: item['minPoints'] as int,
          nameBn: item['nameBn'] as String,
          nameEn: item['nameEn'] as String,
        ),
      );
    }
    try {
      LevelTable(parsed);
      return List<EngagementLevel>.unmodifiable(parsed);
    } on ArgumentError {
      return fallback;
    }
  }
}
