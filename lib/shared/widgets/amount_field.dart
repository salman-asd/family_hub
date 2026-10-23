import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A numeric text field for money or quantities (P2-12).
///
/// It accepts English (`123`) and Bangla (`১২৩`) digits, one decimal separator
/// and at most [scale] fraction digits.  Money (`scale == 2`) gets the `৳`
/// prefix; a quantity (`scale == 3`) has no prefix.
///
/// The widget does **not** parse: the owning controller parses the text with
/// `Money.parse` / `Quantity.parse`, using the same scale.  That keeps the
/// half-up/integer rules in `core/utils` as the only number parser.
class AmountField extends StatelessWidget {
  const AmountField({
    required this.controller,
    required this.label,
    this.errorText,
    this.scale = 2,
    this.onChanged,
    this.autofocus = false,
    this.focusNode,
    this.enabled = true,
    super.key,
  });

  final TextEditingController controller;

  /// Localized field label (for example "Amount").
  final String label;

  /// Localized validation message; drawn by [InputDecoration].
  final String? errorText;

  /// 2 for money (paisa) or 3 for a quantity (milli-units).
  final int scale;

  /// Raw text callback; the caller parses it.
  final ValueChanged<String>? onChanged;

  final bool autofocus;
  final FocusNode? focusNode;

  /// A disabled field still shows its value and keeps its label.
  final bool enabled;

  /// Currency symbol for money fields, from the app's money formatter.
  static const String moneyPrefix = '৳';

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      enabled: enabled,
      autofocus: autofocus,
      keyboardType: TextInputType.numberWithOptions(decimal: scale > 0),
      inputFormatters: [AmountInputFormatter(scale: scale)],
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        errorText: errorText,
        prefixText: scale == 2 ? moneyPrefix : null,
        border: const OutlineInputBorder(),
      ),
    );
  }
}

/// Keeps only digits, one `.` and at most [scale] decimals.
///
/// Both digit scripts are kept exactly as typed, so a Bangla reader sees the
/// digits they typed; `parseScaledDecimal` understands both.
class AmountInputFormatter extends TextInputFormatter {
  const AmountInputFormatter({required this.scale}) : assert(scale >= 0);

  final int scale;

  static final RegExp _digit = RegExp(r'[0-9\u09E6-\u09EF]');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final buffer = StringBuffer();
    var decimalSeen = false;
    var fractionDigits = 0;
    var dropped = false;

    for (final rune in newValue.text.runes) {
      final character = String.fromCharCode(rune);
      if (_digit.hasMatch(character)) {
        if (!decimalSeen) {
          buffer.write(character);
        } else if (fractionDigits < scale) {
          buffer.write(character);
          fractionDigits++;
        } else {
          dropped = true;
        }
      } else if (character == '.' && !decimalSeen && scale > 0) {
        decimalSeen = true;
        buffer.write(character);
      } else {
        dropped = true;
      }
    }

    if (buffer.isEmpty && dropped) {
      return const TextEditingValue();
    }

    // A leading separator is easier to read as '0.'.
    final filtered = buffer.toString();
    final text = filtered.startsWith('.') ? '0$filtered' : filtered;
    if (!dropped && text == newValue.text) return newValue;

    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
