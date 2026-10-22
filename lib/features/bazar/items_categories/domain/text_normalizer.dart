import 'package:family_hub/core/utils/bangla_numerals.dart';

final RegExp _zeroWidth = RegExp('[\u200C\u200D]');
final RegExp _whitespace = RegExp(r'\s+');

/// Case- and spelling-insensitive form used by `ItemSearch`.
///
/// The same function normalizes the stored names/aliases and the typed query,
/// so a query only matches when both sides agree.  It trims, lower-cases,
/// collapses whitespace, drops zero-width joiners (U+200C/U+200D), composes the
/// three Bangla nukta pairs (`ড`+`়` → `ড়`, `ঢ`+`়` → `ঢ়`, `য`+`়` → `য়`) and
/// maps Bangla digits to English ones.
String normalizeSearch(String value) {
  var normalized = value.trim().toLowerCase();
  normalized = normalized.replaceAll(_zeroWidth, '');
  normalized = normalized
      .replaceAll('\u09A1\u09BC', '\u09DC')
      .replaceAll('\u09A2\u09BC', '\u09DD')
      .replaceAll('\u09AF\u09BC', '\u09DF');
  normalized = toEnglishDigits(normalized);
  return normalized.replaceAll(_whitespace, ' ').trim();
}
