import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/core/utils/bangla_numerals.dart';

final RegExp _decimalPattern = RegExp(r'^(-?)(\d*)(?:\.(\d*))?$');

/// Parses a decimal string into an integer scaled by 10^[scale]
/// (scale 2 gives paisa, scale 3 gives milli-units).
///
/// Uses string and integer logic only, so no binary rounding can occur.
/// Accepts Bangla or English digits, thousands commas and spaces.
/// Failure codes: `empty`, `invalid_format`, `negative`,
/// `too_many_decimals`, `too_large`.
Result<int> parseScaledDecimal(
  String raw, {
  required int scale,
  required String field,
  bool allowNegative = true,
}) {
  final cleaned =
      toEnglishDigits(raw).replaceAll(',', '').replaceAll(RegExp(r'\s'), '');
  if (cleaned.isEmpty) {
    return Failure<int>(Validation(field, 'empty'));
  }
  final match = _decimalPattern.firstMatch(cleaned);
  if (match == null) {
    return Failure<int>(Validation(field, 'invalid_format'));
  }
  final negative = match.group(1) == '-';
  final whole = match.group(2) ?? '';
  final fraction = match.group(3) ?? '';
  if (whole.isEmpty && fraction.isEmpty) {
    return Failure<int>(Validation(field, 'invalid_format'));
  }
  if (negative && !allowNegative) {
    return Failure<int>(Validation(field, 'negative'));
  }
  if (fraction.length > scale) {
    return Failure<int>(Validation(field, 'too_many_decimals'));
  }
  if (whole.length > 12) {
    return Failure<int>(Validation(field, 'too_large'));
  }
  final digits =
      '${whole.isEmpty ? '0' : whole}${fraction.padRight(scale, '0')}';
  final value = int.parse(digits);
  return Success<int>(negative ? -value : value);
}
