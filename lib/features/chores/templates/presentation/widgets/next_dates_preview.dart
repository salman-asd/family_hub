import 'package:family_hub/core/localization/app_formatters.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/features/chores/templates/domain/recurrence/recurrence.dart';
import 'package:family_hub/features/chores/templates/domain/recurrence/recurrence_engine.dart';
import 'package:flutter/material.dart';

/// The next few firing days of a schedule, computed with the SAME engine the
/// generator uses (P3-05), so the preview can never promise a date the
/// occurrences do not get.
class NextDatesPreview extends StatelessWidget {
  const NextDatesPreview({
    required this.recurrence,
    required this.startDate,
    required this.today,
    required this.formatters,
    this.endDate,
    this.count = 5,
    super.key,
  });

  final Recurrence recurrence;
  final DateKey startDate;
  final DateKey? endDate;
  final DateKey today;
  final AppFormatters formatters;
  final int count;

  /// The next [count] dates from today (or from the start when it is later).
  ///
  /// `nextAfter` is strictly after its argument, so the cursor starts one day
  /// before the first candidate. The template's own start is the lower bound;
  /// an end date stops the search.
  static List<DateKey> dates({
    required Recurrence recurrence,
    required DateKey startDate,
    required DateKey today,
    DateKey? endDate,
    int count = 5,
  }) {
    final first = today.isAfter(startDate) ? today : startDate;
    var cursor = first.addDays(-1);
    final result = <DateKey>[];
    while (result.length < count) {
      final next = RecurrenceEngine.nextAfter(
        recurrence,
        cursor,
        endDate: endDate,
      );
      if (next == null) break;
      result.add(next);
      cursor = next;
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final dates = NextDatesPreview.dates(
      recurrence: recurrence,
      startDate: startDate,
      today: today,
      endDate: endDate,
      count: count,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.choreEditorNextDates,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: Theme.of(context).hintColor,
          ),
        ),
        const SizedBox(height: 8),
        if (dates.isEmpty)
          Text(
            l10n.choreEditorNoNextDates,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Theme.of(context).hintColor),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final date in dates)
                Chip(
                  key: ValueKey<String>('next_date_${date.compact}'),
                  label: Text(formatters.fullDate(_asDate(date))),
                  avatar: const Icon(Icons.event_outlined, size: 18),
                ),
            ],
          ),
      ],
    );
  }

  static DateTime _asDate(DateKey key) =>
      DateTime.utc(key.year, key.month, key.day);
}
