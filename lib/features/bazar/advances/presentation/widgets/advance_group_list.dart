import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/features/bazar/advances/domain/advance_grouping.dart';
import 'package:family_hub/features/bazar/advances/domain/member_advance.dart';
import 'package:family_hub/features/bazar/advances/presentation/widgets/advance_row.dart';
import 'package:family_hub/shared/widgets/app_card.dart';
import 'package:family_hub/shared/widgets/money_text.dart';
import 'package:flutter/material.dart';

/// One member's block on the Advances screen: "owed to <name> ৳…" and a row per
/// open advance.
class AdvanceGroupList extends StatelessWidget {
  const AdvanceGroupList({
    required this.group,
    required this.name,
    required this.canSettle,
    required this.showSettled,
    required this.onSettle,
    super.key,
  });

  final AdvanceGroup group;
  final String name;
  final bool canSettle;
  final bool showSettled;
  final ValueChanged<MemberAdvance> onSettle;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final style = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    showSettled
                        ? l10n.advancePaidTo(name)
                        : l10n.advanceOwedTo(name),
                    style: style.titleSmall,
                  ),
                ),
                MoneyText(
                  key: ValueKey('advance-owed-${group.memberId}'),
                  value: group.totalOwed,
                  hideZeroFraction: true,
                  style: style.titleSmall,
                ),
              ],
            ),
            const SizedBox(height: 4),
            for (final advance in group.rows)
              AdvanceRow(
                key: ValueKey('advance-row-${advance.expenseId}'),
                advance: advance,
                canSettle: canSettle,
                onSettle: () => onSettle(advance),
              ),
          ],
        ),
      ),
    );
  }
}
