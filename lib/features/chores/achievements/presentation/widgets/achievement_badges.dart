import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/core/localization/generated/app_localizations.dart';
import 'package:family_hub/features/chores/achievements/domain/badges/badge_catalog.dart';
import 'package:family_hub/features/chores/achievements/domain/engagement_settings.dart';
import 'package:family_hub/features/chores/achievements/domain/member_stats.dart';
import 'package:family_hub/features/chores/achievements/presentation/widgets/badge_painter.dart';
import 'package:family_hub/shared/widgets/badge_medal.dart';
import 'package:flutter/material.dart';

class AchievementBadges extends StatelessWidget {
  const AchievementBadges({
    required this.stats,
    required this.settings,
    required this.number,
    super.key,
  });

  final MemberStats stats;
  final EngagementSettings settings;
  final String Function(int) number;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final earnedIds = stats.badges.keys.toSet();
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 12,
      children: [
        for (final id in BadgeCatalog.ids)
          SizedBox(
            width: 116,
            child: CustomPaint(
              painter: BadgePainter(
                color: earnedIds.contains(id)
                    ? context.tokens.statusVerifiedOn
                    : context.tokens.outline,
                earned: earnedIds.contains(id),
              ),
              child: BadgeMedal(
                label: achievementBadgeName(l10n, id),
                statusLabel: earnedIds.contains(id)
                    ? l10n.achievementEarned
                    : l10n.achievementLocked,
                description: earnedIds.contains(id)
                    ? null
                    : _progressHint(context, id),
                earned: earnedIds.contains(id),
                icon: achievementBadgeIcon(id),
              ),
            ),
          ),
      ],
    );
  }

  String _progressHint(BuildContext context, String id) {
    final l10n = context.l10n;
    final thresholds = settings.badgeThresholds;
    final (current, target) = switch (id) {
      BadgeCatalog.freshStart => (stats.completedTotal > 0 ? 1 : 0, 1),
      BadgeCatalog.consistent => (
        stats.streak.current,
        thresholds.consistentDays,
      ),
      BadgeCatalog.reliable => (
        stats.monthly.values.fold<int>(
          0,
          (best, month) => month.done > best ? month.done : best,
        ),
        thresholds.reliableMinDone,
      ),
      BadgeCatalog.helper => (stats.coversTotal, thresholds.helperCovers),
      BadgeCatalog.detailChampion => (
        stats.verifiedCleanTotal,
        thresholds.detailCount,
      ),
      _ => (0, 1),
    };
    return l10n.achievementProgressCount(number(current), number(target));
  }
}

String achievementBadgeName(AppLocalizations l10n, String id) => switch (id) {
  BadgeCatalog.freshStart => l10n.badgeFreshStart,
  BadgeCatalog.consistent => l10n.badgeConsistent,
  BadgeCatalog.reliable => l10n.badgeReliable,
  BadgeCatalog.helper => l10n.badgeHelper,
  BadgeCatalog.detailChampion => l10n.badgeDetailChampion,
  _ => l10n.achievementBadges,
};

IconData achievementBadgeIcon(String id) => switch (id) {
  BadgeCatalog.freshStart => Icons.flag_rounded,
  BadgeCatalog.consistent => Icons.local_fire_department_rounded,
  BadgeCatalog.reliable => Icons.verified_rounded,
  BadgeCatalog.helper => Icons.volunteer_activism_rounded,
  BadgeCatalog.detailChampion => Icons.fact_check_rounded,
  _ => Icons.workspace_premium_rounded,
};
