import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/features/chores/achievements/domain/engagement_settings.dart';
import 'package:family_hub/features/chores/achievements/domain/levels/level_table.dart';
import 'package:family_hub/features/chores/achievements/domain/public_stats.dart';
import 'package:family_hub/features/chores/achievements/presentation/engagement_ui_providers.dart';
import 'package:family_hub/features/chores/achievements/presentation/widgets/achievement_badges.dart';
import 'package:family_hub/features/family/domain/member.dart';
import 'package:family_hub/features/family/presentation/family_providers.dart';
import 'package:family_hub/shared/widgets/app_avatar.dart';
import 'package:family_hub/shared/widgets/error_view.dart';
import 'package:family_hub/shared/widgets/loading_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FamilyLevelsStrip extends ConsumerWidget {
  const FamilyLevelsStrip({required this.settings, super.key});

  final EngagementSettings settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final number = ref.watch(appFormattersProvider).number;
    final stats = ref.watch(familyPublicStatsProvider);
    final members = ref.watch(membersProvider);
    if (!stats.hasValue && stats.isLoading) return const LoadingView(lines: 1);
    if (!stats.hasValue && stats.hasError) {
      return ErrorView(
        message: l10n.errorNetwork,
        onRetry: () => ref.invalidate(familyPublicStatsProvider),
      );
    }
    if (!members.hasValue && members.isLoading) {
      return const LoadingView(lines: 1);
    }
    if (!members.hasValue && members.hasError) {
      return ErrorView(
        message: l10n.errorNetwork,
        onRetry: () => ref.invalidate(membersProvider),
      );
    }
    final cards = _sharedMembers(members.requireValue, stats.requireValue);
    final levels = LevelTable(settings.levels);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.engagementFamilyLevelsTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (cards.isEmpty)
              Text(
                l10n.engagementFamilyLevelsEmpty,
                style: TextStyle(color: context.tokens.textSecondary),
              )
            else
              SizedBox(
                height: 120,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: cards.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 16),
                  itemBuilder: (context, index) {
                    final (member, level, badgeIds) = cards[index];
                    return SizedBox(
                      width: 116,
                      child: Column(
                        children: [
                          AppAvatar(
                            id: member.uid,
                            name: member.displayName,
                            avatarKey: member.avatarKey,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            member.displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                          Text(
                            l10n.engagementSharedLevelAndBadges(
                              _levelName(context, level, levels),
                              number(badgeIds.length),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: context.tokens.textSecondary),
                          ),
                          Wrap(
                            spacing: 4,
                            children: [
                              for (final id in badgeIds)
                                Tooltip(
                                  message: achievementBadgeName(l10n, id),
                                  child: Semantics(
                                    label: achievementBadgeName(l10n, id),
                                    child: Icon(
                                      achievementBadgeIcon(id),
                                      size: 18,
                                      color: context.tokens.statusVerifiedOn,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 8),
            Text(
              l10n.engagementPointsNeverShared,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: context.tokens.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  List<(Member, int, List<String>)> _sharedMembers(
    List<Member> members,
    Map<String, PublicStats> publicStats,
  ) {
    final active = members.where((member) => member.isActive).toList()
      ..sort(
        (a, b) =>
            a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()),
      );
    return [
      for (final member in active)
        if (publicStats[member.uid] case final stats?)
          (member, stats.level, stats.badgeIds),
    ];
  }

  String _levelName(BuildContext context, int level, LevelTable levels) {
    final bounded = level.clamp(1, settings.levels.length).toInt();
    final definition = levels.levels[bounded - 1];
    return Localizations.localeOf(context).languageCode == 'bn'
        ? definition.nameBn
        : definition.nameEn;
  }
}
