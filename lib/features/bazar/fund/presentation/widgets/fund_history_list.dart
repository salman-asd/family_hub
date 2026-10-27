import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:family_hub/core/localization/generated/app_localizations.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/core/utils/money.dart';
import 'package:family_hub/features/bazar/fund/domain/fund_transaction.dart';
import 'package:family_hub/shared/widgets/money_text.dart';
import 'package:flutter/material.dart';

/// The month's ledger rows: type icon + localized label + the signed amount.
///
/// The sign carries the meaning (money in / money out), so the colour is only a
/// second cue and the icon + label always say it too (rule 13).
class FundHistoryList extends StatelessWidget {
  const FundHistoryList({required this.rows, super.key});

  final List<FundTransaction> rows;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final t = context.tokens;
    final style = Theme.of(context).textTheme;

    return Column(
      children: [
        for (final row in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Icon(_icon(row.type), size: 18, color: t.textSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_label(l10n, row), style: style.bodyMedium),
                      Text(
                        row.note ?? row.refId,
                        style: style.bodySmall?.copyWith(
                          color: t.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Text(
                  row.amount.isNegative ? '−' : '+',
                  style: style.bodyMedium?.copyWith(color: t.textSecondary),
                ),
                MoneyText(
                  key: ValueKey('fund-row-${row.id}'),
                  value: Money.paisa(row.amount.paisa.abs()),
                  hideZeroFraction: true,
                  style: style.bodyMedium,
                ),
              ],
            ),
          ),
      ],
    );
  }

  static IconData _icon(FundTxType type) => switch (type) {
    FundTxType.contribution => Icons.add_circle_outline,
    FundTxType.expense => Icons.shopping_bag_outlined,
    FundTxType.reimbursement => Icons.assignment_return_outlined,
    FundTxType.opening => Icons.flag_outlined,
    FundTxType.adjustment => Icons.tune_rounded,
  };

  static String _label(AppLocalizations l10n, FundTransaction row) =>
      switch (row.type) {
        FundTxType.contribution => l10n.fundTxContribution,
        FundTxType.expense => l10n.fundTxExpense,
        FundTxType.reimbursement => l10n.fundTxReimbursement,
        FundTxType.opening => l10n.fundTxOpening,
        FundTxType.adjustment => l10n.fundTxAdjustment,
      };
}
