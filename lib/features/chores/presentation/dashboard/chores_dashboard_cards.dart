import 'package:family_hub/app/routing/app_routes.dart';
import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/features/chores/calendar/presentation/calendar_items_providers.dart';
import 'package:family_hub/features/chores/occurrences/presentation/today_providers.dart';
import 'package:family_hub/features/chores/occurrences/presentation/occurrence_providers.dart';
import 'package:family_hub/features/chores/presentation/dashboard/chores_dashboard_providers.dart';
import 'package:family_hub/features/chores/presentation/dashboard/chores_week_card.dart';
import 'package:family_hub/features/chores/presentation/dashboard/dash_card.dart';
import 'package:family_hub/features/family/presentation/family_providers.dart';
import 'package:family_hub/features/family/presentation/permission_providers.dart';
import 'package:family_hub/shared/widgets/dashboard_card_frame.dart';
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
    final today = ref.watch(familyDateKeysProvider).today();
    final source = ref.watch(monthOccurrencesProvider(today.monthKey));
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

    return DashboardCardFrame(
      key: const Key('chores_card_today'),
      title: l10n.todayTitle,
      icon: Icons.task_alt_rounded,
      mode: !source.hasValue && source.isLoading
          ? DashboardCardMode.loading
          : !source.hasValue && source.hasError
          ? DashboardCardMode.error
          : DashboardCardMode.content,
      errorMessage: !source.hasValue && source.hasError
          ? l10n.errorNetwork
          : null,
      loadingLabel: l10n.loadingSemantics,
      onRetry: !source.hasValue && source.hasError
          ? () => ref.invalidate(monthOccurrencesProvider(today.monthKey))
          : null,
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
                    l10n.choresDashNext(dashNameOf(context, next)),
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
    final month = ref.watch(familyDateKeysProvider).thisMonth();
    final source = ref.watch(monthItemsProvider(month));
    final overdue = ref.watch(dashboardOverdueProvider);
    final textTheme = Theme.of(context).textTheme;
    final has = overdue.isNotEmpty;

    return DashboardCardFrame(
      key: const Key('chores_card_overdue'),
      title: l10n.todaySectionOverdue,
      icon: has ? Icons.warning_amber_rounded : Icons.check_circle_outline,
      mode: !source.hasValue && source.isLoading
          ? DashboardCardMode.loading
          : !source.hasValue && source.hasError
          ? DashboardCardMode.error
          : DashboardCardMode.content,
      errorMessage: !source.hasValue && source.hasError
          ? l10n.errorNetwork
          : null,
      loadingLabel: l10n.loadingSemantics,
      onRetry: !source.hasValue && source.hasError
          ? () => ref.invalidate(monthOccurrencesProvider(month))
          : null,
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
                      dashNameOf(context, overdue.first),
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
    final queue = ref.watch(verifyQueueProvider);
    final count = ref.watch(verifyQueueCountProvider);
    if (queue.hasValue && count == 0) return const SizedBox.shrink();
    final l10n = context.l10n;
    final t = context.tokens;
    final formatters = ref.watch(appFormattersProvider);

    return DashboardCardFrame(
      key: const Key('chores_card_verify'),
      title: l10n.verifyTitle,
      icon: Icons.fact_check_outlined,
      mode: !queue.hasValue && queue.isLoading
          ? DashboardCardMode.loading
          : !queue.hasValue && queue.hasError
          ? DashboardCardMode.error
          : DashboardCardMode.content,
      errorMessage: !queue.hasValue && queue.hasError
          ? l10n.errorNetwork
          : null,
      loadingLabel: l10n.loadingSemantics,
      onRetry: !queue.hasValue && queue.hasError
          ? () => ref.invalidate(verifyQueueProvider)
          : null,
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
