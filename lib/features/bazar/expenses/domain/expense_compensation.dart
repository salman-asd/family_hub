import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/core/utils/money.dart';
import 'package:family_hub/features/bazar/advances/domain/member_advance.dart';
import 'package:family_hub/features/bazar/expenses/domain/expense.dart';
import 'package:family_hub/features/bazar/expenses/domain/funding.dart';
import 'package:family_hub/features/bazar/expenses/domain/write_plans.dart';
import 'package:family_hub/features/bazar/fund/domain/fund_transaction.dart';

/// Fields a content edit may change, named like their Firestore keys.  The
/// revision's `before` map and the audit event's `fields` param use these names.
const List<String> expenseEditableFields = <String>[
  'dateKey',
  'monthKey',
  'itemId',
  'itemName',
  'categoryId',
  'qtyMilli',
  'unit',
  'unitPricePaisa',
  'totalPaisa',
  'fundingSource',
  'paidByMemberId',
  'reimbursable',
  'purchaserId',
  'shop',
  'note',
];

/// The comparable value of one editable field.
Object? expenseFieldValue(Expense expense, String field) => switch (field) {
  'dateKey' => expense.dateKey.toString(),
  'monthKey' => expense.monthKey.toString(),
  'itemId' => expense.itemId,
  'itemName' => expense.itemName,
  'categoryId' => expense.categoryId,
  'qtyMilli' => expense.qty?.milli,
  'unit' => expense.unit?.name,
  'unitPricePaisa' => expense.unitPrice?.paisa,
  'totalPaisa' => expense.total.paisa,
  'fundingSource' => expense.funding.name,
  'paidByMemberId' => expense.paidByMemberId,
  'reimbursable' => expense.reimbursable,
  'purchaserId' => expense.purchaserId,
  'shop' => expense.shop,
  'note' => expense.note,
  _ => null,
};

/// Ledger repairs for an edit.  The original `exp_`/`stl_` rows are never
/// changed;  every difference is a new `adj_` row.
List<FundTransaction> expenseAdjustmentsFor({
  required Expense old,
  required Expense updated,
  required String eventId,
  required String actorUid,
  required DateTime now,
}) {
  final oldFunded = old.funding == FundingSource.fund;
  final newFunded = updated.funding == FundingSource.fund;
  final rows = <FundTransaction>[];

  FundTransaction row(
    Expense expense,
    Money amount,
    DateKey date,
    String suffix,
  ) => FundTransaction.adjustment(
    eventId: eventId,
    suffix: suffix,
    amount: amount,
    dateKey: date,
    refType: FundRefType.expense,
    refId: updated.id,
    createdBy: actorUid,
    createdAt: now,
  );

  if (oldFunded && newFunded) {
    if (old.monthKey != updated.monthKey) {
      rows.add(row(old, old.total, old.dateKey, 'a'));
      rows.add(row(updated, -updated.total, updated.dateKey, 'b'));
    } else {
      final delta = old.total - updated.total;
      if (!delta.isZero) rows.add(row(updated, delta, updated.dateKey, 'a'));
    }
  } else if (oldFunded && !newFunded) {
    rows.add(row(old, old.total, old.dateKey, 'a'));
  } else if (!oldFunded && newFunded) {
    rows.add(row(updated, -updated.total, updated.dateKey, 'a'));
  }
  return rows;
}

/// Creates, updates or voids the advance when the reimbursable state changes.
AdvanceChange? expenseAdvanceChangeFor({
  required Expense old,
  required Expense updated,
  required MemberAdvance? current,
}) {
  final oldReimbursable =
      old.funding == FundingSource.member && old.reimbursable;
  final newReimbursable =
      updated.funding == FundingSource.member && updated.reimbursable;

  if (oldReimbursable && !newReimbursable) {
    if (current == null || current.status == AdvanceStatus.voided) return null;
    return AdvanceChange(
      after: _copyAdvance(current, status: AdvanceStatus.voided),
    );
  }

  if (!oldReimbursable && newReimbursable) {
    return AdvanceChange(after: _newAdvance(updated), isNew: current == null);
  }

  if (oldReimbursable && newReimbursable) {
    if (current == null) {
      return AdvanceChange(after: _newAdvance(updated), isNew: true);
    }
    final changed =
        current.amount != updated.total ||
        current.memberId != updated.paidByMemberId ||
        current.dateKey != updated.dateKey ||
        current.monthKey != updated.monthKey;
    if (!changed) return null;
    return AdvanceChange(
      after: MemberAdvance(
        expenseId: updated.id,
        memberId: updated.paidByMemberId!,
        amount: updated.total,
        settled: current.settled,
        status: current.status == AdvanceStatus.voided
            ? MemberAdvance.statusFor(updated.total, current.settled)
            : current.status,
        dateKey: updated.dateKey,
        monthKey: updated.monthKey,
      ),
    );
  }
  return null;
}

MemberAdvance _newAdvance(Expense expense) => MemberAdvance(
  expenseId: expense.id,
  memberId: expense.paidByMemberId!,
  amount: expense.total,
  settled: Money.zero,
  status: AdvanceStatus.pending,
  dateKey: expense.dateKey,
  monthKey: expense.monthKey,
);

MemberAdvance _copyAdvance(
  MemberAdvance advance, {
  required AdvanceStatus status,
}) => MemberAdvance(
  expenseId: advance.expenseId,
  memberId: advance.memberId,
  amount: advance.amount,
  settled: advance.settled,
  status: status,
  dateKey: advance.dateKey,
  monthKey: advance.monthKey,
);
