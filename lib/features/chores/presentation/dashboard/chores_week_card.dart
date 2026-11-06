import 'package:family_hub/app/routing/app_routes.dart';
import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/features/chores/presentation/dashboard/chores_dashboard_providers.dart';
import 'package:family_hub/features/chores/occurrences/presentation/occurrence_providers.dart';
import 'package:family_hub/shared/widgets/dashboard_card_frame.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// A seven-day strip: the weekday and how many chores that day has.
class ChoresWeekCard extends ConsumerWidget {
  const ChoresWeekCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final t = context.tokens;
    final formatters = ref.watch(appFormattersProvider);
    final week = ref.watch(dashboardWeekProvider);

    return DashboardCardFrame(
      key: const Key('chores_card_week'),
      title: l10n.choresDashWeekTitle,
      icon: Icons.date_range_rounded,
      mode: !week.hasValue && week.isLoading
          ? DashboardCardMode.loading
          : !week.hasValue && week.hasError
          ? DashboardCardMode.error
          : DashboardCardMode.content,
      errorMessage: !week.hasValue && week.hasError ? l10n.errorNetwork : null,
      loadingLabel: l10n.loadingSemantics,
      onRetry: !week.hasValue && week.hasError
          ? () {
              for (final month in ref.read(dashboardWeekMonthsProvider)) {
                ref.invalidate(monthOccurrencesProvider(month));
              }
            }
          : null,
      onTap: () => context.go(AppRoutes.chores),
      child: Row(
        children: [
          for (final day in week.value ?? const <WeekStripDay>[])
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
                            color: day.isToday ? t.textOnAccent : t.textPrimary,
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
