import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/core/utils/money.dart';
import 'package:family_hub/shared/widgets/money_text.dart';
import 'package:flutter/material.dart';

/// The automatic total (quantity x rate), shown instead of the typed field.
class BudgetLineCalculatedTotal extends StatelessWidget {
  const BudgetLineCalculatedTotal({required this.total, super.key});

  final Money? total;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final value = total;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.budgetLineTotal,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (value != null)
            MoneyText(
              key: const ValueKey('line-calculated'),
              value: value,
              style: Theme.of(context).textTheme.titleMedium,
            ),
        ],
      ),
    );
  }
}
