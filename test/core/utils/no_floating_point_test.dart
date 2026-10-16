import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('money and quantity code never use the floating point type', () {
    const files = [
      'lib/core/utils/money.dart',
      'lib/core/utils/quantity.dart',
      'lib/core/utils/scaled_decimal.dart',
    ];
    final banned = RegExp(r'\b(double|num)\b|\.toDouble\(|double\.parse');
    for (final path in files) {
      final source = File(path).readAsStringSync();
      expect(banned.hasMatch(source), isFalse, reason: '$path uses a float');
    }
  });
}
