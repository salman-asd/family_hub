import 'package:family_hub/app/routing/app_routes.dart';
import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/core/localization/unit_labels.dart';
import 'package:family_hub/features/bazar/expenses/domain/expense.dart';
import 'package:family_hub/features/bazar/expenses/presentation/expense_detail_providers.dart';
import 'package:family_hub/features/bazar/expenses/presentation/expense_providers.dart';
import 'package:family_hub/features/bazar/expenses/presentation/widgets/expense_delete_flow.dart';
import 'package:family_hub/features/bazar/expenses/presentation/widgets/expense_history_section.dart';
import 'package:family_hub/features/bazar/expenses/presentation/widgets/expense_ledger_line.dart';
import 'package:family_hub/features/bazar/expenses/presentation/widgets/form_banner.dart';
import 'package:family_hub/features/bazar/items_categories/presentation/catalog_providers.dart';
import 'package:family_hub/features/bazar/presentation/bazar_failure_messages.dart';
import 'package:family_hub/features/bazar/presentation/bazar_providers.dart';
import 'package:family_hub/shared/widgets/app_card.dart';
import 'package:family_hub/shared/widgets/category_badge.dart';
import 'package:family_hub/shared/widgets/error_view.dart';
import 'package:family_hub/shared/widgets/loading_view.dart';
import 'package:family_hub/shared/widgets/money_text.dart';
import 'package:family_hub/shared/widgets/permission_gate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// One expense with its ledger line, actions and history
/// (`/bazar/expenses/:id`).
class ExpenseDetailScreen extends ConsumerWidget {
  const ExpenseDetailScreen({required this.expenseId, super.key});

  final String expenseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final async = ref.watch(liveExpenseProvider(expenseId));
    final Widget body;
    if (async.isLoading && !async.hasValue) {
      body = const LoadingView(lines: 6);
    } else if (async.hasError && !async.hasValue) {
      final error = async.error;
      body = ErrorView(
        message: error is AppFailure
            ? l10n.bazarFailureMessage(error)
            : l10n.bazarErrUnknown,
        onRetry: () => ref.invalidate(expenseDetailProvider(expenseId)),
      );
    } else if (async.value == null) {
      body = ErrorView(message: l10n.bazarErrNotFound);
    } else {
      body = _DetailBody(expense: async.value!);
    }
    return Scaffold(
      appBar: AppBar(title: Text(l10n.expenseDetailTitle)),
      body: body,
    );
  }
}

class _DetailBody extends ConsumerWidget {
  const _DetailBody({required this.expense});

  final Expense expense;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final t = context.tokens;
    final formatters = ref.watch(appFormattersProvider);
    final bangla = Localizations.localeOf(context).languageCode == 'bn';
    final category = ref
        .watch(catalogIndexProvider)
        .categoriesById[expense.categoryId];
    final canEdit = ref.watch(canEditExpenseProvider(expense));
    final locked = ref.watch(monthLockedProvider(expense.monthKey));
    final members = ref.watch(bazarMemberOptionsProvider);
    var addedBy = l10n.expenseUnknownMember;
    for (final m in members) {
      if (m.id == expense.createdBy) addedBy = m.name;
    }
    final theme = Theme.of(context).textTheme;
    final qty = expense.qty;
    final unit = expense.unit;

    Widget line(String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: theme.bodyMedium?.copyWith(color: t.textSecondary),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(value, style: theme.bodyMedium, textAlign: TextAlign.end),
          ),
        ],
      ),
    );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (expense.isDeleted)
          FormBanner(
            icon: Icons.delete_outline,
            text: l10n.expenseRowDeleted,
            color: t.danger,
          ),
        if (locked)
          FormBanner(
            icon: Icons.lock_outline,
            text: l10n.expenseListLocked,
            color: t.warning,
          ),
        Text(expense.itemName, style: theme.headlineSmall),
        const SizedBox(height: 4),
        MoneyText(
          value: expense.total,
          style: theme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        if (category != null)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: CategoryBadge(
              name: category.displayName(bangla: bangla),
              colorIndex: category.colorIndex,
              emoji: category.emoji,
            ),
          ),
        const SizedBox(height: 16),
        AppCard(
          child: Column(
            children: [
              line(
                l10n.expenseDateLabel,
                formatters.fullDate(
                  DateTime(
                    expense.dateKey.year,
                    expense.dateKey.month,
                    expense.dateKey.day,
                  ),
                ),
              ),
              if (qty != null && unit != null)
                line(
                  l10n.expenseQtyField,
                  '${qty.toDecimalString()} ${l10n.unitLabel(unit)}',
                ),
              if (expense.unitPrice != null)
                line(
                  l10n.expenseUnitPriceField,
                  formatters.money(expense.unitPrice!),
                ),
              if ((expense.shop ?? '').isNotEmpty)
                line(l10n.expenseShopField, expense.shop!),
              if ((expense.note ?? '').isNotEmpty)
                line(l10n.expenseNoteField, expense.note!),
              line(l10n.expenseDetailAddedBy, addedBy),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(l10n.expenseDetailPayment, style: theme.titleMedium),
        const SizedBox(height: 8),
        ExpenseLedgerLine(expense: expense),
        const SizedBox(height: 24),
        PermissionGate(
          allowed: canEdit,
          mode: PermissionGateMode.disable,
          deniedMessage: l10n.expenseNotYoursMessage,
          child: _Actions(expense: expense, locked: locked),
        ),
        if (canEdit) ...[
          const SizedBox(height: 24),
          ExpenseHistorySection(expenseId: expense.id),
        ],
      ],
    );
  }
}

class _Actions extends ConsumerWidget {
  const _Actions({required this.expense, required this.locked});

  final Expense expense;
  final bool locked;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    if (expense.isDeleted) {
      return SizedBox(
        width: double.infinity,
        height: 52,
        child: FilledButton.icon(
          key: const ValueKey('expense-restore'),
          icon: const Icon(Icons.restore),
          label: Text(l10n.expenseRestore),
          onPressed: locked
              ? null
              : () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final failure = await restoreDeletedExpense(ref, expense);
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        failure == null
                            ? l10n.expenseRestored
                            : l10n.bazarFailureMessage(failure),
                      ),
                    ),
                  );
                },
        ),
      );
    }
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 52,
            child: OutlinedButton.icon(
              key: const ValueKey('expense-edit'),
              icon: const Icon(Icons.edit_outlined),
              label: Text(l10n.actionEdit),
              onPressed: locked
                  ? null
                  : () async {
                      await context.push(AppRoutes.bazarExpenseEdit(expense.id));
                      if (!context.mounted) return;
                      ref.invalidate(expenseDetailProvider(expense.id));
                    },
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SizedBox(
            height: 52,
            child: OutlinedButton.icon(
              key: const ValueKey('expense-delete'),
              icon: const Icon(Icons.delete_outline),
              label: Text(l10n.actionDelete),
              onPressed: locked
                  ? null
                  : () async {
                      final deleted = await confirmAndDeleteExpense(
                        context,
                        ref,
                        expense,
                      );
                      if (deleted && context.mounted && context.canPop()) {
                        context.pop();
                      }
                    },
            ),
          ),
        ),
      ],
    );
  }
}
