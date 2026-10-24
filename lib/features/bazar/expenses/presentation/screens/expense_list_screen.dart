import 'package:family_hub/app/routing/app_routes.dart';
import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/firebase/query_limits.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/core/permissions/permissions.dart';
import 'package:family_hub/features/bazar/expenses/domain/expense_list_items.dart';
import 'package:family_hub/features/bazar/expenses/presentation/expense_detail_providers.dart';
import 'package:family_hub/features/bazar/expenses/presentation/expense_providers.dart';
import 'package:family_hub/features/bazar/expenses/presentation/widgets/expense_filter_sheet.dart';
import 'package:family_hub/features/bazar/expenses/presentation/widgets/expense_row.dart';
import 'package:family_hub/features/bazar/expenses/presentation/widgets/form_banner.dart';
import 'package:family_hub/features/bazar/presentation/bazar_failure_messages.dart';
import 'package:family_hub/features/bazar/presentation/bazar_providers.dart';
import 'package:family_hub/features/family/presentation/permission_providers.dart';
import 'package:family_hub/shared/widgets/day_section_header.dart';
import 'package:family_hub/shared/widgets/empty_state.dart';
import 'package:family_hub/shared/widgets/error_view.dart';
import 'package:family_hub/shared/widgets/loading_view.dart';
import 'package:family_hub/shared/widgets/money_text.dart';
import 'package:family_hub/shared/widgets/month_switcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// The month's expenses grouped by day, with filters and the filtered total
/// (`/bazar/expenses`).  One listener (`monthExpensesProvider`) feeds it.
class ExpenseListScreen extends ConsumerStatefulWidget {
  const ExpenseListScreen({super.key});

  @override
  ConsumerState<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends ConsumerState<ExpenseListScreen> {
  int _visible = defaultPageSize;

  void _resetPaging() => setState(() => _visible = defaultPageSize);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final t = context.tokens;
    final month = ref.watch(selectedMonthProvider);
    final filters = ref.watch(expenseFiltersProvider);
    final data = ref.watch(expenseListProvider);
    final locked = ref.watch(monthLockedProvider(month));
    final canAdd = ref.can(Permission.addOwnExpense);
    final filtered =
        filters.range != null ||
        filters.categoryId != null ||
        filters.itemId != null ||
        filters.memberId != null ||
        filters.funding != null ||
        filters.includeDeleted;
    final formatters = ref.watch(appFormattersProvider);

    final items = buildExpenseListItems(data.rows, limit: _visible);
    final hasMoreLocal = data.rows.length > _visible;

    final Widget body;
    if (data.loading) {
      body = const LoadingView(lines: 6, showAvatar: true);
    } else if (data.error != null) {
      final error = data.error;
      body = ErrorView(
        message: error is AppFailure
            ? l10n.bazarFailureMessage(error)
            : l10n.bazarErrUnknown,
        onRetry: () => ref.invalidate(monthExpensesProvider(month)),
      );
    } else if (data.rows.isEmpty) {
      body = filtered
          ? EmptyState(
              icon: Icons.filter_alt_off_outlined,
              title: l10n.expenseListFilteredEmptyTitle,
              message: l10n.expenseListFilteredEmptyMessage,
              actionLabel: l10n.expenseFilterReset,
              onAction: () => ref.read(expenseFiltersProvider.notifier).reset(),
            )
          : EmptyState(
              icon: Icons.receipt_long_outlined,
              title: l10n.expenseListEmptyTitle,
              message: l10n.expenseListEmptyMessage,
              actionLabel: canAdd && !locked ? l10n.expenseAddTitle : null,
              onAction: canAdd && !locked
                  ? () => context.push(AppRoutes.bazarExpenseNew)
                  : null,
            );
    } else {
      body = ListView.builder(
        key: const ValueKey('expense-list'),
        padding: const EdgeInsets.only(bottom: 96),
        itemCount: items.length + 1,
        itemBuilder: (context, index) {
          if (index == items.length) {
            return _Footer(
              showMoreLocal: hasMoreLocal,
              showMoreRemote: data.remote && data.hasMoreRemote,
              onMoreLocal: () => setState(() => _visible += defaultPageSize),
              onMoreRemote: () {
                final range = filters.range;
                if (range != null) {
                  ref.read(rangeExpensesProvider(range).notifier).loadMore();
                }
              },
            );
          }
          return switch (items[index]) {
            DayHeaderItem(:final date, :final total) => DaySectionHeader(
              dateLabel:
                  '${formatters.weekdayShort(date.weekday)}, '
                  '${formatters.fullDate(DateTime(date.year, date.month, date.day))}',
              total: total,
            ),
            ExpenseRowItem(:final expense) => ExpenseRow(
              expense: expense,
              onTap: () => context.push(AppRoutes.bazarExpense(expense.id)),
            ),
          };
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.expenseListTitle),
        actions: [
          if (data.remote && filters.range != null)
            IconButton(
              key: const ValueKey('range-refresh'),
              tooltip: l10n.expenseListRefresh,
              icon: const Icon(Icons.refresh),
              onPressed: () =>
                  ref.read(rangeExpensesProvider(filters.range!).notifier).refresh(),
            ),
          IconButton(
            key: const ValueKey('open-filters'),
            tooltip: l10n.expenseFilterTitle,
            icon: Icon(filtered ? Icons.filter_alt : Icons.filter_alt_outlined),
            onPressed: () async {
              await showExpenseFilterSheet(context);
              _resetPaging();
            },
          ),
        ],
      ),
      floatingActionButton: canAdd && !locked
          ? FloatingActionButton(
              key: const ValueKey('expense-add-fab'),
              tooltip: l10n.expenseAddTitle,
              onPressed: () => context.push(AppRoutes.bazarExpenseNew),
              child: const Icon(Icons.add),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
            child: MonthSwitcher(
              month: month,
              onChanged: (m) {
                ref.read(selectedMonthProvider.notifier).set(m);
                _resetPaging();
              },
            ),
          ),
          if (locked)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: FormBanner(
                icon: Icons.lock_outline,
                text: l10n.expenseListLocked,
                color: t.warning,
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.expenseListFilteredTotal,
                    style: Theme.of(
                      context,
                    ).textTheme.titleSmall?.copyWith(color: t.textSecondary),
                  ),
                ),
                MoneyText(
                  value: data.total,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: t.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: body),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({
    required this.showMoreLocal,
    required this.showMoreRemote,
    required this.onMoreLocal,
    required this.onMoreRemote,
  });

  final bool showMoreLocal;
  final bool showMoreRemote;
  final VoidCallback onMoreLocal;
  final VoidCallback onMoreRemote;

  @override
  Widget build(BuildContext context) {
    if (!showMoreLocal && !showMoreRemote) return const SizedBox(height: 8);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: OutlinedButton(
        key: const ValueKey('expense-show-more'),
        onPressed: showMoreLocal ? onMoreLocal : onMoreRemote,
        child: Text(context.l10n.expenseShowMore),
      ),
    );
  }
}
