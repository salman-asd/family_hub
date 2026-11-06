import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/features/chores/achievements/domain/badges/badge_catalog.dart';
import 'package:family_hub/features/chores/achievements/domain/levels/level_table.dart';
import 'package:family_hub/features/chores/achievements/domain/scoring/score_spec.dart';

enum StatsVisibility {
  private('private'),
  levels('levels');

  const StatsVisibility(this.id);

  final String id;

  static StatsVisibility fromId(Object? id) => values.firstWhere(
    (visibility) => visibility.id == id,
    orElse: () => StatsVisibility.private,
  );
}

final class EngagementSettings {
  EngagementSettings({
    required this.enabled,
    required this.startedOn,
    required this.celebrationEnabled,
    required this.showHelpersHighlight,
    required this.statsVisibility,
    required this.scoreSpec,
    required Iterable<EngagementLevel> levels,
    required this.badgeThresholds,
  }) : levels = List<EngagementLevel>.unmodifiable(levels);

  final bool enabled;
  final DateKey startedOn;
  final bool celebrationEnabled;
  final bool showHelpersHighlight;
  final StatsVisibility statsVisibility;
  final ScoreSpec scoreSpec;
  final List<EngagementLevel> levels;
  final BadgeThresholds badgeThresholds;

  EngagementSettings copyWith({
    bool? enabled,
    DateKey? startedOn,
    bool? celebrationEnabled,
    bool? showHelpersHighlight,
    StatsVisibility? statsVisibility,
    ScoreSpec? scoreSpec,
    Iterable<EngagementLevel>? levels,
    BadgeThresholds? badgeThresholds,
  }) => EngagementSettings(
    enabled: enabled ?? this.enabled,
    startedOn: startedOn ?? this.startedOn,
    celebrationEnabled: celebrationEnabled ?? this.celebrationEnabled,
    showHelpersHighlight: showHelpersHighlight ?? this.showHelpersHighlight,
    statsVisibility: statsVisibility ?? this.statsVisibility,
    scoreSpec: scoreSpec ?? this.scoreSpec,
    levels: levels ?? this.levels,
    badgeThresholds: badgeThresholds ?? this.badgeThresholds,
  );

  @override
  bool operator ==(Object other) =>
      other is EngagementSettings &&
      other.enabled == enabled &&
      other.startedOn == startedOn &&
      other.celebrationEnabled == celebrationEnabled &&
      other.showHelpersHighlight == showHelpersHighlight &&
      other.statsVisibility == statsVisibility &&
      other.scoreSpec == scoreSpec &&
      _sameLevels(other.levels, levels) &&
      other.badgeThresholds == badgeThresholds;

  @override
  int get hashCode => Object.hash(
    enabled,
    startedOn,
    celebrationEnabled,
    showHelpersHighlight,
    statsVisibility,
    scoreSpec,
    Object.hashAll(levels),
    badgeThresholds,
  );
}

bool _sameLevels(List<EngagementLevel> first, List<EngagementLevel> second) {
  if (first.length != second.length) return false;
  for (var index = 0; index < first.length; index++) {
    if (first[index] != second[index]) return false;
  }
  return true;
}
