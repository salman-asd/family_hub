import 'dart:async';

import 'package:family_hub/core/localization/app_formatters.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/features/chores/calendar/presentation/calendar_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The filter sheet. P3-22 ships only what the truncated banner needs: how many
/// filters are on and "Clear filters". The group / status / member / search
/// controls arrive with P3-23.
Future<void> showFiltersSheet(BuildContext context) => showModalBottomSheet<void>(
  context: context,
  showDragHandle: true,
  builder: (context) => const FiltersSheet(),
);

class FiltersSheet extends ConsumerWidget {
  const FiltersSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final AppFormatters formatters = ref.watch(appFormattersProvider);
    final count = ref.watch(calendarFiltersProvider).activeCount;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.calendarFilters,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              count == 0
                  ? l10n.calendarFiltersNone
                  : l10n.calendarFiltersActive(formatters.number(count)),
            ),
            const SizedBox(height: 12),
            if (count > 0)
              FilledButton.tonal(
                key: const Key('calendar_clear_filters'),
                onPressed: () {
                  ref.read(calendarQueryProvider.notifier).clear();
                  unawaited(ref.read(calendarPrefsProvider.notifier).clearFilters());
                },
                child: Text(l10n.calendarClearFilters),
              ),
          ],
        ),
      ),
    );
  }
}
