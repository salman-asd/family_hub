import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/core/utils/date_ranges.dart';
import 'package:family_hub/features/bazar/budgets/presentation/budget_providers.dart';
import 'package:family_hub/features/bazar/expenses/domain/expense.dart';
import 'package:family_hub/features/bazar/expenses/presentation/expense_providers.dart';
import 'package:family_hub/features/bazar/presentation/bazar_providers.dart';
import 'package:family_hub/features/bazar/reports/domain/report_data.dart';
import 'package:family_hub/features/bazar/reports/domain/report_engine.dart';
import 'package:family_hub/features/bazar/reports/domain/report_loader.dart';
import 'package:family_hub/features/bazar/reports/domain/report_query.dart';
import 'package:family_hub/features/bazar/settings/presentation/bazar_settings_providers.dart';
import 'package:family_hub/features/family/presentation/family_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The selected report period and filters (`preset` + resolved range).
///
/// The range is resolved HERE, against the injected clock and the family week
/// start, so a week range follows `settings/bazar.weekStartDay` immediately
/// (D-P2-12) and the engine itself stays clock-free.
final reportQueryProvider =
    NotifierProvider<ReportQueryController, ReportQuery>(
      ReportQueryController.new,
    );

class ReportQueryController extends Notifier<ReportQuery> {
  @override
  ReportQuery build() => _resolve(RangePreset.thisMonth);

  /// `weekStartDay` is watched, so changing it re-resolves "This week".
  ReportQuery _resolve(
    RangePreset preset, {
    DateKeyRange? custom,
    String? categoryId,
    String? memberId,
  }) => ReportQuery(
    preset: preset,
    range: resolveRange(
      preset,
      today: ref.read(currentDateKeyProvider),
      weekStartDay: ref.watch(bazarSettingsProvider).weekStartDay,
      custom: custom,
    ),
    categoryId: categoryId ?? state.categoryId,
    itemId: state.itemId,
    memberId: memberId ?? state.memberId,
    funding: state.funding,
  );

  void setPreset(RangePreset preset, {DateKeyRange? custom}) {
    assert(preset != RangePreset.custom || custom != null);
    state = _resolve(preset, custom: custom);
  }

  void setCategory(String? categoryId) => state = ReportQuery(
    preset: state.preset,
    range: state.range,
    categoryId: categoryId,
    itemId: state.itemId,
    memberId: state.memberId,
    funding: state.funding,
  );

  void setMember(String? memberId) => state = ReportQuery(
    preset: state.preset,
    range: state.range,
    categoryId: state.categoryId,
    itemId: state.itemId,
    memberId: memberId,
    funding: state.funding,
  );

  void resetFilters() => state = ReportQuery(
    preset: state.preset,
    range: state.range,
    categoryId: null,
    itemId: null,
    memberId: null,
    funding: null,
  );
}

/// The rows of [range], and whether the report cap cut them off.
///
/// A range inside ONE month reuses the live `monthExpensesProvider` (zero extra
/// reads, and it updates when an expense is added); anything else goes through
/// the bounded `loadRange` pager.
final reportRowsProvider = FutureProvider.autoDispose
    .family<ReportLoad, DateKeyRange>((ref, range) async {
      final familyId = ref.watch(currentFamilyIdProvider);
      if (familyId == null) {
        return ReportLoad(expenses: const <Expense>[], truncated: false);
      }
      final month = _singleMonth(range);
      if (month != null) {
        final rows = await ref.watch(monthExpensesProvider(month).future);
        return ReportLoad(expenses: rows, truncated: false);
      }
      final query = ReportQuery(preset: RangePreset.custom, range: range);
      final result = await loadRange(
        ref.watch(expenseRepositoryProvider),
        familyId,
        query,
      );
      final failure = result.failureOrNull;
      if (failure != null) throw failure;
      return result.valueOrNull!;
    });

/// The engine output for the current query, with its comparison.
final reportDataProvider = FutureProvider.autoDispose<ReportData>((ref) async {
  final query = ref.watch(reportQueryProvider);
  final range = query.resolvedRange;
  final previousRange = previousComparable(range);

  final current = await ref.watch(reportRowsProvider(range).future);
  final previous = await ref.watch(reportRowsProvider(previousRange).future);

  final budgetMonth = _singleMonth(range);
  final budget = budgetMonth == null
      ? null
      : ref.watch(monthBudgetProvider(budgetMonth)).value;

  final data = ReportEngine.build(
    expenses: current.expenses,
    query: query,
    budget: budget,
  );
  return ReportEngine.withComparison(data, previousExpenses: previous.expenses);
});

/// `true` when the loaded rows hit the report cap.
final reportTruncatedProvider = Provider.autoDispose<bool>((ref) {
  final query = ref.watch(reportQueryProvider);
  return ref.watch(reportRowsProvider(query.resolvedRange)).value?.truncated ??
      false;
});

/// The month a range lies inside, or `null` when it spans more than one month
/// (or part of two): only then is the live month listener a correct answer.
MonthKey? _singleMonth(DateKeyRange range) {
  final startMonth = range.start.monthKey;
  final endMonth = range.end.monthKey;
  if (startMonth != endMonth) return null;
  final wholeMonth = range.start.day == 1 &&
      range.end.day == startMonth.daysInMonth;
  return wholeMonth ? startMonth : null;
}
