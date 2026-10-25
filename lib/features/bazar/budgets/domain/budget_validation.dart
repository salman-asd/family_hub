import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/core/utils/money.dart';
import 'package:family_hub/core/utils/quantity.dart';
import 'package:family_hub/features/bazar/budgets/domain/budget.dart';

/// Checks a budget and returns the version that is saved:
///
/// * line names are trimmed; a line with a quantity and a rate gets
///   `estimatedTotal = quantity x rate`, so the stored total can never disagree
///   with its parts;
/// * when there are lines, the Dry-groceries estimate IS their sum (one source
///   of truth), overriding any typed value;
/// * a zero total defaults to the sum of the category estimates.
///
/// Failure codes are the stable ones of roadmap 3.6.
Result<Budget> prepareBudget(Budget budget) {
  final lines = <BudgetLine>[
    for (final line in budget.lines) _normalizedLine(line),
  ];

  if (lines.length > kMaxBudgetLines) {
    return const Failure<Budget>(Validation('lines', 'too_many_lines'));
  }
  for (final line in lines) {
    final failure = _lineFailure(line);
    if (failure != null) return Failure<Budget>(failure);
  }

  if (budget.totalEstimate.isNegative) {
    return const Failure<Budget>(Validation('totalEstimate', 'negative'));
  }
  for (final entry in budget.categoryEstimates.entries) {
    if (entry.key.trim().isEmpty) {
      return const Failure<Budget>(Validation('categoryEstimates', 'required'));
    }
    if (entry.value.isNegative) {
      return const Failure<Budget>(Validation('categoryEstimates', 'negative'));
    }
  }

  final thresholdFailure = validateAlertThresholds(budget.alertThresholds);
  if (thresholdFailure != null) return Failure<Budget>(thresholdFailure);

  final estimates = <String, Money>{...budget.categoryEstimates};
  if (lines.isNotEmpty) {
    estimates[kDryGroceriesCategoryId] = Money.sum(
      lines.map(Budget.lineEstimate),
    );
  }
  if (estimates.length > kMaxBudgetCategories) {
    return const Failure<Budget>(Validation('categoryEstimates', 'too_large'));
  }

  final total = budget.totalEstimate.isZero
      ? Money.sum(estimates.values)
      : budget.totalEstimate;

  return Success<Budget>(
    budget.copyWith(
      totalEstimate: total,
      categoryEstimates: estimates,
      lines: lines,
    ),
  );
}

/// 1..4 integers in 1..200, strictly ascending.
AppFailure? validateAlertThresholds(List<int> thresholds) {
  if (thresholds.isEmpty) return const Validation('alertThresholds', 'empty');
  if (thresholds.length > 4) {
    return const Validation('alertThresholds', 'too_many');
  }
  var previous = 0;
  for (final value in thresholds) {
    if (value < 1 || value > 200) {
      return const Validation('alertThresholds', 'out_of_range');
    }
    if (value == previous) {
      return const Validation('alertThresholds', 'duplicate');
    }
    if (value < previous) {
      return const Validation('alertThresholds', 'not_ascending');
    }
    previous = value;
  }
  return null;
}

BudgetLine _normalizedLine(BudgetLine line) {
  final qty = line.plannedQty;
  final rate = line.estimatedRate;
  final calculated = qty != null && rate != null
      ? lineTotal(qty, rate)
      : line.estimatedTotal;
  return BudgetLine(
    itemId: line.itemId,
    name: line.name.trim(),
    plannedQty: qty,
    unit: line.unit,
    estimatedRate: rate,
    estimatedTotal: calculated,
    stock: line.stock,
  );
}

AppFailure? _lineFailure(BudgetLine line) {
  if (line.name.isEmpty) return const Validation('lines', 'required');
  if (line.name.runes.length > kMaxBudgetLineName) {
    return const Validation('lines', 'too_long');
  }
  if (line.estimatedTotal.isNegative) {
    return const Validation('lines', 'negative');
  }
  final rate = line.estimatedRate;
  if (rate != null && rate.isNegative) {
    return const Validation('lines', 'negative');
  }
  return null;
}
