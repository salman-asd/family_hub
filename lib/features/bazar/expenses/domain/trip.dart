import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/core/utils/money.dart';
import 'package:family_hub/features/bazar/expenses/domain/funding.dart';

/// Header input for a bazar trip before the lines are validated.
final class TripDraft {
  const TripDraft({
    required this.dateKey,
    this.shop,
    this.funding = FundingSource.fund,
    this.paidByMemberId,
    this.reimbursable = false,
    this.note,
  });

  final DateKey dateKey;
  final String? shop;
  final FundingSource funding;
  final String? paidByMemberId;
  final bool reimbursable;
  final String? note;
}

/// The trip header (`bazarTrips/{id}`).  The lines live in `expenses`.
final class Trip {
  Trip({
    required this.id,
    required this.dateKey,
    required this.monthKey,
    this.shop,
    required this.funding,
    this.paidByMemberId,
    this.reimbursable = false,
    required this.lineCount,
    required this.total,
    this.note,
  }) : assert(
         lineCount >= 1 && lineCount <= 40,
         'a trip has between 1 and 40 lines',
       ),
       assert(total.paisa > 0, 'trip total must be positive'),
       assert(
         (funding == FundingSource.member) == (paidByMemberId != null),
         'member funding requires a payer and fund funding forbids one',
       ),
       assert(
         funding == FundingSource.member || !reimbursable,
         'reimbursable is only meaningful for member funding',
       ),
       assert(
         monthKey.year == dateKey.year && monthKey.month == dateKey.month,
         'monthKey must match dateKey',
       );

  final String id;
  final DateKey dateKey;
  final MonthKey monthKey;
  final String? shop;
  final FundingSource funding;
  final String? paidByMemberId;
  final bool reimbursable;
  final int lineCount;
  final Money total;
  final String? note;

  @override
  bool operator ==(Object other) =>
      other is Trip &&
      other.id == id &&
      other.dateKey == dateKey &&
      other.monthKey == monthKey &&
      other.shop == shop &&
      other.funding == funding &&
      other.paidByMemberId == paidByMemberId &&
      other.reimbursable == reimbursable &&
      other.lineCount == lineCount &&
      other.total == total &&
      other.note == note;

  @override
  int get hashCode => Object.hash(
    id,
    dateKey,
    monthKey,
    shop,
    funding,
    paidByMemberId,
    reimbursable,
    lineCount,
    total,
    note,
  );

  @override
  String toString() => 'Trip($id, $lineCount lines, ${total.paisa} paisa)';
}
