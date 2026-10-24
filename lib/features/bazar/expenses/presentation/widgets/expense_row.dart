import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/features/bazar/expenses/domain/expense.dart';
import 'package:family_hub/features/bazar/expenses/domain/funding.dart';
import 'package:family_hub/features/bazar/items_categories/presentation/catalog_providers.dart';
import 'package:family_hub/shared/widgets/category_badge.dart';
import 'package:family_hub/shared/widgets/item_thumb.dart';
import 'package:family_hub/shared/widgets/money_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One expense in a list: thumb, name, category, funding icon and amount.
/// A deleted row is struck through *and* labelled (never colour alone).
class ExpenseRow extends ConsumerWidget {
  const ExpenseRow({required this.expense, required this.onTap, super.key});

  final Expense expense;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final t = context.tokens;
    final theme = Theme.of(context).textTheme;
    final bangla = Localizations.localeOf(context).languageCode == 'bn';
    final category = ref.watch(catalogIndexProvider).categoriesById[expense.categoryId];
    final deleted = expense.isDeleted;
    final fundLabel = expense.funding == FundingSource.fund
        ? l10n.expenseFundingFund
        : l10n.bazarFundingMember;

    final nameStyle = theme.titleSmall?.copyWith(
      color: deleted ? t.textSecondary : t.textPrimary,
      decoration: deleted ? TextDecoration.lineThrough : null,
    );

    return Semantics(
      button: true,
      container: true,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                ItemThumb(id: expense.itemId ?? expense.id, name: expense.itemName),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        expense.itemName,
                        style: nameStyle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (category != null)
                            CategoryBadge(
                              name: category.displayName(bangla: bangla),
                              colorIndex: category.colorIndex,
                              emoji: category.emoji,
                              compact: true,
                            ),
                          if (expense.tripId != null)
                            _Tag(
                              icon: Icons.shopping_cart_outlined,
                              text: l10n.expenseRowTrip,
                            ),
                          if (deleted)
                            _Tag(
                              icon: Icons.delete_outline,
                              text: l10n.expenseRowDeleted,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    MoneyText(
                      value: expense.total,
                      style: nameStyle,
                    ),
                    const SizedBox(height: 4),
                    Tooltip(
                      message: fundLabel,
                      child: Icon(
                        expense.funding == FundingSource.fund
                            ? Icons.account_balance_wallet_outlined
                            : Icons.person_outline,
                        size: 18,
                        semanticLabel: fundLabel,
                        color: t.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: t.textSecondary),
        const SizedBox(width: 2),
        Text(
          text,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: t.textSecondary),
        ),
      ],
    );
  }
}
