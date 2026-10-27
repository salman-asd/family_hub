import 'package:family_hub/core/utils/money.dart';

/// This period against the comparable previous one.
final class PeriodComparison {
  const PeriodComparison({
    required this.current,
    required this.previous,
    required this.delta,
    required this.deltaBp,
  });

  /// [current] is the current period's total, [previous] the earlier one.
  factory PeriodComparison.of({
    required Money current,
    required Money previous,
  }) => PeriodComparison(
    current: current,
    previous: previous,
    delta: current - previous,
    // No basis to compare against: report "no change percentage".
    deltaBp: previous.isZero
        ? null
        : halfUpRatioBp(delta: current - previous, base: previous),
  );

  final Money current;
  final Money previous;
  final Money delta;

  /// `delta / previous` in basis points (rounded, the sign is kept); `null`
  /// when the previous period had no spending.
  final int? deltaBp;

  /// `true` when this period spent more than the previous one.
  bool get isUp => delta.paisa > 0;

  bool get isFlat => delta.isZero;

  @override
  bool operator ==(Object other) =>
      other is PeriodComparison &&
      other.current == current &&
      other.previous == previous &&
      other.delta == delta &&
      other.deltaBp == deltaBp;

  @override
  int get hashCode => Object.hash(current, previous, delta, deltaBp);

  @override
  String toString() =>
      'PeriodComparison($current vs $previous, delta: $delta, $deltaBp bp)';
}

/// `delta / base` in basis points, rounded half-away-from-zero.
///
/// `base` must not be zero; callers show "—" instead (the value is unknowable).
int halfUpRatioBp({required Money delta, required Money base}) {
  assert(base.paisa != 0, 'a ratio needs a non-zero base');
  final numerator = delta.paisa * 20000;
  final denominator = base.paisa;
  final magnitude = (numerator.abs() + denominator.abs() ~/ 2) ~/ denominator.abs();
  return numerator.isNegative ? -magnitude : magnitude;
}
