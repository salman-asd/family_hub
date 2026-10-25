import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/core/permissions/permissions.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/features/bazar/budgets/domain/budget.dart';
import 'package:family_hub/features/bazar/budgets/presentation/budget_providers.dart';
import 'package:family_hub/features/bazar/budgets/presentation/controllers/budget_controller.dart';
import 'package:family_hub/features/bazar/budgets/presentation/widgets/budget_editor_form.dart';
import 'package:family_hub/features/bazar/budgets/presentation/widgets/budget_progress_section.dart';
import 'package:family_hub/features/bazar/expenses/presentation/widgets/form_banner.dart';
import 'package:family_hub/features/bazar/items_categories/presentation/catalog_providers.dart';
import 'package:family_hub/features/bazar/presentation/bazar_failure_messages.dart';
import 'package:family_hub/features/bazar/presentation/bazar_providers.dart';
import 'package:family_hub/features/family/presentation/permission_providers.dart';
import 'package:family_hub/shared/widgets/app_card.dart';
import 'package:family_hub/shared/widgets/busy_button.dart';
import 'package:family_hub/shared/widgets/empty_state.dart';
import 'package:family_hub/shared/widgets/error_view.dart';
import 'package:family_hub/shared/widgets/loading_view.dart';
import 'package:family_hub/shared/widgets/money_text.dart';
import 'package:family_hub/shared/widgets/month_switcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The month's plan against what has been spent (`/bazar/budget`).
///
/// Everyone sees the progress bars; only people with
/// `manageCatalogAndBudgets` see the edit, plan and copy buttons.  Spend comes
/// from the same listener as the expense list, so adding an expense moves the
/// bars at once.  A budget never blocks an expense.
class BudgetScreen extends ConsumerWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final month = ref.watch(selectedMonthProvider);
    final canManage = ref.can(Permission.manageCatalogAndBudgets);
    final budget = ref.watch(monthBudgetProvider(month));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.budgetTitle)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: MonthSwitcher(
              month: month,
              onChanged: ref.read(selectedMonthProvider.notifier).set,
            ),
          ),
          Expanded(
            child: budget.when(
              loading: () => const LoadingView(lines: 4),
              error: (_, _) => ErrorView(
                message: l10n.errorNetwork,
                onRetry: () => ref.invalidate(monthBudgetProvider(month)),
              ),
              data: (value) => _Body(
                month: month,
                budget: value,
                canManage: canManage,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({
    required this.month,
    required this.budget,
    required this.canManage,
  });

  final MonthKey month;
  final Budget? budget;
  final bool canManage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final t = context.tokens;
    final edit = ref.watch(budgetControllerProvider(month));
    final controller = ref.read(budgetControllerProvider(month).notifier);
    final categories = ref.watch(catalogIndexProvider).activeCategories;

    if (edit.editing && canManage) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          BudgetEditorForm(
            month: month,
            categories: categories,
            onSaved: () => ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(l10n.budgetSaved))),
          ),
        ],
      );
    }

    final current = budget;
    if (current == null) {
      return _Empty(
        canManage: canManage,
        busy: edit.saving,
        failure: edit.failure,
        onPlan: () => controller.startEditing(null),
        onCopy: controller.copyLastMonth,
      );
    }

    final report = ref.watch(budgetStatusProvider(month));
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (!canManage)
          FormBanner(
            icon: Icons.lock_outline,
            text: l10n.budgetReadOnly,
            color: t.textSecondary,
          ),
        BudgetProgressSection(report: report, categories: categories),
        const SizedBox(height: 16),
        _DrySummary(budget: current),
        const SizedBox(height: 12),
        FormBanner(
          icon: Icons.info_outline,
          text: l10n.budgetNote,
          color: t.textSecondary,
        ),
        if (canManage)
          OutlinedButton.icon(
            key: const ValueKey('budget-edit'),
            onPressed: () => controller.startEditing(current),
            icon: const Icon(Icons.edit_outlined),
            label: Text(l10n.budgetEdit),
          ),
      ],
    );
  }
}

class _DrySummary extends StatelessWidget {
  const _DrySummary({required this.budget});

  final Budget budget;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppCard(
      child: Row(
        children: [
          Expanded(
            child: Text(
              budget.lines.isEmpty
                  ? '${l10n.budgetDryTitle}: ${l10n.budgetDryEmpty}'
                  : l10n.budgetDryTitle,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          if (budget.lines.isNotEmpty)
            MoneyText(
              key: const ValueKey('budget-dry-total'),
              value: budget.linesTotal,
              style: Theme.of(context).textTheme.titleMedium,
            ),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({
    required this.canManage,
    required this.busy,
    required this.failure,
    required this.onPlan,
    required this.onCopy,
  });

  final bool canManage;
  final bool busy;
  final AppFailure? failure;
  final VoidCallback onPlan;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final t = context.tokens;
    final problem = failure;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        EmptyState(
          icon: Icons.savings_outlined,
          title: l10n.budgetEmptyTitle,
          message: canManage ? l10n.budgetEmptyMessage : l10n.budgetEmptyReadOnly,
          actionLabel: canManage ? l10n.budgetPlanThisMonth : null,
          onAction: canManage ? onPlan : null,
        ),
        if (canManage) ...[
          const SizedBox(height: 8),
          BusyButton(
            key: const ValueKey('budget-copy-last'),
            label: l10n.budgetCopyLast,
            busy: busy,
            busyLabel: l10n.loadingSemantics,
            onPressed: onCopy,
          ),
        ],
        if (problem != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              problem is NotFound
                  ? l10n.budgetNoLastMonth
                  : l10n.bazarFailureMessage(problem),
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: t.danger),
            ),
          ),
        const SizedBox(height: 12),
        FormBanner(
          icon: Icons.info_outline,
          text: l10n.budgetNote,
          color: t.textSecondary,
        ),
      ],
    );
  }
}
