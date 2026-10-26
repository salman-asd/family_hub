import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/features/bazar/contributions/domain/contribution.dart';
import 'package:family_hub/features/bazar/fund/domain/fund_transaction.dart';

/// A new contribution.  [fundTx] is null for a member request (no ledger row)
/// and the `con_<id>` row for a contribution a manager recorded.
final class ContributionWritePlan {
  const ContributionWritePlan({required this.contribution, this.fundTx});

  final Contribution contribution;
  final FundTransaction? fundTx;
}

/// A manager's decision, written in ONE batch.
///
/// * approve: [updated] is `approved` and [fundTx] is `con_<id>`;
/// * reject / reject change: no ledger rows;
/// * approve change: [adjustments] holds the delta row (or the out/in pair when
///   the date moved into another month).
final class ContributionDecisionPlan {
  const ContributionDecisionPlan({
    required this.updated,
    this.fundTx,
    this.adjustments = const <FundTransaction>[],
  });

  final Contribution updated;
  final FundTransaction? fundTx;
  final List<FundTransaction> adjustments;
}

/// A void: the contribution marked voided plus the compensating row.  The
/// original `con_<id>` row is never edited.
final class ContributionVoidPlan {
  const ContributionVoidPlan({required this.voided, required this.adjustment});

  final Contribution voided;
  final FundTransaction adjustment;
}

/// The fund's first month and, when the amount is not zero, its `opening` row.
final class OpeningBalancePlan {
  const OpeningBalancePlan({required this.startMonth, this.opening});

  final MonthKey startMonth;
  final FundTransaction? opening;
}
