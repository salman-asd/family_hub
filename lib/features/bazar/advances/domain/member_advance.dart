import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/core/utils/money.dart';

/// Lifecycle of a member-paid, reimbursable expense.
enum AdvanceStatus { pending, partial, settled, voided }

/// A member advance (`memberAdvances/{expenseId}`).
///
/// [settled] can never exceed [amount].  The constructor also rejects a
/// non-voided [status] that disagrees with the two amounts, so a caller cannot
/// silently leave the status behind after a settlement.
final class MemberAdvance {
  MemberAdvance({
    required this.expenseId,
    required this.memberId,
    required this.amount,
    required this.settled,
    required this.status,
    required this.dateKey,
    required this.monthKey,
  }) : assert(amount.paisa >= 0, 'advance amount must be >= 0'),
       assert(settled.paisa >= 0, 'settled amount must be >= 0'),
       assert(
         settled.paisa <= amount.paisa,
         'settled amount cannot exceed the advance amount',
       ),
       assert(
         status == AdvanceStatus.voided ||
             (settled.paisa == 0 && status == AdvanceStatus.pending) ||
             (settled.paisa > 0 &&
                 settled.paisa < amount.paisa &&
                 status == AdvanceStatus.partial) ||
             (amount.paisa > 0 &&
                 settled.paisa == amount.paisa &&
                 status == AdvanceStatus.settled),
         'advance status does not match amount/settled',
       ),
       assert(
         monthKey.year == dateKey.year && monthKey.month == dateKey.month,
         'monthKey must match dateKey',
       );

  final String expenseId;
  final String memberId;
  final Money amount;
  final Money settled;
  final AdvanceStatus status;
  final DateKey dateKey;
  final MonthKey monthKey;

  Money get remaining => amount - settled;

  /// The status implied by [amount] and [settled].
  ///
  /// `settled == 0` is pending; a value between zero and the amount is
  /// partial; equality is settled.  `settled > amount` is a programmer error.
  static AdvanceStatus statusFor(Money amount, Money settled) {
    assert(amount.paisa >= 0, 'advance amount must be >= 0');
    assert(settled.paisa >= 0, 'settled amount must be >= 0');
    assert(
      settled.paisa <= amount.paisa,
      'settled amount cannot exceed the advance amount',
    );
    if (settled.isZero) return AdvanceStatus.pending;
    if (settled < amount) return AdvanceStatus.partial;
    return AdvanceStatus.settled;
  }

  MemberAdvance copyWith({
    Money? amount,
    Money? settled,
    AdvanceStatus? status,
  }) => MemberAdvance(
    expenseId: expenseId,
    memberId: memberId,
    amount: amount ?? this.amount,
    settled: settled ?? this.settled,
    status: status ?? this.status,
    dateKey: dateKey,
    monthKey: monthKey,
  );

  @override
  bool operator ==(Object other) =>
      other is MemberAdvance &&
      other.expenseId == expenseId &&
      other.memberId == memberId &&
      other.amount == amount &&
      other.settled == settled &&
      other.status == status &&
      other.dateKey == dateKey &&
      other.monthKey == monthKey;

  @override
  int get hashCode => Object.hash(
    expenseId,
    memberId,
    amount,
    settled,
    status,
    dateKey,
    monthKey,
  );

  @override
  String toString() =>
      'MemberAdvance($expenseId, $memberId, ${status.name}, '
      '$settled/$amount)';
}
