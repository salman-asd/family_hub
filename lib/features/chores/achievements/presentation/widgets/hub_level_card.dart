import 'package:family_hub/app/routing/app_routes.dart';

import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/features/chores/achievements/domain/levels/level_table.dart';
import 'package:family_hub/features/chores/achievements/presentation/engagement_providers.dart';
import 'package:family_hub/features/chores/achievements/presentation/widgets/engagement_plant_view.dart';
import 'package:family_hub/features/family/presentation/family_providers.dart';
import 'package:family_hub/shared/widgets/dashboard_card_frame.dart';
import 'package:family_hub/shared/widgets/level_ring.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class HubLevelCard extends ConsumerWidget {
  const HubLevelCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final familyId = ref.watch(currentFamilyIdProvider);
    final memberId = ref.watch(currentUidProvider);
    if (familyId == null || memberId == null) return const SizedBox.shrink();
    final settings = ref.watch(engagementSettingsProvider(familyId));
    if (settings.hasValue && !settings.requireValue.enabled) {
      return const SizedBox.shrink();
    }
    if (!settings.hasValue && settings.hasError) {
      return DashboardCardFrame(
        title: context.l10n.dashCardHubLevel,
        icon: Icons.eco_outlined,
        mode: DashboardCardMode.error,
        errorMessage: context.l10n.errorNetwork,
        onRetry: () => ref.invalidate(engagementSettingsProvider(familyId)),
        child: const SizedBox.shrink(),
      );
    }
    if (!settings.hasValue) {
      return DashboardCardFrame(
        title: context.l10n.dashCardHubLevel,
        icon: Icons.eco_outlined,
        mode: DashboardCardMode.loading,
        loadingLabel: context.l10n.loadingSemantics,
        child: const SizedBox.shrink(),
      );
    }
    final stats = ref.watch(memberStatsProvider(memberId));
    if (!stats.hasValue && stats.hasError) {
      return DashboardCardFrame(
        title: context.l10n.dashCardHubLevel,
        icon: Icons.eco_outlined,
        mode: DashboardCardMode.error,
        errorMessage: context.l10n.errorNetwork,
        onRetry: () => ref.invalidate(memberStatsProvider(memberId)),
        child: const SizedBox.shrink(),
      );
    }
    if (!stats.hasValue) {
      return DashboardCardFrame(
        title: context.l10n.dashCardHubLevel,
        icon: Icons.eco_outlined,
        mode: DashboardCardMode.loading,
        loadingLabel: context.l10n.loadingSemantics,
        child: const SizedBox.shrink(),
      );
    }
    final settingsValue = settings.requireValue;
    final statsValue = stats.requireValue;
    if (statsValue == null) return const SizedBox.shrink();
    final levels = LevelTable(settingsValue.levels);
    final progress = levels.progress(statsValue.totalPoints);
    final levelNumber = levels.levelFor(statsValue.totalPoints);
    final stage =
        (levelNumber - 1) * 7 ~/ (settingsValue.levels.length - 1).clamp(1, 11);
    final number = ref.watch(appFormattersProvider).number;
    final progressLabel = progress.needed == 0
        ? context.l10n.achievementMaxLevel
        : context.l10n.achievementProgress(
            number(progress.into),
            number(progress.needed),
          );
    final levelName = Localizations.localeOf(context).languageCode == 'bn'
        ? progress.level.nameBn
        : progress.level.nameEn;
    return DashboardCardFrame(
      title: context.l10n.dashCardHubLevel,
      icon: Icons.eco_outlined,
      onTap: () => context.push(AppRoutes.choresAchievements),
      child: Row(
        children: [
          EngagementPlantView(
            stage: stage.clamp(0, 7).toInt(),
            semanticLabel: context.l10n.achievementLevel(number(levelNumber)),
            size: 72,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(levelName, style: Theme.of(context).textTheme.titleMedium),
                Text(
                  context.l10n.achievementPoints(
                    number(statsValue.totalPoints),
                  ),
                ),
                Text(progressLabel),
              ],
            ),
          ),
          LevelRing(
            level: levelNumber,
            levelLabel: levelName,
            progress: progress.fraction / 1000,
            progressLabel: progressLabel,
          ),
        ],
      ),
    );
  }
}
