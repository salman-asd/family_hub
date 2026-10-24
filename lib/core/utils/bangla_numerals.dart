const String _banglaDigits = '০১২৩৪৫৬৭৮৯';

final RegExp _asciiDigit = RegExp('[0-9]');
final RegExp _banglaDigit = RegExp('[০-৯]');

/// Replaces ASCII digits 0-9 with Bangla digits; other characters are kept.
String toBanglaDigits(String input) =>
    input.replaceAllMapped(_asciiDigit, (m) => _banglaDigits[int.parse(m[0]!)]);

/// Replaces Bangla digits with ASCII digits 0-9; other characters are kept.
String toEnglishDigits(String input) => input.replaceAllMapped(
  _banglaDigit,
  (m) => _banglaDigits.indexOf(m[0]!).toString(),
);
