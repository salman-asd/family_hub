import 'package:family_hub/features/bazar/budgets/domain/budget_status.dart';

/// One line of the "budget alerts" strip: the whole month ([categoryId] null)
/// or a single category that is at or over a breakpoint.
final class BudgetAlert {
  const BudgetAlert({required this.categoryId, required this.status});

  final String? categoryId;
  final CategoryBudgetStatus status;

  bool get isTotal => categoryId == null;

  @override
  bool operator ==(Object other) =>
      other is BudgetAlert &&
      other.categoryId == categoryId &&
      other.status == status;

  @override
  int get hashCode => Object.hash(categoryId, status);
}

/// Every warning/exceeded limit, worst first: exceeded before warning, then the
/// larger share, the month total before a category on a tie, then category id
/// so the order is stable.
List<BudgetAlert> buildBudgetAlerts(BudgetStatusReport report) {
  final alerts = <BudgetAlert>[
    if (report.total.isAlert)
      BudgetAlert(categoryId: null, status: report.total),
    for (final entry in report.byCategory.entries)
      if (entry.value.isAlert)
        BudgetAlert(categoryId: entry.key, status: entry.value),
  ];
  alerts.sort((a, b) {
    final level = _rank(b.status.level).compareTo(_rank(a.status.level));
    if (level != 0) return level;
    final percent = (b.status.percentBp ?? 0).compareTo(
      a.status.percentBp ?? 0,
    );
    if (percent != 0) return percent;
    if (a.isTotal != b.isTotal) return a.isTotal ? -1 : 1;
    return (a.categoryId ?? '').compareTo(b.categoryId ?? '');
  });
  return alerts;
}

int _rank(BudgetLevel level) => switch (level) {
  BudgetLevel.exceeded => 2,
  BudgetLevel.warning => 1,
  BudgetLevel.ok || BudgetLevel.noLimit => 0,
};
