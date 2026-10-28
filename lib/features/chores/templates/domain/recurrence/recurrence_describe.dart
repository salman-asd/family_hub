import 'package:family_hub/features/chores/templates/domain/recurrence/recurrence.dart';

/// What a recurrence IS, reduced to the values a sentence needs (P3-05).
///
/// It holds **no strings**: the presentation layer picks an ARB key from
/// [kind] and fills these numbers, so Bangla grammar (word order, plural forms,
/// "প্রতি ২ সপ্তাহে") lives in the ARB files where translators can see it, not
/// in Dart string concatenation.
final class RecurrenceSummary {
  const RecurrenceSummary({
    required this.kind,
    this.n,
    this.weekdays = const <int>[],
    this.days = const <int>[],
    this.nth,
    this.weekday,
    this.monthEnd = MonthEndMode.clamp,
  });

  /// Reduces [r] to its describing values.
  factory RecurrenceSummary.of(Recurrence r) => switch (r) {
    OnceRecurrence() => const RecurrenceSummary(kind: RecurrenceKind.once),
    DailyRecurrence() => const RecurrenceSummary(kind: RecurrenceKind.daily),
    EveryNDaysRecurrence(:final n) => RecurrenceSummary(
      kind: RecurrenceKind.everyNDays,
      n: n,
    ),
    WeekdaysRecurrence(:final weekdays) => RecurrenceSummary(
      kind: RecurrenceKind.weekdays,
      weekdays: _sorted(weekdays),
    ),
    EveryNWeeksRecurrence(:final n, :final weekdays) => RecurrenceSummary(
      kind: RecurrenceKind.everyNWeeks,
      n: n,
      weekdays: _sorted(weekdays),
    ),
    DaysOfMonthRecurrence(:final days, :final monthEnd) => RecurrenceSummary(
      kind: RecurrenceKind.daysOfMonth,
      days: _sorted(days),
      monthEnd: monthEnd,
    ),
    NthWeekdayRecurrence(:final nth, :final weekday) => RecurrenceSummary(
      kind: RecurrenceKind.nthWeekday,
      nth: nth,
      weekday: weekday,
    ),
    LastDayRecurrence() => const RecurrenceSummary(
      kind: RecurrenceKind.lastDay,
    ),
  };

  final RecurrenceKind kind;

  /// The `every n …` factor, when the kind has one.
  final int? n;

  /// ISO weekdays (1 = Monday … 7 = Sunday), ascending.
  final List<int> weekdays;

  /// Days of the month, ascending.
  final List<int> days;

  /// 1 … 4, or -1 for "last", for [RecurrenceKind.nthWeekday].
  final int? nth;

  /// ISO weekday for [RecurrenceKind.nthWeekday].
  final int? weekday;

  final MonthEndMode monthEnd;

  /// True when the sentence needs a "last" word rather than an ordinal.
  bool get isLast => nth == -1;

  static List<int> _sorted(Iterable<int> values) =>
      values.toSet().toList()..sort();

  @override
  bool operator ==(Object other) =>
      other is RecurrenceSummary &&
      other.kind == kind &&
      other.n == n &&
      other.nth == nth &&
      other.weekday == weekday &&
      other.monthEnd == monthEnd &&
      _sameList(other.weekdays, weekdays) &&
      _sameList(other.days, days);

  @override
  int get hashCode => Object.hash(
    kind,
    n,
    nth,
    weekday,
    monthEnd,
    Object.hashAll(weekdays),
    Object.hashAll(days),
  );

  @override
  String toString() =>
      'RecurrenceSummary(${kind.id}, n: $n, weekdays: $weekdays, '
      'days: $days, nth: $nth, weekday: $weekday, ${monthEnd.id})';

  static bool _sameList(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
