import 'package:family_hub/core/utils/bangla_numerals.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('toBanglaDigits converts digits only', () {
    expect(toBanglaDigits('৳1,250.50'), '৳১,২৫০.৫০');
    expect(toBanglaDigits('abc'), 'abc');
  });

  test('toEnglishDigits converts digits only', () {
    expect(toEnglishDigits('১২.৫ কেজি'), '12.5 কেজি');
  });

  test('round trip', () {
    expect(toEnglishDigits(toBanglaDigits('0123456789')), '0123456789');
  });
}
