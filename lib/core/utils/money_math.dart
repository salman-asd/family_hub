import 'package:family_hub/core/utils/money.dart';
import 'package:family_hub/core/utils/quantity.dart';

/// [part] expressed in basis points of [whole] (1 bp = 1/100 of a percent).
///
/// Rounded half-up; ties for negative amounts go away from zero, mirroring
/// [lineTotal]. Returns `null` when [whole] is zero or negative, because a
/// ratio to a non-positive total is undefined (the UI shows "—").
int? basisPoints(Money part, Money whole) {
  if (whole.paisa <= 0) return null;
  final product = part.paisa * 10000;
  final negative = product < 0;
  final absolute = negative ? -product : product;
  // floor((2n + d) / 2d) == round-half-up(n / d) for positive integers.
  final rounded = (absolute * 2 + whole.paisa) ~/ (whole.paisa * 2);
  return negative ? -rounded : rounded;
}

/// Splits [total] into [parts] shares that differ by at most one paisa.
///
/// The remainder paisa go one each to the first `total.paisa % parts` shares,
/// so the sum always equals [total]. [total] must not be negative and [parts]
/// must be positive.
List<Money> splitEqually(Money total, int parts) {
  assert(parts > 0, 'parts must be > 0');
  assert(!total.isNegative, 'total must be >= 0');
  final base = total.paisa ~/ parts;
  final remainder = total.paisa % parts;
  return <Money>[
    for (var i = 0; i < parts; i++) Money.paisa(base + (i < remainder ? 1 : 0)),
  ];
}

/// The larger of [a] and [b].
Money maxMoney(Money a, Money b) => a >= b ? a : b;

/// The smaller of [a] and [b].
Money minMoney(Money a, Money b) => a <= b ? a : b;

/// `quantity x unitPrice`, or `null` unless both are present.
///
/// `null` is the "not enough input yet" state, distinct from a zero total.
Money? tryLineTotal(Quantity? quantity, Money? unitPrice) {
  if (quantity == null || unitPrice == null) return null;
  return lineTotal(quantity, unitPrice);
}
