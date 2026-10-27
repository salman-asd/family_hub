import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/core/utils/date_ranges.dart';
import 'package:family_hub/features/bazar/expenses/domain/funding.dart';

/// What a report shows: a time range plus optional narrowing filters.
///
/// [preset] and [range] describe the SAME period: a screen sets the preset and
/// calls `withRange`, or supplies a custom range directly.  [range] is the one
/// the engine reads, so nothing in the engine has to resolve a preset against a
/// clock (CLAUDE.md rule 2: the domain never reads `DateTime.now()`).
final class ReportQuery {
  const ReportQuery({
    required this.preset,
    required this.range,
    this.categoryId,
    this.itemId,
    this.memberId,
    this.funding,
  }) : assert(
         preset != RangePreset.custom || range != null,
         'a custom preset needs its range',
       );

  /// A query whose range is [today]'s month.
  factory ReportQuery.thisMonth(DateKey today, {int weekStartDay = 6}) =>
      ReportQuery(
        preset: RangePreset.thisMonth,
        range: resolveRange(
          RangePreset.thisMonth,
          today: today,
          weekStartDay: weekStartDay,
        ),
      );

  /// Resolves [preset] against [today] in the family zone.  `custom` needs
  /// [custom] and throws (assert) otherwise, exactly like `resolveRange`.
  factory ReportQuery.resolve({
    required RangePreset preset,
    required DateKey today,
    int weekStartDay = 6,
    DateKeyRange? custom,
    String? categoryId,
    String? itemId,
    String? memberId,
    FundingSource? funding,
  }) => ReportQuery(
    preset: preset,
    range: resolveRange(
      preset,
      today: today,
      weekStartDay: weekStartDay,
      custom: custom,
    ),
    categoryId: categoryId,
    itemId: itemId,
    memberId: memberId,
    funding: funding,
  );

  final RangePreset preset;

  /// The inclusive day range every total is computed over.  Read it through
  /// [resolvedRange]; the field is nullable only so the assert can fire instead
  /// of a null-check crash in a release build.
  final DateKeyRange? range;

  final String? categoryId;
  final String? itemId;

  /// Matches `Expense.spenderId` (`purchaserId`, else payer, else creator).
  final String? memberId;

  final FundingSource? funding;

  /// The range the engine uses; a custom query without one is a programmer
  /// error and this throws instead of silently reporting on nothing.
  DateKeyRange get resolvedRange {
    final value = range;
    assert(value != null, 'ReportQuery needs a resolved range');
    return value!;
  }

  /// The same filters over another range (the comparison period).
  ReportQuery withRange(DateKeyRange next, {RangePreset? preset}) =>
      ReportQuery(
        preset: preset ?? this.preset,
        range: next,
        categoryId: categoryId,
        itemId: itemId,
        memberId: memberId,
        funding: funding,
      );

  @override
  bool operator ==(Object other) =>
      other is ReportQuery &&
      other.preset == preset &&
      other.range == range &&
      other.categoryId == categoryId &&
      other.itemId == itemId &&
      other.memberId == memberId &&
      other.funding == funding;

  @override
  int get hashCode => Object.hash(
    preset,
    range,
    categoryId,
    itemId,
    memberId,
    funding,
  );

  @override
  String toString() => 'ReportQuery(${preset.name}, $range)';
}
