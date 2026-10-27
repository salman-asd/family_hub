import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/core/utils/money.dart';
import 'package:family_hub/features/bazar/advances/domain/member_advance.dart';
import 'package:family_hub/features/bazar/advances/domain/settlement.dart';
import 'package:family_hub/features/bazar/advances/domain/settlement_plan.dart';
import 'package:family_hub/features/bazar/fund/domain/fund_transaction.dart';

/// Builds a [SettlementPlan] from the advance as the TRANSACTION sees it.
///
/// Pure: the repository reads the advance inside the transaction and calls
/// this, so a settlement can never be computed from a stale copy (two managers
/// tapping at once cannot both use the old `settled`).  Returns
/// `Conflict('overpayment')`, `Conflict('advance_voided')` or
/// `NotFound('advance')` instead of writing anything.
Result<SettlementPlan> buildSettlementPlan({
  required MemberAdvance? current,
  required Money amount,
  required DateKey date,
  required DateTime at,
  required String actorUid,
  required String settlementId,
  String? method,
  String? note,
}) {
  if (current == null) {
    return const Failure<SettlementPlan>(NotFound(entity: 'advance'));
  }
  if (current.status == AdvanceStatus.voided) {
    return const Failure<SettlementPlan>(Conflict(code: 'advance_voided'));
  }
  if (amount.paisa <= 0) {
    return const Failure<SettlementPlan>(
      Validation('amount', 'amount_not_positive'),
    );
  }
  if (amount > current.remaining) {
    return const Failure<SettlementPlan>(Conflict(code: 'overpayment'));
  }

  final settled = current.settled + amount;
  final settlement = Settlement(
    id: settlementId,
    advanceId: current.expenseId,
    memberId: current.memberId,
    amount: amount,
    dateKey: date,
    monthKey: date.monthKey,
    fundTxId: 'stl_$settlementId',
    method: method,
    note: note,
  );
  return Success<SettlementPlan>(
    SettlementPlan(
      settlement: settlement,
      reimbursement: FundTransaction.forReimbursement(
        settlementId: settlementId,
        amount: amount,
        dateKey: date,
        createdBy: actorUid,
        createdAt: at,
        note: note,
      ),
      advanceAfter: current.copyWith(
        settled: settled,
        status: MemberAdvance.statusFor(current.amount, settled),
      ),
    ),
  );
}
