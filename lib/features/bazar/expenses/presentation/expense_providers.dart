import 'package:family_hub/core/permissions/permissions.dart';
import 'package:family_hub/core/utils/clock_provider.dart';
import 'package:family_hub/core/utils/date_key.dart';
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

/// One month of expenses, newest first, capped by `kMaxListenerDocs`.
///
/// Auto-disposed with the screen that watches it; the current month is kept
/// warm so switching tabs (list → fund → back) does not re-read the same month.
final monthExpensesProvider = StreamProvider.autoDispose
    .family<List<Expense>, MonthKey>((ref, month) {
      final familyId = ref.watch(currentFamilyIdProvider);
      if (familyId == null) return Stream.value(const <Expense>[]);
      if (month == ref.watch(familyDateKeysProvider).thisMonth()) {
        ref.keepAlive();
      }
      return ref.watch(expenseRepositoryProvider).watchMonth(familyId, month);
    });

/// Totals for one month (soft-deleted rows already excluded by [MonthSpend]).
final monthSpendProvider = Provider.autoDispose.family<MonthSpend, MonthKey>(
  (ref, month) => MonthSpend.of(
    ref.watch(monthExpensesProvider(month)).value ?? const <Expense>[],
  ),
);

/// The list filters; a screen sets them, every list/derived view reads them.
final expenseFiltersProvider =
    NotifierProvider<ExpenseFiltersController, ExpenseFilters>(
      ExpenseFiltersController.new,
    );

/// [expenseFiltersProvider]'s state, reset to "everything" on `clear()`.
class ExpenseFiltersController extends Notifier<ExpenseFilters> {
  @override
  ExpenseFilters build() => const ExpenseFilters();

  void set(ExpenseFilters filters) => state = filters;

  void clear() => state = const ExpenseFilters();
}

/// The selected month's rows after the client-side filters, in query order.
final filteredExpensesProvider = Provider.autoDispose<List<Expense>>((ref) {
  final month = ref.watch(selectedMonthProvider);
  final expenses =
      ref.watch(monthExpensesProvider(month)).value ?? const <Expense>[];
  return ref.watch(expenseFiltersProvider).apply(expenses);
});

/// One expense's append-only edit history (newest 20), for the detail screen.
final expenseRevisionsProvider = StreamProvider.autoDispose
    .family<List<ExpenseRevision>, String>((ref, expenseId) {
      final familyId = ref.watch(currentFamilyIdProvider);
      if (familyId == null) return Stream.value(const <ExpenseRevision>[]);
      return ref
          .watch(expenseRepositoryProvider)
          .watchRevisions(familyId, expenseId);
    });

/// Whether the signed-in user may edit [expense]: own rows need
/// `addOwnExpense`, somebody else's need `editOthersExpense`.  Never a role test.
final canEditExpenseProvider = Provider.family<bool, Expense>((ref, expense) {
  final own = expense.createdBy == ref.watch(currentUidProvider);
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
