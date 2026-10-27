import 'package:family_hub/features/bazar/advances/domain/member_advance.dart';
import 'package:family_hub/features/bazar/advances/domain/settlement.dart';
import 'package:family_hub/features/bazar/fund/domain/fund_transaction.dart';

/// Everything `SettleAdvance` writes, staged by the repository in ONE
/// transaction (P2-20).
///
/// * [settlement] is the append-only `settlements/<id>` row;
/// * [reimbursement] is the `stl_<id>` ledger row that lowers the fund;
/// * [advanceAfter] is the advance with its new `settled`/`status`.
///
/// The original expense and its `exp_` ledger row are never touched: paying a
/// member back is not a new expense and must not change any category total.
final class SettlementPlan {
  const SettlementPlan({
    required this.settlement,
    required this.reimbursement,
    required this.advanceAfter,
  });

  final Settlement settlement;
  final FundTransaction reimbursement;
  final MemberAdvance advanceAfter;
}
