import 'package:family_hub/core/firebase/query_limits.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/core/utils/money.dart';
import 'package:family_hub/features/bazar/advances/domain/member_advance.dart';
import 'package:family_hub/features/bazar/advances/presentation/advance_providers.dart';
import 'package:family_hub/features/bazar/expenses/domain/expense.dart';
import 'package:family_hub/features/bazar/expenses/domain/expense_filters.dart';
import 'package:family_hub/features/bazar/expenses/presentation/expense_providers.dart';
import 'package:family_hub/features/bazar/presentation/bazar_providers.dart';
import 'package:family_hub/features/family/presentation/family_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One expense, read once (cache first).  A failed read throws the
/// `AppFailure`, so the screen shows it through `bazarFailureMessage`.
final expenseDetailProvider = FutureProvider.autoDispose
    .family<Expense?, String>((ref, id) async {
      final familyId = ref.watch(currentFamilyIdProvider);
      if (familyId == null) return null;
      final result = await ref
          .watch(expenseRepositoryProvider)
          .getExpense(familyId, id);
      final failure = result.failureOrNull;
      if (failure != null) throw failure;
      return result.valueOrNull;
    });

/// [expenseDetailProvider], kept live by the month listener: an edit, delete or
/// restore shows up without a manual refresh.
final liveExpenseProvider = Provider.autoDispose
    .family<AsyncValue<Expense?>, String>((ref, id) {
      final fetched = ref.watch(expenseDetailProvider(id));
      final expense = fetched.value;
      if (expense == null) return fetched;
      final live = ref.watch(monthExpensesProvider(expense.monthKey)).value;
      for (final row in live ?? const <Expense>[]) {
        if (row.id == id) return AsyncData<Expense?>(row);
      }
      return fetched;
    });

/// The reimbursement record of a member-paid expense (`null` when none).
final expenseAdvanceProvider = FutureProvider.autoDispose
    .family<MemberAdvance?, String>((ref, expenseId) async {
      final familyId = ref.watch(currentFamilyIdProvider);
      if (familyId == null) return null;
      final result = await ref
          .watch(advanceRepositoryProvider)
          .getAdvance(familyId, expenseId);
      final failure = result.failureOrNull;
      if (failure != null) throw failure;
      return result.valueOrNull;
    });

/// Pages of a custom range that reaches outside the selected month.
final class RangePage {
  const RangePage({required this.rows, required this.hasMore});

  final List<Expense> rows;
  final bool hasMore;
}

/// Non-live, paged read of a range (`queryRange` + `startAfter`).  Refreshing
/// is explicit, because a one-off range is not worth a second listener.
final rangeExpensesProvider = AsyncNotifierProvider.autoDispose
    .family<RangeExpensesController, RangePage, DateKeyRange>(
      RangeExpensesController.new,
    );

class RangeExpensesController extends AsyncNotifier<RangePage> {
  RangeExpensesController(this.range);

  final DateKeyRange range;

  @override
  Future<RangePage> build() => _load(null, const <Expense>[]);

  Future<RangePage> _load(Expense? after, List<Expense> before) async {
    final familyId = ref.read(currentFamilyIdProvider);
    if (familyId == null) return const RangePage(rows: <Expense>[], hasMore: false);
    final result = await ref
        .read(expenseRepositoryProvider)
        .queryRange(
          familyId,
          range,
          limit: defaultPageSize,
          startAfter: after,
        );
    final failure = result.failureOrNull;
    if (failure != null) throw failure;
    final page = result.valueOrNull ?? const <Expense>[];
    return RangePage(
      rows: <Expense>[...before, ...page],
      hasMore: page.length >= defaultPageSize,
    );
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore) return;
    state = await AsyncValue.guard(() => _load(current.rows.last, current.rows));
  }

  Future<void> refresh() async {
    state = const AsyncLoading<RangePage>();
    state = await AsyncValue.guard(() => _load(null, const <Expense>[]));
  }
}

/// What the expense list shows now: rows, their total and the load state.
final class ExpenseListData {
  const ExpenseListData({
    required this.rows,
    required this.total,
    this.loading = false,
    this.error,
    this.remote = false,
    this.hasMoreRemote = false,
  });

  final List<Expense> rows;

  /// Sum of the rows; deleted rows never count.
  final Money total;
  final bool loading;
  final Object? error;

  /// `true` for a range outside the selected month (paged, not live).
  final bool remote;
  final bool hasMoreRemote;
}

final expenseListProvider = Provider.autoDispose<ExpenseListData>((ref) {
  final month = ref.watch(selectedMonthProvider);
  final filters = ref.watch(expenseFiltersProvider);
  final range = filters.range;
  final remote =
      range != null &&
      (range.start.monthKey != month || range.end.monthKey != month);

  List<Expense> source;
  var loading = false;
  Object? error;
  var hasMore = false;
  if (range != null && remote) {
    final page = ref.watch(rangeExpensesProvider(range));
    source = page.value?.rows ?? const <Expense>[];
    hasMore = page.value?.hasMore ?? false;
    loading = page.isLoading && !page.hasValue;
    error = page.hasValue ? null : page.error;
  } else {
    final async = ref.watch(monthExpensesProvider(month));
    source = async.value ?? const <Expense>[];
    loading = async.isLoading && !async.hasValue;
    error = async.hasValue ? null : async.error;
  }

  final rows = applyFilters(source, filters);
  var total = Money.zero;
  for (final row in rows) {
    if (!row.isDeleted) total += row.total;
  }
  return ExpenseListData(
    rows: rows,
    total: total,
    loading: loading,
    error: error,
    remote: remote,
    hasMoreRemote: hasMore,
  );
});
