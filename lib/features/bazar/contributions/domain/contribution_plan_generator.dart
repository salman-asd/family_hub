import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/core/utils/money.dart';
import 'package:family_hub/core/utils/money_math.dart';
import 'package:family_hub/features/bazar/contributions/domain/contribution.dart';

/// Splits the family's monthly [target] equally among [activeMemberIds]
/// (D-P2-11).  The remainder paisa go one each to the first members in roster
/// order, so the shares always add up to [target] and the result is
/// deterministic.  An empty roster yields no plans.
List<ContributionPlan> generateEqualSplit({
  required MonthKey month,
  required Money target,
  required List<String> activeMemberIds,
}) {
  if (activeMemberIds.isEmpty) return const <ContributionPlan>[];
  final shares = splitEqually(target, activeMemberIds.length);
  return <ContributionPlan>[
    for (var i = 0; i < activeMemberIds.length; i++)
      ContributionPlan(
        month: month,
        memberId: activeMemberIds[i],
        expected: shares[i],
      ),
  ];
}
