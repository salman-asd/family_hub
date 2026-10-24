import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/core/utils/money.dart';
import 'package:family_hub/core/utils/scaled_decimal.dart';

/// Unit a bazar item is bought in.
enum Unit { kg, g, litre, piece, dozen, packet, cylinder }

/// A non-negative amount stored as integer milli-units (2.5 kg = 2500).
final class Quantity implements Comparable<Quantity> {
  const Quantity.milli(this.milli) : assert(milli >= 0, 'milli must be >= 0');

  static const Quantity zero = Quantity.milli(0);

  final int milli;

  /// Parses '2.5', '২.৫', '1,000'. At most 3 decimal places; negative values
  /// are rejected with code `negative`.
  static Result<Quantity> parse(String input) => parseScaledDecimal(
    input,
    scale: 3,
    field: 'quantity',
    allowNegative: false,
  ).map(Quantity.milli);

  bool get isZero => milli == 0;

  Quantity operator +(Quantity other) => Quantity.milli(milli + other.milli);

  bool operator <(Quantity other) => milli < other.milli;

  bool operator >(Quantity other) => milli > other.milli;

  /// Plain decimal text without trailing zeros: 2500 -> '2.5', 2000 -> '2'.
  String toDecimalString() {
    final whole = milli ~/ 1000;
    final fraction = (milli % 1000)
        .toString()
        .padLeft(3, '0')
        .replaceFirst(RegExp(r'0+$'), '');
    return fraction.isEmpty ? '$whole' : '$whole.$fraction';
  }

  @override
  int compareTo(Quantity other) => milli.compareTo(other.milli);

  @override
  bool operator ==(Object other) => other is Quantity && other.milli == milli;

  @override
  int get hashCode => milli.hashCode;

  @override
  String toString() => 'Quantity($milli milli)';
}

/// Line total = quantity x unit price, in integer arithmetic.
///
/// Rounding rule (explicit, half-up): the exact result in paisa is
/// `milli * unitPricePaisa / 1000`. A remainder of 500 or more (half a paisa
/// or more) rounds up, anything less rounds down. Ties go away from zero for
/// negative amounts, so the result is symmetric around zero.
Money lineTotal(Quantity quantity, Money unitPrice) {
  final product = quantity.milli * unitPrice.paisa;
  final negative = product < 0;
  final absolute = negative ? -product : product;
  final rounded = (absolute + 500) ~/ 1000;
  return Money.paisa(negative ? -rounded : rounded);
}
