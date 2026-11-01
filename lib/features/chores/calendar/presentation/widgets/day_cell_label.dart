import 'package:family_hub/core/localization/app_formatters.dart';
import 'package:family_hub/core/localization/generated/app_localizations.dart';
import 'package:family_hub/features/chores/calendar/domain/day_summary.dart';
import 'package:family_hub/features/chores/occurrences/domain/occurrence_status.dart';

/// The ONE sentence a screen reader hears for a day cell (B.7):
/// "25 October, Sunday, today, 3 chores, 1 overdue, 1 yours, selected".
/// Empty parts are left out; a day outside the month is only its date.
String dayCellLabel({
  required AppLocalizations l10n,
  required AppFormatters formatters,
  required DaySummary summary,
  required bool selected,
}) {
  final day = summary.dateKey;
  final parts = <String>[
    '${formatters.number(day.day)} ${formatters.monthName(day.month)}',
    formatters.weekdayName(day.isoWeekday),
    if (summary.isToday) l10n.calendarToday,
  ];
  if (!summary.isOutsideMonth) {
    if (summary.total > 0) {
      parts.add(l10n.calendarCellChores(formatters.number(summary.total)));
    }
    final overdue = summary.countOf(ChoreStatus.overdue);
    if (overdue > 0) {
      parts.add(l10n.calendarCellOverdue(formatters.number(overdue)));
    }
    if (summary.mineCount > 0) {
      parts.add(l10n.calendarCellMine(formatters.number(summary.mineCount)));
    }
  }
  if (selected) parts.add(l10n.calendarCellSelected);
  return parts.join(', ');
}
