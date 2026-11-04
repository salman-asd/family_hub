import 'package:family_hub/app/routing/app_routes.dart';
import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/features/chores/occurrences/domain/chore_item.dart';
import 'package:family_hub/features/chores/occurrences/presentation/today_providers.dart';
import 'package:family_hub/features/chores/presentation/dashboard/chores_dashboard_providers.dart';
import 'package:family_hub/features/family/presentation/family_providers.dart';
import 'package:family_hub/features/family/presentation/permission_providers.dart';
import 'package:family_hub/shared/widgets/app_card.dart';
import 'package:family_hub/shared/widgets/progress_ring.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// The Home cards of the Chores module (P3-29), in display order.
///
/// `FamilyModule.dashboardCards` takes widget builders; each card is a
/// `ConsumerWidget` over the providers in `chores_dashboard_providers.dart`, so
/// it follows the same listeners as Today and the calendar.
final List<WidgetBuilder> choresDashboardCards = <WidgetBuilder>[
  (_) => const ChoresTodayCard(),
  (_) => const ChoresOverdueCard(),
  (_) => const ChoresVerifyCard(),
  (_) => const ChoresWeekCard(),
];

String _nameOf(BuildContext context, ChoreItem item) =>
    Localizations.localeOf(context).languageCode == 'bn'
    ? item.nameBn
    : (item.nameEn ?? item.nameBn);

/// The shared frame: a tappable [AppCard] with a title line.
class _DashCard extends StatelessWidget {
  const _DashCard({
    required this.cardKey,
    required this.title,
    required this.onTap,
    required this.child,
  });

  final Key cardKey;
  final String title;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        key: cardKey,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: t.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

/// Progress ring, "3 of 7 done" and the next chore that is due.
class ChoresTodayCard extends ConsumerWidget {
  const ChoresTodayCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final t = context.tokens;
    final formatters = ref.watch(appFormattersProvider);
    final progress = ref.watch(dashboardTodayProgressProvider);
    final next = ref.watch(dashboardNextItemProvider);
    final textTheme = Theme.of(context).textTheme;

    final String headline;
    if (progress.total == 0) {
      headline = l10n.todayEmptyTitle;
    } else if (progress.isComplete) {
      headline = l10n.todayAllDoneTitle;
    } else {
      headline = l10n.todayProgress(
        formatters.number(progress.done),
        formatters.number(progress.total),
      );
    }

    return _DashCard(
      cardKey: const Key('chores_card_today'),
      title: l10n.todayTitle,
      onTap: () => context.push(AppRoutes.choresToday),
      child: Row(
        children: [
          ProgressRing(
            value: progress.fraction,
            size: 56,
            semanticLabel: headline,
            center: Text(
              formatters.number(progress.done),
              style: TextStyle(
                color: t.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(headline, style: textTheme.bodyLarge),
                if (next != null) ...[
                  Text(
                    l10n.choresDashNext(_nameOf(context, next)),
                    key: const Key('chores_card_today_next'),
                    style: textTheme.bodyMedium?.copyWith(
                      color: t.textSecondary,
                    ),
                  ),
                  if (next.dueMinutes != null)
                    Text(
                      l10n.choreDueTime(formatters.timeOfDay(next.dueMinutes!)),
                      style: textTheme.bodySmall?.copyWith(
                        color: t.textSecondary,
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// How many open chores are past their deadline, and the oldest one.
class ChoresOverdueCard extends ConsumerWidget {
  const ChoresOverdueCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final t = context.tokens;
    final formatters = ref.watch(appFormattersProvider);
    final overdue = ref.watch(dashboardOverdueProvider);
    final textTheme = Theme.of(context).textTheme;
    final has = overdue.isNotEmpty;

    return _DashCard(
      cardKey: const Key('chores_card_overdue'),
      title: l10n.todaySectionOverdue,
      onTap: () => context.go(AppRoutes.chores),
      child: Row(
        children: [
          // Shape + text, never colour alone (rule 43).
          Icon(
            has ? Icons.warning_amber_rounded : Icons.check_circle_outline,
            color: has ? t.statusOverdue : t.statusCompleted,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  has
                      ? l10n.choresDashOverdueCount(
                          formatters.number(overdue.length),
                        )
                      : l10n.choresDashOverdueNone,
                  style: textTheme.bodyLarge,
                ),
                if (has)
                  Text(
                    l10n.choresDashOverdueOldest(
                      _nameOf(context, overdue.first),
                    ),
                    style: textTheme.bodyMedium?.copyWith(
                      color: t.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Chores waiting for a check. Only people who can verify see it, and only
/// while the queue is not empty.
class ChoresVerifyCard extends ConsumerWidget {
  const ChoresVerifyCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(canVerifyAnyProvider)) return const SizedBox.shrink();
    final count = ref.watch(verifyQueueCountProvider);
    if (count == 0) return const SizedBox.shrink();
    final l10n = context.l10n;
    final t = context.tokens;
    final formatters = ref.watch(appFormattersProvider);

    return _DashCard(
      cardKey: const Key('chores_card_verify'),
      title: l10n.verifyTitle,
      onTap: () => context.push(AppRoutes.choresVerify),
      child: Row(
        children: [
          Icon(Icons.fact_check_outlined, color: t.accentStrong),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l10n.choresDashVerifyCount(formatters.number(count)),
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ],
      ),
    );
  }
}

/// A seven-day strip: the weekday and how many chores that day has.
class ChoresWeekCard extends ConsumerWidget {
  const ChoresWeekCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final t = context.tokens;
    final formatters = ref.watch(appFormattersProvider);
    final week = ref.watch(dashboardWeekProvider);

    return _DashCard(
      cardKey: const Key('chores_card_week'),
      title: l10n.choresDashWeekTitle,
      onTap: () => context.go(AppRoutes.chores),
      child: Row(
        children: [
          for (final day in week)
            Expanded(
              child: Semantics(
                label: l10n.choresDashWeekDay(
                  formatters.weekdayShort(day.day.isoWeekday),
                  formatters.number(day.total),
                ),
                excludeSemantics: true,
                child: Column(
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        formatters.weekdayShort(day.day.isoWeekday),
                        style: Theme.of(context).textTheme.labelSmall
                            ?.copyWith(color: t.textSecondary),
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Today is a filled disc, other days a plain outline:
                    // shape differs, not only colour.
                    Container(
                      key: Key('chores_week_${day.day}'),
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: day.isToday ? t.accent : null,
                        border: day.isToday
                            ? null
                            : Border.all(color: t.outline),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          formatters.number(day.total),
                          style: TextStyle(
                            color: day.isToday
                                ? t.textOnAccent
                                : t.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
