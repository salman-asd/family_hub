import 'dart:async';

import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/features/chores/calendar/presentation/calendar_providers.dart';
import 'package:family_hub/features/chores/presentation/widgets/chore_tile.dart'
    show statusLabelOf;
import 'package:family_hub/features/chores/settings/presentation/chore_settings_providers.dart';
import 'package:family_hub/features/family/presentation/family_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The filters that are on, as removable chips under the header (P3-23).
/// Nothing is drawn when no filter is on.
class FilterChipsRow extends ConsumerWidget {
  const FilterChipsRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final bn = l10n.localeName.startsWith('bn');
    final filters = ref.watch(calendarFiltersProvider);
    if (filters.isEmpty) return const SizedBox.shrink();
    final groups = ref.watch(choreGroupsProvider);
    final members = ref.watch(membersProvider).value ?? const [];
    final prefs = ref.read(calendarPrefsProvider.notifier);

    Widget chip(Key key, String label, VoidCallback onRemove) => Semantics(
      label: l10n.calendarRemoveFilter(label),
      button: true,
      excludeSemantics: true,
      onTap: onRemove,
      child: InputChip(
        key: key,
        label: Text(label),
        onDeleted: onRemove,
        deleteButtonTooltipMessage: l10n.calendarRemoveFilter(label),
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          for (final id in filters.groupIds)
            chip(
              Key('calendar_chip_group_$id'),
              groups
                      .where((g) => g.id == id)
                      .map((g) => bn ? g.nameBn : (g.nameEn ?? g.nameBn))
                      .firstOrNull ??
                  id,
              () => unawaited(
                prefs.setFilters(
                  filters.copyWith(
                    groupIds: <String>{...filters.groupIds}..remove(id),
                    query: '',
                  ),
                ),
              ),
            ),
          for (final status in filters.statuses)
            chip(
              Key('calendar_chip_status_${status.id}'),
              statusLabelOf(status, l10n),
              () => unawaited(
                prefs.setFilters(
                  filters.copyWith(
                    statuses: filters.statuses.where((s) => s != status).toSet(),
                    query: '',
                  ),
                ),
              ),
            ),
          for (final id in filters.memberIds)
            chip(
              Key('calendar_chip_member_$id'),
              members.where((m) => m.uid == id).map((m) => m.displayName).firstOrNull ?? id,
              () => unawaited(
                prefs.setFilters(
                  filters.copyWith(
                    memberIds: <String>{...filters.memberIds}..remove(id),
                    query: '',
                  ),
                ),
              ),
            ),
          if (filters.onlyNeedsAttention)
            chip(
              const Key('calendar_chip_attention'),
              l10n.calendarFilterNeedsAttention,
              () => unawaited(
                prefs.setFilters(
                  filters.copyWith(onlyNeedsAttention: false, query: ''),
                ),
              ),
            ),
          if (filters.query.trim().isNotEmpty)
            chip(
              const Key('calendar_chip_query'),
              filters.query.trim(),
              ref.read(calendarQueryProvider.notifier).clear,
            ),
        ],
      ),
    );
  }
}
