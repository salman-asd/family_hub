import 'package:family_hub/core/localization/app_formatters.dart';
import 'package:family_hub/core/localization/generated/app_localizations.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/features/chores/templates/domain/recurrence/recurrence.dart';
import 'package:family_hub/features/chores/templates/domain/recurrence/recurrence_describe.dart';
import 'package:flutter/material.dart';

/// Turns a [RecurrenceSummary] into one localized sentence (P3-16).
///
/// The domain summary holds values only; every word, ordinal and separator comes
/// from the ARB files, so Bangla word order stays with the translators.
class RecurrenceSummaryText extends StatelessWidget {
  const RecurrenceSummaryText({
    required this.summary,
    required this.formatters,
    this.style,
    super.key,
  });

  final RecurrenceSummary summary;
  final AppFormatters formatters;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) =>
      Text(text(context.l10n, formatters, summary), style: style);

  /// The sentence for [summary], usable from tests and other widgets.
  static String text(
    AppLocalizations l10n,
    AppFormatters formatters,
    RecurrenceSummary summary,
  ) {
    switch (summary.kind) {
      case RecurrenceKind.once:
        return l10n.recurrenceSummaryOnce;
      case RecurrenceKind.daily:
        return l10n.recurrenceSummaryDaily;
      case RecurrenceKind.everyNDays:
        return l10n.recurrenceSummaryEveryNDays(
          formatters.number(summary.n ?? 0),
        );
      case RecurrenceKind.weekdays:
        return l10n.recurrenceSummaryWeekdays(
          _weekdays(l10n, formatters, summary.weekdays),
        );
      case RecurrenceKind.everyNWeeks:
        return l10n.recurrenceSummaryEveryNWeeks(
          formatters.number(summary.n ?? 0),
          _weekdays(l10n, formatters, summary.weekdays),
        );
      case RecurrenceKind.daysOfMonth:
        return l10n.recurrenceSummaryDaysOfMonth(
          _numbers(l10n, formatters, summary.days),
        );
      case RecurrenceKind.nthWeekday:
        return l10n.recurrenceSummaryNthWeekday(
          _nth(l10n, summary.nth),
          formatters.weekdayName(summary.weekday ?? DateTime.monday),
        );
      case RecurrenceKind.lastDay:
        return l10n.recurrenceSummaryLastDay;
    }
  }

  static String _weekdays(
    AppLocalizations l10n,
    AppFormatters formatters,
    List<int> weekdays,
  ) => weekdays
      .map(formatters.weekdayName)
      .join(l10n.recurrenceListSeparator);

  static String _numbers(
    AppLocalizations l10n,
    AppFormatters formatters,
    List<int> values,
  ) => values.map(formatters.number).join(l10n.recurrenceListSeparator);

  static String _nth(AppLocalizations l10n, int? nth) => switch (nth) {
    1 => l10n.recurrenceNthFirst,
    2 => l10n.recurrenceNthSecond,
    3 => l10n.recurrenceNthThird,
    4 => l10n.recurrenceNthFourth,
    _ => l10n.recurrenceNthLast,
  };
}
