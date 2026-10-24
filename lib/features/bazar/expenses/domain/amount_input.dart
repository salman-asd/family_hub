import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/utils/money.dart';
import 'package:family_hub/core/utils/quantity.dart';

/// What the amount fields of an entry form mean, read once.
///
/// Shared by the Add/Edit expense form and the trip line sheet so both apply
/// the same rule as `computeTotal`: quantity x unit price wins over a typed
/// total, and supplying only one of the pair is an error, never a silent zero.
/// Text is parsed with `Money.parse` / `Quantity.parse` (Bangla digits ok).
final class AmountInput {
  const AmountInput({
    this.qty,
    this.unit,
    this.unitPrice,
    this.typedTotal,
    this.total,
    this.calculated = false,
    this.errors = const <String, String>{},
  });

  final Quantity? qty;
  final Unit? unit;
  final Money? unitPrice;
  final Money? typedTotal;

  /// The amount that will be saved, or `null` while it cannot be known.
  final Money? total;

  /// `true` when [total] came from quantity x unit price.
  final bool calculated;

  /// Field (`qty`, `unit`, `unitPrice`, `total`) -> stable validation code.
  final Map<String, String> errors;

  bool get isValid => errors.isEmpty && total != null;
}

/// Reads the four amount fields.
///
/// [strict] adds the "enter an amount" error for an empty form; the live
/// total shown while typing passes `false` so a half-typed form shows no red.
AmountInput readAmountInput({
  required String qtyText,
  required Unit? unit,
  required String unitPriceText,
  required String totalText,
  bool strict = true,
}) {
  final errors = <String, String>{};

  Quantity? qty;
  if (qtyText.trim().isNotEmpty) {
    final parsed = Quantity.parse(qtyText);
    final failure = parsed.failureOrNull;
    if (failure != null) {
      errors['qty'] = _codeOf(failure);
    } else if (parsed.valueOrNull!.milli <= 0) {
      errors['qty'] = 'amount_not_positive';
    } else {
      qty = parsed.valueOrNull;
    }
  }

  Money? unitPrice;
  if (unitPriceText.trim().isNotEmpty) {
    final parsed = Money.parse(unitPriceText);
    final failure = parsed.failureOrNull;
    if (failure != null) {
      errors['unitPrice'] = _codeOf(failure);
    } else if (parsed.valueOrNull!.paisa <= 0) {
      errors['unitPrice'] = 'amount_not_positive';
    } else {
      unitPrice = parsed.valueOrNull;
    }
  }

  Money? typed;
  if (totalText.trim().isNotEmpty) {
    final parsed = Money.parse(totalText);
    final failure = parsed.failureOrNull;
    if (failure != null) {
      errors['total'] = _codeOf(failure);
    } else if (parsed.valueOrNull!.paisa <= 0) {
      errors['total'] = 'amount_not_positive';
    } else {
      typed = parsed.valueOrNull;
    }
  }

  final hasQtyText = qtyText.trim().isNotEmpty;
  final hasPriceText = unitPriceText.trim().isNotEmpty;
  if (strict && hasQtyText != hasPriceText) {
    errors.putIfAbsent(
      hasQtyText ? 'unitPrice' : 'qty',
      () => 'qty_unit_required',
    );
  }
  if (strict && qty != null && unit == null) {
    errors['unit'] = 'qty_unit_required';
  }

  final Money? total = qty != null && unitPrice != null
      ? lineTotal(qty, unitPrice)
      : typed;
  final calculated = qty != null && unitPrice != null;
  if (strict && total == null && !errors.containsKey('total')) {
    errors['total'] = 'invalid_amount';
  }
  if (calculated && total != null && total.paisa <= 0) {
    // A tiny quantity at a tiny price can round to zero paisa.
    errors['total'] = 'amount_not_positive';
  }

  return AmountInput(
    qty: qty,
    unit: qty == null ? null : unit,
    unitPrice: unitPrice,
    typedTotal: calculated ? null : typed,
    total: total,
    calculated: calculated,
    errors: errors,
  );
}

String _codeOf(AppFailure failure) {
  final code = failure is Validation ? failure.code : 'invalid_amount';
  return switch (code) {
    'negative' => 'negative',
    'too_many_decimals' => 'too_many_decimals',
    'too_large' => 'too_large',
    _ => 'invalid_amount',
  };
}

/// Plain editable text for [value]: `12`, `12.5`, `12.05` (never grouped).
String moneyEditText(Money value) {
  final whole = value.paisa ~/ 100;
  final cents = value.paisa % 100;
  if (cents == 0) return '$whole';
  final text = cents.toString().padLeft(2, '0');
  return '$whole.${text.endsWith('0') ? text.substring(0, 1) : text}';
}
