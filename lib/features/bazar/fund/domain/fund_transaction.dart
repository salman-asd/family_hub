import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/core/utils/money.dart';

/// What a fund ledger row represents.
enum FundTxType { contribution, expense, reimbursement, opening, adjustment }

/// The record a ledger row points at.
enum FundRefType { expense, contribution, settlement, month, manual }

/// One append-only row of `families/{f}/fundTransactions`.
///
/// [amount] is signed and is the only source of the fund balance (ADR 0007):
/// contributions are positive, expenses and reimbursements are negative, and
/// openings/adjustments may have either sign but are never zero.  The named
/// factories below are the intended construction path; the public constructor
/// is for rehydrating a stored document and enforces the same sign rule.
final class FundTransaction {
  FundTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.dateKey,
    required this.monthKey,
    required this.refType,
    required this.refId,
    required this.createdBy,
    required this.createdAt,
    this.note,
  }) : assert(
         (type == FundTxType.contribution && amount.paisa > 0) ||
             ((type == FundTxType.expense ||
                     type == FundTxType.reimbursement) &&
                 amount.paisa < 0) ||
             ((type == FundTxType.opening || type == FundTxType.adjustment) &&
                 amount.paisa != 0),
         'FundTransaction amount has the wrong sign for $type',
       ),
       assert(
         monthKey.year == dateKey.year && monthKey.month == dateKey.month,
         'monthKey must match dateKey',
       );

  /// A fund-funded expense: `exp_<expenseId>`, negative total.
  factory FundTransaction.forExpense({
    required String expenseId,
    required Money total,
    required DateKey dateKey,
    required String createdBy,
    required DateTime createdAt,
    String? note,
  }) {
    assert(total.paisa > 0, 'expense total must be positive');
    return FundTransaction(
      id: 'exp_$expenseId',
      type: FundTxType.expense,
      amount: -total,
      dateKey: dateKey,
      monthKey: dateKey.monthKey,
      refType: FundRefType.expense,
      refId: expenseId,
      createdBy: createdBy,
      createdAt: createdAt,
      note: note,
    );
  }

  /// An approved contribution: `con_<contributionId>`, positive amount.
  factory FundTransaction.forContribution({
    required String contributionId,
    required Money amount,
    required DateKey dateKey,
    required String createdBy,
    required DateTime createdAt,
    String? note,
  }) {
    assert(amount.paisa > 0, 'contribution amount must be positive');
    return FundTransaction(
      id: 'con_$contributionId',
      type: FundTxType.contribution,
      amount: amount,
      dateKey: dateKey,
      monthKey: dateKey.monthKey,
      refType: FundRefType.contribution,
      refId: contributionId,
      createdBy: createdBy,
      createdAt: createdAt,
      note: note,
    );
  }

  /// Money paid back to a member: `stl_<settlementId>`, negative amount.
  factory FundTransaction.forReimbursement({
    required String settlementId,
    required Money amount,
    required DateKey dateKey,
    required String createdBy,
    required DateTime createdAt,
    String? note,
  }) {
    assert(amount.paisa > 0, 'reimbursement amount must be positive');
    return FundTransaction(
      id: 'stl_$settlementId',
      type: FundTxType.reimbursement,
      amount: -amount,
      dateKey: dateKey,
      monthKey: dateKey.monthKey,
      refType: FundRefType.settlement,
      refId: settlementId,
      createdBy: createdBy,
      createdAt: createdAt,
      note: note,
    );
  }

  /// The opening row for [monthKey]: `open_<yyyy-MM>`.  Its sign is free.
  factory FundTransaction.opening({
    required MonthKey monthKey,
    required Money amount,
    required String createdBy,
    required DateTime createdAt,
    String? note,
  }) {
    assert(amount.paisa != 0, 'opening amount must not be zero');
    return FundTransaction(
      id: 'open_$monthKey',
      type: FundTxType.opening,
      amount: amount,
      dateKey: monthKey.startOfMonth,
      monthKey: monthKey,
      refType: FundRefType.month,
      refId: monthKey.toString(),
      createdBy: createdBy,
      createdAt: createdAt,
      note: note,
    );
  }

  /// A compensating row: `adj_<eventId>[_suffix]`.  Its sign is free.
  factory FundTransaction.adjustment({
    required String eventId,
    required Money amount,
    required DateKey dateKey,
    required FundRefType refType,
    required String refId,
    required String createdBy,
    required DateTime createdAt,
    String? suffix,
    String? note,
  }) {
    assert(amount.paisa != 0, 'adjustment amount must not be zero');
    final cleanedSuffix = suffix?.trim() ?? '';
    return FundTransaction(
      id: cleanedSuffix.isEmpty
          ? 'adj_$eventId'
          : 'adj_${eventId}_$cleanedSuffix',
      type: FundTxType.adjustment,
      amount: amount,
      dateKey: dateKey,
      monthKey: dateKey.monthKey,
      refType: refType,
      refId: refId,
      createdBy: createdBy,
      createdAt: createdAt,
      note: note,
    );
  }

  final String id;
  final FundTxType type;

  /// Signed integer paisa; see the class comment.
  final Money amount;
  final DateKey dateKey;
  final MonthKey monthKey;
  final FundRefType refType;
  final String refId;
  final String createdBy;
  final DateTime createdAt;
  final String? note;

  @override
  bool operator ==(Object other) =>
      other is FundTransaction &&
      other.id == id &&
      other.type == type &&
      other.amount == amount &&
      other.dateKey == dateKey &&
      other.monthKey == monthKey &&
      other.refType == refType &&
      other.refId == refId &&
      other.createdBy == createdBy &&
      other.createdAt == createdAt &&
      other.note == note;

  @override
  int get hashCode => Object.hash(
    id,
    type,
    amount,
    dateKey,
    monthKey,
    refType,
    refId,
    createdBy,
    createdAt,
    note,
  );

  @override
  String toString() =>
      'FundTransaction($id, ${type.name}, ${amount.paisa} paisa)';
}

/// The read the month carry-forward needs: the amount of a month's `opening`
/// row, or `null` when that month has none yet.
///
/// The ledger port implements it as one exact-id `get` of `open_<yyyy-MM>`,
/// which the rules let every active member read.  A separate port (instead of
/// a `getTransactionsFromServer` call) keeps `CloseMonth` from depending on a
/// server-only read it can do without — and the interface stays fake-able.
abstract interface class ExistingOpeningLedger {
  Future<Result<Money?>> getOpeningAmount(String familyId, MonthKey month);
}
