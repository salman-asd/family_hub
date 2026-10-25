import 'package:family_hub/core/firebase/base_mapper.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/core/utils/money.dart';
import 'package:family_hub/core/utils/quantity.dart';
import 'package:family_hub/features/bazar/budgets/domain/budget.dart';

/// Pure functions between [Budget] and `budgets/{yyyy-MM}`.
///
/// Money is integer paisa (`*Paisa`) and quantities integer milli-units
/// (`*Milli`).  The key list written here is mirrored by `budgetKeys()` in the
/// rules and by `test/contract/rules_key_sets_test.dart`.  Reads are tolerant
/// of old or damaged documents, like `relationships.items`: a malformed line is
/// skipped, never a crash.
abstract final class BudgetMappers {
  static Map<String, dynamic> toMap(
    Budget budget,
    BaseDocumentMetadata meta,
  ) => <String, dynamic>{
    'monthKey': budget.month.toString(),
    'totalEstimatePaisa': budget.totalEstimate.paisa,
    'categoryEstimates': <String, int>{
      for (final entry in budget.categoryEstimates.entries)
        entry.key: entry.value.paisa,
    },
    'lines': <Map<String, dynamic>>[
      for (final line in budget.lines) lineToMap(line),
    ],
    'alertThresholds': <int>[...budget.alertThresholds],
    ...BaseMapper.metadataToMap(meta),
  };

  /// Absent optional values are left out (they are optional in the rules too).
  static Map<String, dynamic> lineToMap(BudgetLine line) => <String, dynamic>{
    if (line.itemId != null) 'itemId': line.itemId,
    'name': line.name,
    if (line.plannedQty != null) 'plannedQtyMilli': line.plannedQty!.milli,
    if (line.unit != null) 'unit': line.unit!.name,
    if (line.estimatedRate != null)
      'estimatedRatePaisa': line.estimatedRate!.paisa,
    'estimatedTotalPaisa': line.estimatedTotal.paisa,
    if (line.stock != null) 'stockMilli': line.stock!.milli,
  };

  /// `null` when the document has no readable month (id and field both bad).
  static Budget? fromMap(String docId, Map<String, dynamic> map) {
    final month =
        MonthKey.parse(_string(map['monthKey']) ?? docId).valueOrNull ??
        MonthKey.parse(docId).valueOrNull;
    if (month == null) return null;

    final estimates = <String, Money>{};
    final rawEstimates = map['categoryEstimates'];
    if (rawEstimates is Map) {
      for (final entry in rawEstimates.entries) {
        if (estimates.length == kMaxBudgetCategories) break;
        final paisa = _nonNegativeInt(entry.value);
        if (entry.key is String && paisa != null) {
          estimates[entry.key as String] = Money.paisa(paisa);
        }
      }
    }

    final lines = <BudgetLine>[];
    final rawLines = map['lines'];
    if (rawLines is List) {
      for (final raw in rawLines) {
        if (lines.length == kMaxBudgetLines) break;
        final line = lineFromMap(raw);
        if (line != null) lines.add(line);
      }
    }

    final metadata = BaseMapper.metadataFromMap(map);
    final hasAuthor = metadata.createdBy.isNotEmpty;

    return Budget(
      month: month,
      totalEstimate: Money.paisa(_nonNegativeInt(map['totalEstimatePaisa']) ?? 0),
      categoryEstimates: estimates,
      lines: lines,
      alertThresholds: _thresholds(map['alertThresholds']),
      createdAt: hasAuthor ? metadata.createdAt : null,
      createdBy: hasAuthor ? metadata.createdBy : null,
    );
  }

  /// `null` for anything that is not a map with a name.
  static BudgetLine? lineFromMap(Object? raw) {
    if (raw is! Map) return null;
    final name = _string(raw['name']);
    if (name == null || name.trim().isEmpty) return null;
    final qty = _nonNegativeInt(raw['plannedQtyMilli']);
    final rate = _nonNegativeInt(raw['estimatedRatePaisa']);
    final stock = _nonNegativeInt(raw['stockMilli']);
    return BudgetLine(
      itemId: _string(raw['itemId']),
      name: name,
      plannedQty: qty == null ? null : Quantity.milli(qty),
      unit: _unit(raw['unit']),
      estimatedRate: rate == null ? null : Money.paisa(rate),
      estimatedTotal: Money.paisa(_nonNegativeInt(raw['estimatedTotalPaisa']) ?? 0),
      stock: stock == null ? null : Quantity.milli(stock),
    );
  }

  static String? _string(Object? value) => value is String ? value : null;

  static int? _nonNegativeInt(Object? value) {
    if (value is! num) return null;
    final result = value.toInt();
    return result < 0 ? null : result;
  }

  static Unit? _unit(Object? value) {
    if (value is! String) return null;
    for (final unit in Unit.values) {
      if (unit.name == value) return unit;
    }
    return null;
  }

  static List<int> _thresholds(Object? value) {
    if (value is! List) return kDefaultBudgetThresholds;
    final result = <int>[];
    for (final item in value) {
      if (result.length == 4) break;
      if (item is num) {
        final threshold = item.toInt();
        if (threshold >= 1 && threshold <= 200) result.add(threshold);
      }
    }
    if (result.isEmpty) return kDefaultBudgetThresholds;
    for (var i = 1; i < result.length; i++) {
      if (result[i] <= result[i - 1]) return kDefaultBudgetThresholds;
    }
    return result;
  }
}
