import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/core/utils/date_ranges.dart';

/// The day grid of a calendar month (P3-02, Appendix B).
///
/// Pure Dart, week-start aware, always FULL weeks: every row holds exactly
/// seven consecutive days, the days before and after [month] belong to the
/// neighbouring months, and there are 4–6 rows. The calendar widgets render
/// this; nothing here knows about Firestore, colours or "today".
final class MonthMatrix {
  const MonthMatrix(this.month, this.weekStartDay, this.rows)
    : assert(
        weekStartDay >= DateTime.monday && weekStartDay <= DateTime.sunday,
        'weekStartDay must be 1..7',
      );

  /// Builds the grid for [month] with weeks starting on [weekStartDay]
  /// (1 = Monday … 7 = Sunday; 6 = Saturday is the family default).
  factory MonthMatrix.build(MonthKey month, int weekStartDay) {
    final firstOfMonth = month.startOfMonth;
    final firstCell = startOfWeek(firstOfMonth, weekStartDay);
    // The last week is the one that holds the last day: it appears already in
    // the first four weeks when the padding in front is short (a 28-day
    // month starting on the week start needs no extra row at all).
    final lastOfMonth = month.endOfMonth;
    final lastWeekStart = startOfWeek(lastOfMonth, weekStartDay);
    final rowCount = firstCell.daysUntil(lastWeekStart) ~/ 7 + 1;
    assert(rowCount >= 4 && rowCount <= 6, 'a month needs 4..6 weeks');

    final rows = <List<DateKey>>[];
    for (var row = 0; row < rowCount; row++) {
      final start = firstCell.addDays(row * 7);
      rows.add(
        List<DateKey>.unmodifiable(<DateKey>[
          for (var column = 0; column < 7; column++) start.addDays(column),
        ]),
      );
    }
    return MonthMatrix(
      month,
      weekStartDay,
      List<List<DateKey>>.unmodifiable(rows),
    );
  }

  /// The month the grid shows (days of other months may appear in it).
  final MonthKey month;

  /// 1 = Monday … 7 = Sunday, from `settings/chores.weekStartDay`.
  final int weekStartDay;

  /// 4–6 rows of exactly 7 days, each row a full week.
  final List<List<DateKey>> rows;

  /// The weekdays top to bottom: start 6 (Saturday) gives
  /// `[6, 7, 1, 2, 3, 4, 5]`.
  static List<int> weekdayOrder(int weekStartDay) {
    assert(
      weekStartDay >= DateTime.monday && weekStartDay <= DateTime.sunday,
      'weekStartDay must be 1..7',
    );
    return List<int>.unmodifiable(<int>[
      for (var offset = 0; offset < 7; offset++)
        (weekStartDay - 1 + offset) % 7 + 1,
    ]);
  }

  /// The full week around [day] for a given start, from [weekStartDay] to the
  /// day before it (week start 6 gives Saturday to Friday).
  static DateKeyRange weekOf(DateKey day, int weekStartDay) {
    final start = startOfWeek(day, weekStartDay);
    return DateKeyRange(start, start.addDays(6));
  }

  /// [weekOf] for this grid's own week start.
  DateKeyRange weekContaining(DateKey day) => weekOf(day, weekStartDay);

  /// True when [day] belongs to [month] rather than to a neighbouring month
  /// shown to complete the first or last week.
  bool isInMonth(DateKey day) => day.monthKey == month;

  /// Every day of the grid, row by row.
  List<DateKey> get days => <DateKey>[for (final row in rows) ...row];
}
