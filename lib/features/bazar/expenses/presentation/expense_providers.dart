import 'package:family_hub/core/permissions/permissions.dart';
import 'package:family_hub/core/utils/clock_provider.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/core/utils/money.dart';
import 'package:family_hub/features/bazar/advances/presentation/advance_providers.dart';
import 'package:family_hub/features/bazar/expenses/domain/expense.dart';
import 'package:family_hub/features/bazar/expenses/domain/expense_filters.dart';
import 'package:family_hub/features/bazar/expenses/domain/expense_repository.dart';
import 'package:family_hub/features/bazar/expenses/domain/month_spend.dart';
import 'package:family_hub/features/bazar/expenses/domain/usecases/add_bazar_trip.dart';
import 'package:family_hub/features/bazar/expenses/domain/usecases/add_expense.dart';
import 'package:family_hub/features/bazar/expenses/domain/usecases/check_duplicate.dart';
import 'package:family_hub/features/bazar/expenses/domain/usecases/restore_expense.dart';
import 'package:family_hub/features/bazar/expenses/domain/usecases/soft_delete_expense.dart';
import 'package:family_hub/features/bazar/expenses/domain/usecases/update_expense.dart';
import 'package:family_hub/features/bazar/fund/presentation/fund_providers.dart';
import 'package:family_hub/features/bazar/items_categories/presentation/catalog_providers.dart';
import 'package:family_hub/features/bazar/presentation/bazar_providers.dart';
import 'package:family_hub/features/family/presentation/family_providers.dart';
import 'package:family_hub/features/family/presentation/permission_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Overridden in `bootstrap.dart` and in tests.
final expenseRepositoryProvider = Provider<ExpenseRepository>(
  (ref) => throw UnimplementedError(
    'expenseRepositoryProvider must be overridden (bootstrap.dart / tests).',
  ),
);

/// One live listener per month, bounded by `kMaxListenerDocs`.  The current
/// month stays alive so switching tabs never re-reads it; other months are
/// released when their last screen leaves.
final monthExpensesProvider = StreamProvider.autoDispose
    .family<List<Expense>, MonthKey>((ref, month) {
      final familyId = ref.watch(currentFamilyIdProvider);
      if (familyId == null) return Stream.value(const <Expense>[]);
      if (month == ref.read(familyDateKeysProvider).thisMonth()) {
        ref.keepAlive();
      }
      return ref.watch(expenseRepositoryProvider).watchMonth(familyId, month);
    });

/// The single spend aggregation (CLAUDE.md rule 30).  Budgets, reports and the
/// dashboard all read this, so they can never disagree.
final monthSpendProvider = Provider.autoDispose.family<MonthSpend, MonthKey>(
  (ref, month) => MonthSpend.of(
    ref.watch(monthExpensesProvider(month)).value ?? const <Expense>[],
  ),
);

/// The expense list's filters.  The month comes from `selectedMonthProvider`;
/// these only narrow the rows already loaded for it.
final expenseFiltersProvider =
    NotifierProvider<ExpenseFiltersController, ExpenseFilters>(
      ExpenseFiltersController.new,
    );

class ExpenseFiltersController extends Notifier<ExpenseFilters> {
  @override
  ExpenseFilters build() => const ExpenseFilters();

  void set(ExpenseFilters filters) => state = filters;

  void reset() => state = const ExpenseFilters();
}

/// The filtered rows of the selected month, grouped by day, with their total.
final class FilteredExpenses {
  const FilteredExpenses({
    required this.rows,
    required this.byDay,
    required this.total,
  });

  static const FilteredExpenses empty = FilteredExpenses(
    rows: <Expense>[],
    byDay: <DateKey, List<Expense>>{},
    total: Money.zero,
  );

  final List<Expense> rows;
  final Map<DateKey, List<Expense>> byDay;

  /// Sum of the visible rows; deleted rows (shown only on request) are not
  /// money spent and never count.
  final Money total;
}

final filteredExpensesProvider = Provider.autoDispose<FilteredExpenses>((ref) {
  final month = ref.watch(selectedMonthProvider);
  final filters = ref.watch(expenseFiltersProvider);
  final all = ref.watch(monthExpensesProvider(month)).value;
  if (all == null) return FilteredExpenses.empty;
  final rows = applyFilters(all, filters);
  var total = Money.zero;
  for (final row in rows) {
    if (!row.isDeleted) total += row.total;
  }
  return FilteredExpenses(
    rows: rows,
    byDay: groupExpensesByDay(rows),
    total: total,
  );
});

/// The edit history of one expense (newest first, at most 20).  Only its
/// creator and managers may read it; others get a permission error.
final expenseRevisionsProvider = StreamProvider.autoDispose
    .family<List<ExpenseRevision>, String>((ref, expenseId) {
      final familyId = ref.watch(currentFamilyIdProvider);
      if (familyId == null) return Stream.value(const <ExpenseRevision>[]);
      return ref
          .watch(expenseRepositoryProvider)
          .watchRevisions(familyId, expenseId);
    });

/// May the signed-in user edit or delete [expense]?  "Own" is a data check
/// (`createdBy`), never a role test.
final canEditExpenseProvider = Provider.family<bool, Expense>((ref, expense) {
  final uid = ref.watch(currentUidProvider);
  final own = uid != null && expense.createdBy == uid;
  return ref.can(
    own ? Permission.addOwnExpense : Permission.editOthersExpense,
    ownerId: expense.createdBy,
  );
});

// ── Use cases ─────────────────────────────────────────────────────────────

final addExpenseProvider = Provider<AddExpense>(
  (ref) => AddExpense(
    expenses: ref.watch(expenseRepositoryProvider),
    catalog: ref.watch(catalogRepositoryProvider),
    funds: ref.watch(fundRepositoryProvider),
    advances: ref.watch(advanceRepositoryProvider),
    families: ref.watch(familyRepositoryProvider),
    clock: ref.watch(clockProvider),
    newId: ref.watch(idGeneratorProvider),
    dateKeys: ref.watch(familyDateKeysProvider),
  ),
);

final addBazarTripProvider = Provider<AddBazarTrip>(
  (ref) => AddBazarTrip(
    expenses: ref.watch(expenseRepositoryProvider),
    catalog: ref.watch(catalogRepositoryProvider),
    funds: ref.watch(fundRepositoryProvider),
    advances: ref.watch(advanceRepositoryProvider),
    families: ref.watch(familyRepositoryProvider),
    clock: ref.watch(clockProvider),
    newId: ref.watch(idGeneratorProvider),
    dateKeys: ref.watch(familyDateKeysProvider),
  ),
);

final updateExpenseProvider = Provider<UpdateExpense>(
  (ref) => UpdateExpense(
    expenses: ref.watch(expenseRepositoryProvider),
    funds: ref.watch(fundRepositoryProvider),
    advances: ref.watch(advanceRepositoryProvider),
    families: ref.watch(familyRepositoryProvider),
    clock: ref.watch(clockProvider),
    newId: ref.watch(idGeneratorProvider),
    dateKeys: ref.watch(familyDateKeysProvider),
  ),
);

final softDeleteExpenseProvider = Provider<SoftDeleteExpense>(
  (ref) => SoftDeleteExpense(
    expenses: ref.watch(expenseRepositoryProvider),
    funds: ref.watch(fundRepositoryProvider),
    advances: ref.watch(advanceRepositoryProvider),
    families: ref.watch(familyRepositoryProvider),
    clock: ref.watch(clockProvider),
    newId: ref.watch(idGeneratorProvider),
    dateKeys: ref.watch(familyDateKeysProvider),
  ),
);

final restoreExpenseProvider = Provider<RestoreExpense>(
  (ref) => RestoreExpense(
    expenses: ref.watch(expenseRepositoryProvider),
    funds: ref.watch(fundRepositoryProvider),
    advances: ref.watch(advanceRepositoryProvider),
    families: ref.watch(familyRepositoryProvider),
    clock: ref.watch(clockProvider),
    newId: ref.watch(idGeneratorProvider),
    dateKeys: ref.watch(familyDateKeysProvider),
  ),
);

final checkDuplicateProvider = Provider<CheckDuplicate>(
  (ref) => CheckDuplicate(
    expenses: ref.watch(expenseRepositoryProvider),
    families: ref.watch(familyRepositoryProvider),
    clock: ref.watch(clockProvider),
  ),
);
