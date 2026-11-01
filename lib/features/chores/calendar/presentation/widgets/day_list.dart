import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/features/chores/calendar/presentation/calendar_providers.dart';
import 'package:family_hub/features/chores/occurrences/presentation/occurrence_providers.dart';
import 'package:family_hub/features/chores/presentation/chores_failure_messages.dart';
import 'package:family_hub/features/chores/presentation/widgets/today_row.dart';
import 'package:family_hub/shared/widgets/empty_state.dart';
import 'package:family_hub/shared/widgets/error_view.dart';
import 'package:family_hub/shared/widgets/loading_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The chores of the selected day, under the grid (P3-22; the draggable day
/// panel of P3-23 replaces it). Every row is the same [TodayRow] the Today
/// screen uses, so a chore looks and swipes the same everywhere.
class DayList extends ConsumerWidget {
  const DayList({required this.day, super.key});

  final DateKey day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final t = context.tokens;
    final formatters = ref.watch(appFormattersProvider);
    final items = ref.watch(dayPanelItemsProvider(day));

    final Widget body;
    if (items.hasValue) {
      final list = items.requireValue;
      body = list.isEmpty
          ? EmptyState(
              icon: Icons.event_available_rounded,
              title: l10n.calendarDayEmptyTitle,
              message: l10n.calendarDayEmptyMessage,
            )
          : Column(children: [for (final item in list) TodayRow(item: item)]);
    } else if (items.hasError) {
      final error = items.error;
      body = ErrorView(
        message: l10n.choresFailureMessage(
          error is AppFailure ? error : Unknown(error),
        ),
        onRetry: () => ref.invalidate(monthOccurrencesProvider(day.monthKey)),
      );
    } else {
      body = const SizedBox(height: 120, child: LoadingView());
    }

    final count = items.hasValue ? items.requireValue.length : 0;
    final date = DateTime.utc(day.year, day.month, day.day);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
          child: Semantics(
            header: true,
            child: Text(
              l10n.calendarDayHeader(
                '${formatters.fullDate(date)}, '
                    '${formatters.weekdayName(day.isoWeekday)}',
                formatters.number(count),
              ),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: t.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        body,
      ],
    );
  }
}
