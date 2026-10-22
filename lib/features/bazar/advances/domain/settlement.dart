import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/core/utils/money.dart';

/// One append-only reimbursement of a [MemberAdvance].
///
/// `fundTxId` is the deterministic `stl_<id>` row that lowers the fund in the
/// same batch.  Settlements are never updated or deleted.
final class Settlement {
  Settlement({
    required this.id,
    required this.advanceId,
    required this.memberId,
    required this.amount,
    required this.dateKey,
    required this.monthKey,
    required this.fundTxId,
    this.method,
    this.note,
  }) : assert(amount.paisa > 0, 'settlement amount must be positive'),
       assert(
         monthKey.year == dateKey.year && monthKey.month == dateKey.month,
         'monthKey must match dateKey',
       );

  final String id;
  final String advanceId;
  final String memberId;
  final Money amount;
  final DateKey dateKey;
  final MonthKey monthKey;
  final String fundTxId;
  final String? method;
  final String? note;

  @override
  bool operator ==(Object other) =>
      other is Settlement &&
      other.id == id &&
      other.advanceId == advanceId &&
      other.memberId == memberId &&
      other.amount == amount &&
      other.dateKey == dateKey &&
      other.monthKey == monthKey &&
      other.fundTxId == fundTxId &&
      other.method == method &&
      other.note == note;

  @override
  int get hashCode => Object.hash(
    id,
    advanceId,
    memberId,
    amount,
    dateKey,
    monthKey,
    fundTxId,
    method,
    note,
  );

  @override
  String toString() =>
      'Settlement($id, $advanceId, ${amount.paisa} paisa, $fundTxId)';
}
