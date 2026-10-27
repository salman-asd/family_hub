import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/core/utils/money.dart';
import 'package:family_hub/features/bazar/fund/domain/fund_balance_calculator.dart';
import 'package:family_hub/shared/widgets/app_card.dart';
import 'package:family_hub/shared/widgets/money_text.dart';
import 'package:flutter/material.dart';

/// The fund card: the balance (large) and the month's three chips.
///
/// The balance is always the ledger sum ([FundSummary.balance]), never a stored
/// number (ADR 0007).  A closed month adds a lock line with its closing balance,
/// so a viewer understands why the number no longer moves.
class FundBalanceCard extends StatelessWidget {
  const FundBalanceCard({
    required this.summary,
    this.closedLabel,
    super.key,
  });

  final FundSummary summary;

  /// Ready text for a closed month (`appFormatters.fullDate` + the localized
  /// "Closed on ..." sentence), built by the screen.  `null` while open.
  final String? closedLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final t = context.tokens;
    final style = Theme.of(context).textTheme;
    final closed = closedLabel;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.fundBalanceTitle,
            style: style.labelLarge?.copyWith(color: t.textSecondary),
          ),
          const SizedBox(height: 4),
          MoneyText(
            key: const ValueKey('fund-balance'),
            value: summary.balance,
            style: style.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Chip(
                key: const ValueKey('fund-chip-received'),
                icon: Icons.add_circle_outline,
                label: l10n.fundReceived,
                value: summary.received,
              ),
              _Chip(
                key: const ValueKey('fund-chip-spent'),
                icon: Icons.shopping_bag_outlined,
                label: l10n.fundSpent,
                value: summary.spent,
              ),
              _Chip(
                key: const ValueKey('fund-chip-reimbursed'),
                icon: Icons.assignment_return_outlined,
                label: l10n.fundReimbursed,
                value: summary.reimbursed,
              ),
            ],
          ),
          if (closed != null) ...[
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lock_outline, size: 18, color: t.textSecondary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    closed,
                    style: style.bodySmall?.copyWith(color: t.textSecondary),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.icon,
    required this.label,
    required this.value,
    super.key,
  });

  final IconData icon;
  final String label;
  final Money value;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: t.textSecondary),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            '$label: ',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: t.textSecondary),
          ),
        ),
        MoneyText(
          value: value,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}
