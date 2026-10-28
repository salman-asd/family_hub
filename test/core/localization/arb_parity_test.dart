import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Bangla is the default language, so a missing Bangla string is a bug users
/// see first. `flutter gen-l10n` fills a gap from the template, but it does not
/// fail the build, and it cannot fill a message whose placeholders differ.
/// This test closes both gaps (CLAUDE.md rule 10, road map 3.7).
void main() {
  test('both ARB files have the same message keys', () {
    final enKeys = _messages(_read(_enPath));
    final bnKeys = _messages(_read(_bnPath));
    expect(enKeys, isNotEmpty);
    expect(
      enKeys.difference(bnKeys),
      isEmpty,
      reason: 'missing from app_bn.arb: ${enKeys.difference(bnKeys)}',
    );
    expect(
      bnKeys.difference(enKeys),
      isEmpty,
      reason: 'missing from app_en.arb: ${bnKeys.difference(enKeys)}',
    );
  });

  test('every message has a non-blank translation in both languages', () {
    final en = _read(_enPath);
    final bn = _read(_bnPath);
    for (final key in _messages(en)) {
      expect(en[key], isA<String>(), reason: '$key (en)');
      expect(bn[key], isA<String>(), reason: '$key (bn)');
      expect((en[key] as String).trim(), isNotEmpty, reason: '$key (en)');
      expect((bn[key] as String).trim(), isNotEmpty, reason: '$key (bn)');
    }
  });

  test('a message and its translation use the same placeholders', () {
    final en = _read(_enPath);
    final bn = _read(_bnPath);
    final mismatched = <String>[];
    for (final key in _messages(en)) {
      final english = _placeholders(en[key] as String);
      final bangla = _placeholders(bn[key] as String);
      final same =
          english.length == bangla.length &&
          english.containsAll(bangla) &&
          bangla.containsAll(english);
      if (!same) {
        mismatched.add('$key: en $english vs bn $bangla');
      }
    }
    expect(mismatched, isEmpty);
  });

  test('the P3-03 vocabulary is present in both languages', () {
    final enKeys = _messages(_read(_enPath));
    final bnKeys = _messages(_read(_bnPath));
    const required = <String>[
      'choresModuleTitle',
      'choreStatusSkipped',
      'choreFlagNeedsCover',
      'choreFlagAwaitingVerification',
      'choreFlagNeedsAttention',
      'choreFlagPlanned',
      'permissionCompleteChoreForOthers',
      'permissionRecordOwnAvailability',
      'permissionManageAvailability',
      'permissionManageChoreOccurrences',
      'permissionModerateChoreComments',
      'choresFailure_required',
      'choresFailure_invalid_recurrence',
      'choresFailure_reason_required',
      'choresFailure_not_a_recipient',
      'choresFailure_unknown',
    ];
    for (final key in required) {
      expect(enKeys, contains(key), reason: '$key (en)');
      expect(bnKeys, contains(key), reason: '$key (bn)');
    }
  });
}

const String _enPath = 'lib/core/localization/arb/app_en.arb';
const String _bnPath = 'lib/core/localization/arb/app_bn.arb';

/// Reads one ARB file. Called inside each test on purpose: a `test` body may
/// call `expect`, a top-level initializer may not.
Map<String, dynamic> _read(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

Set<String> _messages(Map<String, dynamic> arb) =>
    arb.keys.where((key) => !key.startsWith('@')).toSet();

/// `{name}` style placeholders of one ICU message.
Set<String> _placeholders(String message) =>
    RegExp(r'\{([A-Za-z0-9_]+)')
        .allMatches(message)
        .map((match) => match.group(1)!)
        .toSet();
