import 'package:family_hub/core/utils/clock_provider.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/features/bazar/budgets/domain/budget.dart';
import 'package:family_hub/features/bazar/budgets/domain/budget_alert.dart';
import 'package:family_hub/features/bazar/budgets/domain/budget_repository.dart';
import 'package:family_hub/features/bazar/budgets/domain/budget_status.dart';
import 'package:family_hub/features/bazar/budgets/domain/usecases/copy_last_month_budget.dart';
import 'package:family_hub/features/bazar/budgets/domain/usecases/save_budget.dart';
import 'package:family_hub/features/bazar/expenses/presentation/expense_providers.dart';
import 'package:family_hub/features/bazar/settings/presentation/bazar_settings_providers.dart';
import 'package:family_hub/features/family/presentation/family_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Overridden in `bootstrap.dart` and in tests.
final budgetRepositoryProvider = Provider<BudgetRepository>(
  (ref) => throw UnimplementedError(
    'budgetRepositoryProvider must be overridden (bootstrap.dart / tests).',
  ),
);

/// One live listener per month's budget document; `null` = no budget saved.
final monthBudgetProvider = StreamProvider.autoDispose
    .family<Budget?, MonthKey>((ref, month) {
      final familyId = ref.watch(currentFamilyIdProvider);
      if (familyId == null) return Stream.value(null);
      return ref.watch(budgetRepositoryProvider).watchBudget(familyId, month);
    });

/// Plan vs spend for [month].  Spend comes from `monthSpendProvider` (the same
/// listener as the expense list), so adding an expense moves the bars at once.
/// The family's alert levels (`settings/bazar`) decide warning/exceeded; the
/// copy stored in the budget is only a snapshot.
final budgetStatusProvider = Provider.autoDispose
    .family<BudgetStatusReport, MonthKey>((ref, month) {
      final budget = ref.watch(monthBudgetProvider(month)).value;
      final spend = ref.watch(monthSpendProvider(month));
      final thresholds = ref.watch(bazarSettingsProvider).alertThresholds;
      return ComputeBudgetStatus.call(budget, spend, thresholds: thresholds);
    });

/// Warning / exceeded limits of the CURRENT month, worst first.  Read by the
/// dashboard card (P2-29).  Alerts never block an expense: the Add Expense form
/// does not read this.
final budgetAlertsProvider = Provider.autoDispose<List<BudgetAlert>>((ref) {
  final month = ref.watch(familyDateKeysProvider).thisMonth();
  return buildBudgetAlerts(ref.watch(budgetStatusProvider(month)));
});

final saveBudgetProvider = Provider<SaveBudget>(
  (ref) => SaveBudget(
    budgets: ref.watch(budgetRepositoryProvider),
    families: ref.watch(familyRepositoryProvider),
    clock: ref.watch(clockProvider),
    newId: ref.watch(idGeneratorProvider),
  ),
);

final copyLastMonthBudgetProvider = Provider<CopyLastMonthBudget>(
  (ref) => CopyLastMonthBudget(
    budgets: ref.watch(budgetRepositoryProvider),
    families: ref.watch(familyRepositoryProvider),
    clock: ref.watch(clockProvider),
    newId: ref.watch(idGeneratorProvider),
  ),
);
