import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/features/chores/calendar/domain/calendar_filters.dart';
import 'package:family_hub/features/chores/calendar/presentation/calendar_providers.dart';
import 'package:family_hub/features/chores/occurrences/domain/chore_item.dart';
import 'package:family_hub/features/family/presentation/family_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The chores of one day for the list under the grid (P3-22), earliest
/// deadline first.
///
/// Filters first, then scope, exactly like `DaySummaryBuilder`, so the list and
/// the cell above it can never disagree. It reads the day's month items (the
/// listener the grid already holds), so it costs no extra read.
final dayPanelItemsProvider = Provider.autoDispose
    .family<AsyncValue<List<ChoreItem>>, DateKey>((ref, day) {
      final items = ref.watch(monthItemsProvider(day.monthKey));
      final scope = ref.watch(calendarScopeProvider);
      final filters = ref.watch(calendarFiltersProvider);
      final viewer = ref.watch(currentUidProvider);
      return mapAsync<MonthItems, List<ChoreItem>>(
        items,
        (value) => <ChoreItem>[
          for (final item in filters.apply(
            value.items.where((item) => item.dateKey == day),
          ))
            if (inScope(scope, viewer, item)) item,
        ]..sort((a, b) => a.dueAt.compareTo(b.dueAt)),
      );
    });
