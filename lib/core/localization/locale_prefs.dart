import 'package:flutter/material.dart';

/// Persisted language preferences.
///
/// [languageCode] is the app locale ('bn' default, 'en' optional).
/// [useBanglaDigits] controls whether numbers and dates render with Bangla
/// digits (০১২৩) or ASCII digits — it is independent of [languageCode] so an
/// English reader may still want Bangla numerals and vice-versa.
@immutable
class LocalePrefs {
  const LocalePrefs({
    this.languageCode = defaultLanguageCode,
    this.useBanglaDigits = true,
  });

  /// Bangla is the default app language (roadmap Step 5).
  static const String defaultLanguageCode = 'bn';

  /// Languages this app ships.
  static const List<String> supportedLanguageCodes = ['bn', 'en'];

  static const String _kKeyLanguage = 'language_code';
  static const String _kKeyBanglaDigits = 'use_bangla_digits';

  final String languageCode;
  final bool useBanglaDigits;

  /// Whether [languageCode] is Bangla.
  bool get isBangla => languageCode == 'bn';

  /// The Flutter [Locale] for this preference.
  Locale get locale => Locale(languageCode);

  /// Serialize to a flat map for SharedPreferences storage.
  Map<String, Object> toMap() => {
    _kKeyLanguage: languageCode,
    _kKeyBanglaDigits: useBanglaDigits,
  };

  /// Deserialize from a SharedPreferences-style map.
  /// Unknown values fall back to defaults — never throws.
  factory LocalePrefs.fromMap(Map<String, Object?> map) {
    final rawLanguage = map[_kKeyLanguage];
    final language =
        rawLanguage is String && supportedLanguageCodes.contains(rawLanguage)
        ? rawLanguage
        : defaultLanguageCode;
    final rawDigits = map[_kKeyBanglaDigits];
    return LocalePrefs(
      languageCode: language,
      // Default to Bangla digits for Bangla readers when the key is absent.
      useBanglaDigits: rawDigits is bool ? rawDigits : language == 'bn',
    );
  }

  LocalePrefs copyWith({String? languageCode, bool? useBanglaDigits}) =>
      LocalePrefs(
        languageCode: languageCode ?? this.languageCode,
        useBanglaDigits: useBanglaDigits ?? this.useBanglaDigits,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocalePrefs &&
          other.languageCode == languageCode &&
          other.useBanglaDigits == useBanglaDigits;

  @override
  int get hashCode => Object.hash(languageCode, useBanglaDigits);

  @override
  String toString() =>
      'LocalePrefs(language: $languageCode, banglaDigits: $useBanglaDigits)';
}
