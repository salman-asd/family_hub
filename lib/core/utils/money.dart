import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/core/utils/bangla_numerals.dart';
import 'package:family_hub/core/utils/scaled_decimal.dart';

/// An amount of taka stored as integer paisa (1 taka = 100 paisa).
final class Money implements Comparable<Money> {
  const Money.paisa(this.paisa);

  static const Money zero = Money.paisa(0);

  final int paisa;

  /// Parses '৳১,২৫০.৫০', '12.5', '১২' and similar. Never goes through a
  /// floating point type. More than 2 decimal places is a Validation failure
  /// with code `too_many_decimals`.
  static Result<Money> parse(String input) => parseScaledDecimal(
    input.replaceAll('৳', ''),
    scale: 2,
    field: 'money',
  ).map(Money.paisa);

  /// Sum of [items]; [zero] for an empty collection.
  static Money sum(Iterable<Money> items) =>
      items.fold<Money>(zero, (total, m) => total + m);

  bool get isNegative => paisa < 0;

  bool get isZero => paisa == 0;

  Money operator +(Money other) => Money.paisa(paisa + other.paisa);

  Money operator -(Money other) => Money.paisa(paisa - other.paisa);

  Money operator -() => Money.paisa(-paisa);

  Money operator *(int factor) => Money.paisa(paisa * factor);

  bool operator <(Money other) => paisa < other.paisa;

  bool operator <=(Money other) => paisa <= other.paisa;

  bool operator >(Money other) => paisa > other.paisa;

  bool operator >=(Money other) => paisa >= other.paisa;

  @override
  int compareTo(Money other) => paisa.compareTo(other.paisa);

  @override
  bool operator ==(Object other) => other is Money && other.paisa == paisa;

  @override
  int get hashCode => paisa.hashCode;

  @override
  String toString() => 'Money($paisa paisa)';
}

/// Formats [Money] at the UI edge only.
///
/// bn: '৳১২.৫০' with lakh grouping ('৳১২,৩৪,৫৬৭.০০').
/// en: '৳12.50' with international grouping ('৳1,234,567.00').
/// [useBanglaDigits] defaults to true when [locale] is bn; Step 5 wires it to
/// the 'Use Bangla digits' setting.
final class MoneyFormatter {
  const MoneyFormatter({
    required this.locale,
    this.hideZeroFraction = false,
    this.useBanglaDigits,
  });

  final String locale;
  final bool hideZeroFraction;
  final bool? useBanglaDigits;

  bool get _isBangla => locale.startsWith('bn');

  String format(Money money) {
    final negative = money.isNegative;
    final absolute = negative ? -money.paisa : money.paisa;
    final whole = absolute ~/ 100;
    final fraction = absolute % 100;
    final grouped = _group(whole.toString(), lakh: _isBangla);
    final decimals = hideZeroFraction && fraction == 0
        ? ''
        : '.${fraction.toString().padLeft(2, '0')}';
    final text = '৳$grouped$decimals';
    final localized = (useBanglaDigits ?? _isBangla)
        ? toBanglaDigits(text)
        : text;
    return negative ? '-$localized' : localized;
  }

  static String _group(String digits, {required bool lakh}) {
    if (digits.length <= 3) {
      return digits;
    }
    final tail = digits.substring(digits.length - 3);
    var head = digits.substring(0, digits.length - 3);
    final size = lakh ? 2 : 3;
    final parts = <String>[];
    while (head.length > size) {
      parts.insert(0, head.substring(head.length - size));
      head = head.substring(0, head.length - size);
    }
    parts.insert(0, head);
    return '${parts.join(',')},$tail';
  }
}
