import 'package:family_hub/app/routing/app_routes.dart';
import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/core/utils/money.dart';
import 'package:family_hub/features/bazar/expenses/presentation/expense_providers.dart';
import 'package:family_hub/features/bazar/items_categories/domain/category.dart';
import 'package:family_hub/features/bazar/items_categories/presentation/catalog_providers.dart';
import 'package:family_hub/features/family/presentation/family_providers.dart';
import 'package:family_hub/shared/widgets/app_card.dart';
import 'package:family_hub/shared/widgets/money_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class BazarMonthCard extends ConsumerWidget {
  const BazarMonthCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final month = ref.watch(familyDateKeysProvider).thisMonth();
    final expenses = ref.watch(monthExpensesProvider(month));
    final categories = ref.watch(categoriesProvider);
    final spend = ref.watch(monthSpendProvider(month));
    final onTap = () => context.go(AppRoutes.bazarExpenses);

    return AppCard(
      key: const ValueKey('dashboard-bazar-month'),
      margin: const EdgeInsets.only(bottom: 12),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.expenseListTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            ref.watch(appFormattersProvider).monthLabel(month),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: context.tokens.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          if (expenses.isLoading || categories.isLoading)
            const Center(child: CircularProgressIndicator())
          else if (expenses.hasError || categories.hasError)
            _DashboardError(message: l10n.errorNetwork)
          else
            _SpendSummary(
              total: spend.total,
              byCategory: spend.byCategory,
              categories: categories.value ?? const <Category>[],
            ),
        ],
      ),
    );
  }
}

class _SpendSummary extends StatelessWidget {
  const _SpendSummary({
    required this.total,
    required this.byCategory,
    required this.categories,
  });

  final Money total;
  final Map<String, Money> byCategory;
  final List<Category> categories;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final style = Theme.of(context).textTheme;
    final spent = byCategory.entries.toList()
      ..sort((a, b) {
        final byAmount = b.value.compareTo(a.value);
        return byAmount != 0 ? byAmount : a.key.compareTo(b.key);
      });

    if (spent.isEmpty) return Text(l10n.expenseListEmptyTitle);

    final topCategory = spent.first;
    final category = _findCategory(categories, topCategory.key);
    final isBangla = Localizations.localeOf(context).languageCode == 'bn';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.reportTotal,
                style: style.bodyMedium?.copyWith(
                  color: context.tokens.textSecondary,
                ),
              ),
            ),
            MoneyText(
              value: total,
              style: style.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.reportCategoryColumn,
                style: style.bodyMedium?.copyWith(
                  color: context.tokens.textSecondary,
                ),
              ),
            ),
            Flexible(
              child: Text(
                category?.displayName(bangla: isBangla) ??
                    l10n.reportCategoryColumn,
                textAlign: TextAlign.end,
                style: style.bodyMedium,
              ),
            ),
            const SizedBox(width: 8),
            MoneyText(value: topCategory.value, style: style.bodyMedium),
          ],
        ),
      ],
    );
  }

  static Category? _findCategory(List<Category> categories, String id) {
    for (final category in categories) {
      if (category.id == id) return category;
    }
    return null;
  }
}

class _DashboardError extends StatelessWidget {
  const _DashboardError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(Icons.cloud_off_outlined, color: context.tokens.danger),
      const SizedBox(width: 8),
      Expanded(child: Text(message)),
    ],
  );
}
