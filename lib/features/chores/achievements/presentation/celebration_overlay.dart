import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/features/chores/achievements/domain/celebration_state.dart';
import 'package:family_hub/features/chores/achievements/domain/engagement_settings.dart';
import 'package:family_hub/features/chores/achievements/domain/levels/level_table.dart';
import 'package:family_hub/features/chores/achievements/presentation/engagement_motion.dart';
import 'package:family_hub/features/chores/achievements/presentation/painters/confetti_painter.dart';
import 'package:family_hub/features/chores/achievements/presentation/widgets/achievement_badges.dart';
import 'package:family_hub/features/chores/achievements/presentation/widgets/engagement_plant_view.dart';
import 'package:family_hub/shared/widgets/badge_medal.dart';
import 'package:family_hub/shared/widgets/level_ring.dart';
import 'package:flutter/material.dart';

final class CelebrationOverlay extends StatelessWidget {
  const CelebrationOverlay({
    required this.celebration,
    required this.settings,
    required this.formatNumber,
    super.key,
  });

  final CelebrationShown celebration;
  final EngagementSettings settings;
  final String Function(int) formatNumber;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tokens = context.tokens;
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    final levelTable = LevelTable(settings.levels);
    final progress = levelTable.progress(celebration.totalPoints);
    final stage =
        (celebration.levelAfter - 1) *
        7 ~/
        (settings.levels.length - 1).clamp(1, 11);
    final levelName = Localizations.localeOf(context).languageCode == 'bn'
        ? progress.level.nameBn
        : progress.level.nameEn;
    final progressLabel = progress.needed == 0
        ? l10n.achievementMaxLevel
        : l10n.achievementProgress(
            formatNumber(progress.into),
            formatNumber(progress.needed),
          );
    final semanticLabel = l10n.celebrationSemantics;
    final confettiColors = List<Color>.unmodifiable(tokens.chart);

    return Semantics(
      liveRegion: true,
      label: semanticLabel,
      child: SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.88,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 92,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (!reducedMotion)
                        TweenAnimationBuilder<double>(
                          duration: engagementMotionConfetti(context),
                          tween: Tween<double>(begin: 0, end: 1),
                          builder: (context, progress, _) => CustomPaint(
                            painter: ConfettiPainter(
                              seed: celebration.dateKey.epochDay,
                              progress: progress,
                              colors: confettiColors,
                            ),
                            size: Size.infinite,
                          ),
                        ),
                      Center(
                        child: Icon(
                          Icons.celebration_rounded,
                          color: tokens.accent,
                          size: 36,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  l10n.celebrationTitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.celebrationPointsToday(
                    formatNumber(celebration.pointsToday),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    EngagementPlantView(
                      stage: stage.clamp(0, 7).toInt(),
                      semanticLabel: l10n.achievementLevel(
                        formatNumber(celebration.levelAfter),
                      ),
                      animate:
                          celebration.levelAfter > celebration.levelBefore &&
                          !reducedMotion,
                      size: 96,
                    ),
                    const SizedBox(width: 20),
                    LevelRing(
                      level: celebration.levelAfter,
                      levelLabel: levelName,
                      progress: progress.fraction / 1000,
                      progressLabel: progressLabel,
                      size: 88,
                    ),
                  ],
                ),
                Text(levelName, textAlign: TextAlign.center),
                if (celebration.levelAfter > celebration.levelBefore) ...[
                  const SizedBox(height: 8),
                  Text(
                    l10n.celebrationLevelUp,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
                if (celebration.newBadges.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text(
                    l10n.celebrationNewBadges,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      for (final badgeId in celebration.newBadges)
                        SizedBox(
                          width: 124,
                          child: BadgeMedal(
                            icon: achievementBadgeIcon(badgeId),
                            label: achievementBadgeName(l10n, badgeId),
                            statusLabel: l10n.achievementEarned,
                          ),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    child: Text(l10n.actionDone),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
