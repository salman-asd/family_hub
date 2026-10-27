import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/features/bazar/fund/domain/month_closing.dart';

/// The closing for [month] in [rows], or `null` when the month is open.
MonthClosing? closingOf(Iterable<MonthClosing> rows, MonthKey month) {
  for (final row in rows) {
    if (row.monthKey == month) return row;
  }
  return null;
}

/// Months the close screen offers: the current month and the
/// [monthCount] - 1 before it, plus any month that was ever closed (so an old
/// closing can be reopened), newest first.
List<MonthKey> monthChoices(
  MonthKey thisMonth,
  Iterable<MonthClosing> rows, {
  int monthCount = 12,
}) {
  final months = <MonthKey>{
    for (var i = 0; i < monthCount; i++) thisMonth.addMonths(-i),
    for (final row in rows) row.monthKey,
  }.toList()..sort((a, b) => b.compareTo(a));
  return months;
}
