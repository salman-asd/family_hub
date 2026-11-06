import 'package:family_hub/app/routing/app_routes.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/features/chores/calendar/presentation/calendar_items_providers.dart';
import 'package:family_hub/features/chores/calendar/presentation/month_items.dart';
import 'package:family_hub/features/chores/occurrences/domain/chore_item.dart';
import 'package:family_hub/features/chores/occurrences/presentation/occurrence_providers.dart';
import 'package:family_hub/features/family/presentation/family_providers.dart';
import 'package:family_hub/shared/widgets/dashboard_card_frame.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class UpcomingCard extends ConsumerWidget {
  const UpcomingCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final month = ref.watch(familyDateKeysProvider).thisMonth();
    final items = ref.watch(monthItemsProvider(month));
    final uid = ref.watch(currentUidProvider);

    return DashboardCardFrame(
      title: l10n.dashboardUpcomingTitle,
      icon: Icons.upcoming_outlined,
      mode: !items.hasValue && items.isLoading
          ? DashboardCardMode.loading
          : !items.hasValue && items.hasError
          ? DashboardCardMode.error
          : DashboardCardMode.content,
      errorMessage: !items.hasValue && items.hasError
          ? l10n.errorNetwork
          : null,
      onRetry: !items.hasValue && items.hasError
          ? () => ref.invalidate(monthOccurrencesProvider(month))
          : null,
      loadingLabel: l10n.loadingSemantics,
      onTap: () => context.go(AppRoutes.chores),
      child: items.hasValue
          ? _UpcomingItems(
              items: _selectUpcoming(
                items.requireValue.items,
                ref.watch(todayKeyProvider),
                uid,
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}

class _UpcomingItems extends ConsumerWidget {
  const _UpcomingItems({required this.items});

  final List<ChoreItem> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    if (items.isEmpty) return Text(l10n.dashboardUpcomingEmpty);
    final dates = ref.watch(familyDateKeysProvider);
    final formatters = ref.watch(appFormattersProvider);
    final bangla = Localizations.localeOf(context).languageCode == 'bn';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.task_alt_outlined, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    bangla ? item.nameBn : item.nameEn ?? item.nameBn,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${formatters.fullDate(DateTime.utc(item.dateKey.year, item.dateKey.month, item.dateKey.day))} · '
                  '${formatters.timeOfDay(dates.minutesOfDayOf(item.dueAt))}',
                  textAlign: TextAlign.end,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

List<ChoreItem> _selectUpcoming(
  List<ChoreItem> items,
  DateKey today,
  String? uid,
) {
  if (uid == null) return const <ChoreItem>[];
  final upcoming = <ChoreItem>[
    for (final item in items)
      if (item.assigneeId == uid &&
          item.dateKey.isAfter(today) &&
          item.status.isOpen)
        item,
  ]..sort(compareChoreItems);
  return upcoming.take(3).toList(growable: false);
}
