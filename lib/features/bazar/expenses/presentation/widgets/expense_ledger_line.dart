import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/features/bazar/advances/domain/member_advance.dart';
import 'package:family_hub/features/bazar/expenses/domain/expense.dart';
import 'package:family_hub/features/bazar/expenses/domain/funding.dart';
import 'package:family_hub/features/bazar/expenses/presentation/expense_detail_providers.dart';
import 'package:family_hub/features/bazar/presentation/bazar_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// "From family fund" / "Paid by Rafiq - ৳... waiting to be reimbursed": where
/// the money of one expense came from and how far its reimbursement is.
class ExpenseLedgerLine extends ConsumerWidget {
  const ExpenseLedgerLine({required this.expense, super.key});

  final Expense expense;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final t = context.tokens;
    final formatters = ref.watch(appFormattersProvider);
    final members = ref.watch(bazarMemberOptionsProvider);
    final payerId = expense.paidByMemberId;
    var name = l10n.expenseUnknownMember;
    for (final member in members) {
      if (member.id == payerId) name = member.name;
    }

    final String text;
    final IconData icon;
    if (expense.funding == FundingSource.fund) {
      text = l10n.expenseLedgerFund;
      icon = Icons.account_balance_wallet_outlined;
    } else if (!expense.reimbursable) {
      text = l10n.expenseLedgerPersonal(name);
      icon = Icons.person_outline;
    } else {
      final advance = ref.watch(expenseAdvanceProvider(expense.id)).value;
      final total = formatters.money(expense.total);
      icon = Icons.currency_exchange_outlined;
      text = switch (advance?.status) {
        AdvanceStatus.partial => l10n.expenseLedgerPartial(
          name,
          formatters.money(advance!.settled),
          formatters.money(advance!.amount),
        ),
        AdvanceStatus.settled => l10n.expenseLedgerSettled(name),
        AdvanceStatus.voided => l10n.expenseLedgerVoided,
        _ => l10n.expenseLedgerPending(name, total),
      };
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: t.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: t.textPrimary),
          ),
        ),
      ],
    );
  }
}
