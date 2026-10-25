import 'package:family_hub/core/utils/money.dart';
import 'package:family_hub/core/utils/quantity.dart';
import 'package:family_hub/features/bazar/budgets/domain/budget.dart';
import 'package:family_hub/features/bazar/expenses/domain/amount_input.dart';

/// One editable row of the dry-grocery table, still as the text the person
/// typed.  Text is turned into values only by [readLineDrafts]; a widget never
/// parses.
final class BudgetLineDraft {
  const BudgetLineDraft({
    required this.id,
    this.itemId,
    this.name = '',
    this.qtyText = '',
    this.unit,
    this.rateText = '',
    this.totalText = '',
    this.stockText = '',
  });

  /// Local row id (stable while editing; never stored).
  final String id;
  final String? itemId;
  final String name;
  final String qtyText;
  final Unit? unit;
  final String rateText;
  final String totalText;
  final String stockText;

  bool get isBlank =>
      name.trim().isEmpty &&
      qtyText.trim().isEmpty &&
      rateText.trim().isEmpty &&
      totalText.trim().isEmpty &&
      stockText.trim().isEmpty;

  BudgetLineDraft copyWith({
    String? name,
    String? qtyText,
    Unit? unit,
    String? rateText,
    String? totalText,
    String? stockText,
  }) => BudgetLineDraft(
    id: id,
    itemId: itemId,
    name: name ?? this.name,
    qtyText: qtyText ?? this.qtyText,
    unit: unit ?? this.unit,
    rateText: rateText ?? this.rateText,
    totalText: totalText ?? this.totalText,
    stockText: stockText ?? this.stockText,
  );

  /// The draft of an existing line.
  static BudgetLineDraft fromLine(String id, BudgetLine line) => BudgetLineDraft(
    id: id,
    itemId: line.itemId,
    name: line.name,
    qtyText: line.plannedQty?.toDecimalString() ?? '',
    unit: line.unit,
    rateText: line.estimatedRate == null
        ? ''
        : moneyEditText(line.estimatedRate!),
    totalText: line.plannedQty != null && line.estimatedRate != null
        ? ''
        : moneyEditText(line.estimatedTotal),
    stockText: line.stock?.toDecimalString() ?? '',
  );
}

/// The lines that can be saved plus, per row id, `field -> stable code`.
final class BudgetLinesRead {
  const BudgetLinesRead({required this.lines, required this.errors});

  final List<BudgetLine> lines;

  /// `rowId -> {name|qty|unit|unitPrice|total|stock -> code}`.
  final Map<String, Map<String, String>> errors;

  bool get isValid => errors.isEmpty;
}

/// Reads every non-blank row with the same amount rule as an expense:
/// quantity x rate wins over a typed total, a lone quantity or rate is an
/// error.  A row with an amount but no name, or a name but no amount, is an
/// error; a completely empty row is ignored.
BudgetLinesRead readLineDrafts(List<BudgetLineDraft> drafts) {
  final lines = <BudgetLine>[];
  final errors = <String, Map<String, String>>{};

  for (final draft in drafts) {
    if (draft.isBlank) continue;
    final rowErrors = <String, String>{};
    final input = readAmountInput(
      qtyText: draft.qtyText,
      unit: draft.unit,
      unitPriceText: draft.rateText,
      totalText: draft.totalText,
    );
    rowErrors.addAll(input.errors);
    if (draft.name.trim().isEmpty) rowErrors['name'] = 'required';

    Quantity? stock;
    if (draft.stockText.trim().isNotEmpty) {
      final parsed = Quantity.parse(draft.stockText);
      if (parsed.failureOrNull != null) {
        rowErrors['stock'] = 'invalid_amount';
      } else {
        stock = parsed.valueOrNull;
      }
    }

    final total = input.total;
    if (rowErrors.isNotEmpty || total == null) {
      errors[draft.id] = rowErrors.isEmpty
          ? <String, String>{'total': 'invalid_amount'}
          : rowErrors;
      continue;
    }
    lines.add(
      BudgetLine(
        itemId: draft.itemId,
        name: draft.name.trim(),
        plannedQty: input.qty,
        unit: input.unit,
        estimatedRate: input.unitPrice,
        estimatedTotal: total,
        stock: stock,
      ),
    );
  }
  return BudgetLinesRead(lines: lines, errors: errors);
}

/// Per-category estimate text -> money.  Blank or zero means "no estimate".
final class CategoryEstimatesRead {
  const CategoryEstimatesRead({required this.estimates, required this.errors});

  final Map<String, Money> estimates;

  /// `categoryId -> code`.
  final Map<String, String> errors;

  bool get isValid => errors.isEmpty;
}

CategoryEstimatesRead readCategoryTexts(Map<String, String> texts) {
  final estimates = <String, Money>{};
  final errors = <String, String>{};
  for (final entry in texts.entries) {
    final text = entry.value.trim();
    if (text.isEmpty) continue;
    final parsed = Money.parse(text);
    final value = parsed.valueOrNull;
    if (value == null) {
      errors[entry.key] = 'invalid_amount';
    } else if (!value.isZero) {
      estimates[entry.key] = value;
    }
  }
  return CategoryEstimatesRead(estimates: estimates, errors: errors);
}

/// Total text -> money.  Blank is zero ("use the sum"); anything unreadable is
/// `null`.
Money? readTotalText(String text) {
  if (text.trim().isEmpty) return Money.zero;
  return Money.parse(text).valueOrNull;
}
