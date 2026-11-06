import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/features/chores/achievements/domain/engagement_settings.dart';
import 'package:family_hub/features/chores/achievements/domain/levels/level_table.dart';
import 'package:family_hub/features/chores/achievements/domain/member_stats.dart';
import 'package:family_hub/features/chores/achievements/presentation/widgets/achievement_badges.dart';
import 'package:family_hub/features/chores/achievements/presentation/widgets/engagement_plant_view.dart';
import 'package:family_hub/features/chores/achievements/presentation/widgets/family_levels_strip.dart';
import 'package:family_hub/shared/widgets/level_ring.dart';
import 'package:family_hub/shared/widgets/responsive_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AchievementsContent extends ConsumerWidget {
  const AchievementsContent({
    required this.settings,
    required this.stats,
    required this.familyId,
    required this.memberId,
    required this.sharingBusy,
    required this.onSharingChanged,
    super.key,
  });

  final EngagementSettings settings;
  final MemberStats stats;
  final String familyId;
  final String memberId;
  final bool sharingBusy;
  final ValueChanged<bool> onSharingChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final formatters = ref.watch(appFormattersProvider);
    final table = LevelTable(settings.levels);
    final progress = table.progress(stats.totalPoints);
    final levelNumber = table.levelFor(stats.totalPoints);
    final stage =
        (levelNumber - 1) * 7 ~/ (settings.levels.length - 1).clamp(1, 11);
    final localeName = Localizations.localeOf(context).languageCode == 'bn'
        ? progress.level.nameBn
        : progress.level.nameEn;
    final progressLabel = progress.needed == 0
        ? l10n.achievementMaxLevel
        : l10n.achievementProgress(
            formatters.number(progress.into),
            formatters.number(progress.needed),
          );
    final rate = stats.completedTotal == 0
        ? 0
        : (stats.onTimeTotal * 100 ~/ stats.completedTotal)
              .clamp(0, 100)
              .toInt();

    final levelCard = Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                EngagementPlantView(
                  stage: stage.clamp(0, 7).toInt(),
                  semanticLabel: l10n.achievementLevel(
                    formatters.number(levelNumber),
                  ),
                  size: 112,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        localeName,
                        style: Theme.of(context).textTheme.titleLarge
                            ?.copyWith(color: context.tokens.textPrimary),
                      ),
                      Text(
                        l10n.achievementLevel(formatters.number(levelNumber)),
                        style: TextStyle(color: context.tokens.textSecondary),
                      ),
                      Text(
                        l10n.achievementPoints(
                          formatters.number(stats.totalPoints),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(progressLabel),
                    ],
                  ),
                ),
                LevelRing(
                  level: levelNumber,
                  levelLabel: localeName,
                  progress: progress.fraction / 1000,
                  progressLabel: progressLabel,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.achievementStreak(
                      formatters.number(stats.streak.current),
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    l10n.achievementBestStreak(
                      formatters.number(stats.streak.best),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    final badgesPane = <Widget>[
      Text(
        l10n.achievementBadges,
        style: Theme.of(context).textTheme.titleLarge,
      ),
      const SizedBox(height: 12),
      AchievementBadges(
        stats: stats,
        settings: settings,
        number: formatters.number,
      ),
      if (settings.statsVisibility == StatsVisibility.levels) ...[
        const SizedBox(height: 16),
        SwitchListTile(
          key: const Key('achievement_share_switch'),
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.engagementSharingSwitch),
          subtitle: Text(l10n.engagementSharingDescription),
          value: stats.sharing,
          onChanged: sharingBusy ? null : onSharingChanged,
        ),
        const SizedBox(height: 8),
        FamilyLevelsStrip(settings: settings),
      ],
    ];

    // P4-24: the plant and the personal numbers keep the leading side, the
    // badge shelf gets its own scrolling column beside them.
    if (context.layoutClass.showsTwoPanes) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
              children: [
                levelCard,
                const SizedBox(height: 12),
                _PersonalStats(
                  stats: stats,
                  onTimePercent: rate,
                  number: formatters.number,
                ),
              ],
            ),
          ),
          Expanded(
            flex: 4,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(8, 16, 16, 16),
              children: badgesPane,
            ),
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        levelCard,
        const SizedBox(height: 12),
        _PersonalStats(
          stats: stats,
          onTimePercent: rate,
          number: formatters.number,
        ),
        const SizedBox(height: 16),
        ...badgesPane,
      ],
    );
  }
}

class _PersonalStats extends StatelessWidget {
  const _PersonalStats({
    required this.stats,
    required this.onTimePercent,
    required this.number,
  });

  final MemberStats stats;
  final int onTimePercent;
  final String Function(int) number;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      _StatChip(
        label: context.l10n.achievementCompleted,
        value: stats.completedTotal,
        number: number,
      ),
      _StatChip(
        label: context.l10n.achievementOnTime,
        value: onTimePercent,
        suffix: '%',
        number: number,
      ),
      _StatChip(
        label: context.l10n.achievementCovers,
        value: stats.coversTotal,
        number: number,
      ),
      _StatChip(
        label: context.l10n.achievementVerified,
        value: stats.verifiedCleanTotal,
        number: number,
      ),
    ],
  );
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.number,
    this.suffix = '',
  });

  final String label;
  final int value;
  final String Function(int) number;
  final String suffix;

  @override
  Widget build(BuildContext context) =>
      Chip(label: Text('$label: ${number(value)}$suffix'));
}
