import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A numeric text field for money (`scale` 2) and quantities (`scale` 3).
///
/// It accepts Bangla (০–৯) and English digits and one decimal separator, and
/// refuses to type more than [scale] decimals.  It never parses: the screen's
/// controller turns the text into `Money` / `Quantity` with the value objects'
/// `parse` (which also normalises Bangla digits), so there is one parser.
///
/// Money fields show a `৳` prefix (set [showCurrencyPrefix] to override).
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
    this.showCurrencyPrefix,
    this.textInputAction,
    this.onSubmitted,
    super.key,
  });

  final TextEditingController controller;
  final String label;

  /// Localized error shown under the field (also announced by screen readers).
  final String? errorText;

  /// Maximum decimals: 2 for money, 3 for quantities.
  final int scale;

  final ValueChanged<String>? onChanged;
  final bool autofocus;
  final FocusNode? focusNode;
  final bool enabled;

  /// Defaults to `scale == 2` (money).
  final bool? showCurrencyPrefix;

  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final prefix = showCurrencyPrefix ?? scale == 2;
    return TextField(
      controller: controller,
      focusNode: focusNode,
      autofocus: autofocus,
      enabled: enabled,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      textInputAction: textInputAction,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: <TextInputFormatter>[AmountInputFormatter(scale)],
      textAlign: TextAlign.start,
      decoration: InputDecoration(
        labelText: label,
        errorText: errorText,
        errorMaxLines: 3,
        prefixText: prefix ? '৳ ' : null,
      ),
    );
  }
}

/// Keeps only digits (English or Bangla) and a single `.`, with at most
/// [scale] digits after it.  A keystroke that would break the rule is dropped
/// by returning the previous value, so the caret never jumps.
class AmountInputFormatter extends TextInputFormatter {
  const AmountInputFormatter(this.scale) : assert(scale >= 0);

  final int scale;

  static final RegExp _allowed = RegExp(r'^[0-9০-৯]*\.?[0-9০-৯]*$');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // A comma or the Bangla decimal mark typed as a separator becomes '.'.
    final text = newValue.text.replaceAll(',', '.').replaceAll('٫', '.');
    if (!_allowed.hasMatch(text)) return oldValue;
    final dot = text.indexOf('.');
    if (dot >= 0) {
      if (scale == 0) return oldValue;
      if (text.length - dot - 1 > scale) return oldValue;
    }
    if (text == newValue.text) return newValue;
    return newValue.copyWith(
      text: text,
      selection: TextSelection.collapsed(
        offset: newValue.selection.baseOffset.clamp(0, text.length),
      ),
    );
  }
}
