import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/core/utils/money.dart';
import 'package:family_hub/core/utils/quantity.dart';

/// The one money rule shared by the add/edit/trip forms.
///
/// Quantity + unit price wins over a typed total.  Supplying only one of the
/// two is a validation error, never a silent zero.
Result<Money> computeTotal({
  Quantity? qty,
  Money? unitPrice,
  Money? typedTotal,
}) {
  if (qty != null && unitPrice != null) {
    return _positive(lineTotal(qty, unitPrice), 'total');
  }
  if (qty != null || unitPrice != null) {
    return Failure<Money>(
      Validation(qty != null ? 'unitPrice' : 'qty', 'qty_unit_required'),
    );
  }
  return _positive(typedTotal ?? Money.zero, 'total');
}

Result<Money> _positive(Money amount, String field) => amount.paisa > 0
    ? Success<Money>(amount)
    : Failure<Money>(Validation(field, 'amount_not_positive'));
