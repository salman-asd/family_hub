import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/features/bazar/expenses/presentation/controllers/expense_form_state.dart';
import 'package:family_hub/shared/widgets/choice_wrap.dart';
import 'package:family_hub/shared/widgets/person_picker.dart';
import 'package:flutter/material.dart';

/// "Who paid?": the three funding choices and, for a member-paid expense, the
/// payer.  Plain values only, so the trip screen reuses it for its header.
class FundingSelector extends StatelessWidget {
  const FundingSelector({
    required this.funding,
    required this.onFundingChanged,
    required this.members,
    required this.paidById,
    required this.onPaidByChanged,
    this.errorText,
    this.enabled = true,
    super.key,
  });

  final FundingChoice funding;
  final ValueChanged<FundingChoice> onFundingChanged;
  final List<PersonOption> members;
  final String? paidById;
  final ValueChanged<String?> onPaidByChanged;
  final String? errorText;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final t = context.tokens;
    final label = Theme.of(context).textTheme.labelLarge?.copyWith(
      color: t.textSecondary,
    );
    return IgnorePointer(
      ignoring: !enabled,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.expenseFundingLabel, style: label),
          const SizedBox(height: 8),
          ChoiceWrap<FundingChoice>(
            selected: funding,
            onChanged: onFundingChanged,
            options: [
              ChoiceOption(
                FundingChoice.fundPool,
                l10n.expenseFundingFund,
                key: const ValueKey('funding-fund'),
              ),
              ChoiceOption(
                FundingChoice.memberReimbursable,
                l10n.expenseFundingReimbursable,
                key: const ValueKey('funding-reimbursable'),
              ),
              ChoiceOption(
                FundingChoice.memberPersonal,
                l10n.expenseFundingPersonal,
                key: const ValueKey('funding-personal'),
              ),
            ],
          ),
          if (funding.needsPayer) ...[
            const SizedBox(height: 12),
            PersonPicker(
              options: members,
              selectedId: paidById,
              onChanged: onPaidByChanged,
              label: l10n.expensePaidByLabel,
            ),
            if (errorText != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  errorText!,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: t.danger),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
