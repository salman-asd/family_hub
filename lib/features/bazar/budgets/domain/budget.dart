import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/core/utils/money.dart';
import 'package:family_hub/core/utils/quantity.dart';

/// Id of the seeded "Dry groceries" category (`cat_<seedKey>`).  When a budget
/// has estimate lines, this category's estimate is their sum.
const String kDryGroceriesCategoryId = 'cat_dry_groceries';

/// Size bounds mirrored by `budgetOk` in `firestore.rules`.
const int kMaxBudgetLines = 150;
const int kMaxBudgetCategories = 40;
const int kMaxBudgetLineName = 80;

/// Warn at 80 %, exceeded at 100 % until the family changes it.
const List<int> kDefaultBudgetThresholds = <int>[80, 100];

/// One planned purchase in the monthly estimate (a dry-grocery line).
///
/// A line either has a planned quantity and a rate (the estimate is their
/// product, rounded half-up to the paisa) or just a typed total.
final class BudgetLine {
  const BudgetLine({
    required this.name,
    required this.estimatedTotal,
    this.itemId,
    this.plannedQty,
    this.unit,
    this.estimatedRate,
    this.stock,
  });

  final String? itemId;
  final String name;
  final Quantity? plannedQty;
  final Unit? unit;
  final Money? estimatedRate;
  final Money estimatedTotal;

  /// What is already in the house (informational, never counted).
  final Quantity? stock;

  /// `quantity x rate` when both exist, otherwise the typed total.
  Money get estimate {
    final qty = plannedQty;
    final rate = estimatedRate;
    if (qty != null && rate != null) return lineTotal(qty, rate);
    return estimatedTotal;
  }

  BudgetLine copyWith({
    String? itemId,
    String? name,
    Quantity? plannedQty,
    Unit? unit,
    Money? estimatedRate,
    Money? estimatedTotal,
    Quantity? stock,
    bool clearStock = false,
  }) => BudgetLine(
    itemId: itemId ?? this.itemId,
    name: name ?? this.name,
    plannedQty: plannedQty ?? this.plannedQty,
    unit: unit ?? this.unit,
    estimatedRate: estimatedRate ?? this.estimatedRate,
    estimatedTotal: estimatedTotal ?? this.estimatedTotal,
    stock: clearStock ? null : (stock ?? this.stock),
  );

  @override
  bool operator ==(Object other) =>
      other is BudgetLine &&
      other.itemId == itemId &&
      other.name == name &&
      other.plannedQty == plannedQty &&
      other.unit == unit &&
      other.estimatedRate == estimatedRate &&
      other.estimatedTotal == estimatedTotal &&
      other.stock == stock;

  @override
  int get hashCode => Object.hash(
    itemId,
    name,
    plannedQty,
    unit,
    estimatedRate,
    estimatedTotal,
    stock,
  );

  @override
  String toString() => 'BudgetLine($name, $estimatedTotal)';
}

/// The plan for one month (`budgets/{yyyy-MM}`).
///
/// A budget is a plan: it never blocks spending and never changes the fund
/// balance.  [createdAt]/[createdBy] are carried so a re-save keeps the
/// original author without reading the document first (so the save can queue
/// offline); they are metadata and not part of equality.
final class Budget {
  Budget({
    required this.month,
    required this.totalEstimate,
    Map<String, Money> categoryEstimates = const <String, Money>{},
    List<BudgetLine> lines = const <BudgetLine>[],
    List<int> alertThresholds = kDefaultBudgetThresholds,
    this.createdAt,
    this.createdBy,
  }) : categoryEstimates = Map<String, Money>.unmodifiable(categoryEstimates),
       lines = List<BudgetLine>.unmodifiable(lines),
       alertThresholds = List<int>.unmodifiable(alertThresholds);

  final MonthKey month;
  final Money totalEstimate;

  /// `categoryId -> planned spend`.
  final Map<String, Money> categoryEstimates;

  /// The dry-grocery estimate table.
  final List<BudgetLine> lines;

  /// Percent breakpoints saved with the plan (ascending).
  final List<int> alertThresholds;

  final DateTime? createdAt;
  final String? createdBy;

  /// `quantity x rate` when both exist, otherwise the typed total.
  static Money lineEstimate(BudgetLine line) => line.estimate;

  /// Sum of every line's estimate.
  Money get linesTotal => Money.sum(lines.map(lineEstimate));

  /// Sum of the per-category estimates.
  Money get categoriesTotal => Money.sum(categoryEstimates.values);

  Budget copyWith({
    Money? totalEstimate,
    Map<String, Money>? categoryEstimates,
    List<BudgetLine>? lines,
    List<int>? alertThresholds,
    MonthKey? month,
    DateTime? createdAt,
    String? createdBy,
  }) => Budget(
    month: month ?? this.month,
    totalEstimate: totalEstimate ?? this.totalEstimate,
    categoryEstimates: categoryEstimates ?? this.categoryEstimates,
    lines: lines ?? this.lines,
    alertThresholds: alertThresholds ?? this.alertThresholds,
    createdAt: createdAt ?? this.createdAt,
    createdBy: createdBy ?? this.createdBy,
  );

  @override
  bool operator ==(Object other) =>
      other is Budget &&
      other.month == month &&
      other.totalEstimate == totalEstimate &&
      _sameMap(other.categoryEstimates, categoryEstimates) &&
      _sameList(other.lines, lines) &&
      _sameList(other.alertThresholds, alertThresholds);

  @override
  int get hashCode => Object.hash(
    month,
    totalEstimate,
    Object.hashAll(
      categoryEstimates.entries.map((e) => Object.hash(e.key, e.value)),
    ),
    Object.hashAll(lines),
    Object.hashAll(alertThresholds),
  );

  @override
  String toString() => 'Budget($month, $totalEstimate, ${lines.length} lines)';
}

bool _sameMap(Map<String, Money> a, Map<String, Money> b) {
  if (a.length != b.length) return false;
  for (final entry in a.entries) {
    if (b[entry.key] != entry.value) return false;
  }
  return true;
}

bool _sameList<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
