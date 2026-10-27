import 'package:family_hub/app/routing/app_routes.dart';
import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/features/bazar/budgets/domain/budget_status.dart';
import 'package:family_hub/features/bazar/budgets/domain/budget_alert.dart';
import 'package:family_hub/features/bazar/budgets/presentation/budget_providers.dart';
import 'package:family_hub/features/bazar/expenses/presentation/expense_providers.dart';
import 'package:family_hub/features/bazar/items_categories/domain/category.dart';
import 'package:family_hub/features/bazar/items_categories/presentation/catalog_providers.dart';
import 'package:family_hub/features/family/presentation/family_providers.dart';
import 'package:family_hub/shared/widgets/app_card.dart';
import 'package:family_hub/shared/widgets/money_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class BudgetAlertCard extends ConsumerWidget {
  const BudgetAlertCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final month = ref.watch(familyDateKeysProvider).thisMonth();
    final budget = ref.watch(monthBudgetProvider(month));
    final expenses = ref.watch(monthExpensesProvider(month));
    final categories = ref.watch(categoriesProvider);
    if (budget.isLoading || expenses.isLoading || categories.isLoading) {
      return AppCard(
        key: const ValueKey('dashboard-budget-alert'),
        margin: const EdgeInsets.only(bottom: 12),
        onTap: () => context.go(AppRoutes.bazarBudget),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.budgetAlertsTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            const Center(child: CircularProgressIndicator()),
          ],
        ),
      );
    }
    if (budget.hasError || expenses.hasError || categories.hasError) {
      return AppCard(
        key: const ValueKey('dashboard-budget-alert'),
        margin: const EdgeInsets.only(bottom: 12),
        onTap: () => context.go(AppRoutes.bazarBudget),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.cloud_off_outlined, color: context.tokens.danger),
            const SizedBox(width: 8),
            Expanded(child: Text(l10n.errorNetwork)),
          ],
        ),
      );
    }

    final alerts = ref.watch(budgetAlertsProvider);
    if (alerts.isEmpty) return const SizedBox.shrink();
    return _AlertCard(
      alert: alerts.first,
      categories: categories.value ?? const <Category>[],
      onTap: () => context.go(AppRoutes.bazarBudget),
    );
  }
}

class _AlertCard extends ConsumerWidget {
  const _AlertCard({
    required this.alert,
    required this.categories,
    required this.onTap,
  });

  final BudgetAlert alert;
  final List<Category> categories;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final tokens = context.tokens;
    final status = alert.status;
    final exceeded = status.level == BudgetLevel.exceeded;
    final icon = exceeded
        ? Icons.error_outline_rounded
        : Icons.warning_amber_rounded;
    final color = exceeded ? tokens.danger : tokens.warning;
    final label = alert.isTotal
        ? l10n.budgetOverall
        : _categoryName(
            categories,
            alert.categoryId!,
            Localizations.localeOf(context).languageCode == 'bn',
            l10n.reportCategoryColumn,
          );
    final amount = exceeded
        ? l10n.budgetOver(
            ref.watch(appFormattersProvider).money(
              status.spent - status.limit,
            ),
          )
        : l10n.budgetLeft(
            ref.watch(appFormattersProvider).money(status.remaining),
          );

    return AppCard(
      key: const ValueKey('dashboard-budget-alert'),
      margin: const EdgeInsets.only(bottom: 12),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.budgetAlertsTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            ref.watch(appFormattersProvider).monthLabel(
              ref.watch(familyDateKeysProvider).thisMonth(),
            ),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: tokens.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Semantics(
                label: l10n.budgetAlertsTitle,
                excludeSemantics: true,
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(label)),
              Flexible(child: Text(amount, textAlign: TextAlign.end)),
            ],
          ),
          const SizedBox(height: 4),
          Wrap(
            alignment: WrapAlignment.end,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 4,
            children: [
              MoneyText(value: status.spent, style: Theme.of(context).textTheme.bodySmall),
              Text(' / ', style: Theme.of(context).textTheme.bodySmall),
              MoneyText(value: status.limit, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ],
      ),
    );
  }

  static String _categoryName(
    List<Category> categories,
    String id,
    bool bangla,
    String fallback,
  ) {
    for (final category in categories) {
      if (category.id == id) return category.displayName(bangla: bangla);
    }
    return fallback;
  }
}
