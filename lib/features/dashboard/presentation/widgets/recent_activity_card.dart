import 'package:family_hub/app/routing/app_routes.dart';
import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:family_hub/core/localization/activity_names.dart';
import 'package:family_hub/core/localization/activity_text.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/features/activity/domain/activity_entry.dart';
import 'package:family_hub/features/activity/presentation/activity_providers.dart';
import 'package:family_hub/features/activity/presentation/activity_target.dart';
import 'package:family_hub/features/family/domain/member.dart';
import 'package:family_hub/features/family/presentation/family_providers.dart';
import 'package:family_hub/shared/widgets/activity_tile.dart';
import 'package:family_hub/shared/widgets/dashboard_card_frame.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class RecentActivityCard extends ConsumerWidget {
  const RecentActivityCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activity = ref.watch(recentActivityProvider(5));
    final members = ref.watch(membersProvider);
    final l10n = context.l10n;
    final failed =
        (!activity.hasValue && activity.hasError) ||
        (!members.hasValue && members.hasError);
    final loading =
        (!activity.hasValue && activity.isLoading) ||
        (!members.hasValue && members.isLoading);

    return DashboardCardFrame(
      title: l10n.dashboardRecentActivityTitle,
      icon: Icons.history_rounded,
      mode: loading
          ? DashboardCardMode.loading
          : failed
          ? DashboardCardMode.error
          : DashboardCardMode.content,
      errorMessage: failed ? l10n.activityLoadError : null,
      loadingLabel: l10n.loadingSemantics,
      onRetry: failed
          ? () {
              ref.invalidate(recentActivityProvider(5));
              ref.invalidate(membersProvider);
            }
          : null,
      onTap: () => context.push(AppRoutes.activity),
      child: activity.hasValue && members.hasValue
          ? _RecentActivityRows(
              entries: activity.requireValue,
              members: members.requireValue,
            )
          : const SizedBox.shrink(),
    );
  }
}

class _RecentActivityRows extends ConsumerWidget {
  const _RecentActivityRows({required this.entries, required this.members});

  final List<ActivityEntry> entries;
  final List<Member> members;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    if (entries.isEmpty) return Text(l10n.activityEmpty);
    return Column(
      children: [
        for (final entry in entries)
          _ActivityEntryTile(entry: entry, members: members),
      ],
    );
  }
}

class _ActivityEntryTile extends ConsumerWidget {
  const _ActivityEntryTile({required this.entry, required this.members});

  final ActivityEntry entry;
  final List<Member> members;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final dates = ref.watch(familyDateKeysProvider);
    final formatters = ref.watch(appFormattersProvider);
    final date = dates.dateKeyOf(entry.createdAt);
    final target = ActivityTarget.from(entry);
    return ActivityTile(
      key: ValueKey<String>('dashboard_activity_${entry.id}'),
      title: l10n.activityText(
        entry.type,
        resolveChoreActivityNames(entry.type, entry.params, (uid) {
          for (final member in members) {
            if (member.uid == uid) return member.displayName;
          }
          return null;
        }),
      ),
      subtitle: _actorName(entry.actorId, members, l10n.activityUnknownActor),
      timeLabel:
          '${formatters.fullDate(DateTime.utc(date.year, date.month, date.day))} · '
          '${formatters.timeOfDay(dates.minutesOfDayOf(entry.createdAt))}',
      leading: Icon(
        _activityIcon(entry.type),
        color: context.tokens.accentStrong,
      ),
      onTap: target == null ? null : () => context.push(target.location),
    );
  }

  String _actorName(String uid, List<Member> members, String fallback) {
    for (final member in members) {
      if (member.uid == uid) return member.displayName;
    }
    return fallback;
  }

  IconData _activityIcon(String type) => switch (type.split('.').first) {
    'bazar' => Icons.shopping_basket_outlined,
    'chores' => Icons.task_alt_rounded,
    'engagement' => Icons.emoji_events_outlined,
    _ => Icons.groups_outlined,
  };
}
