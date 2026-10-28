import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Bangla is the default language, so a missing Bangla string is a bug users
/// see first. `flutter gen-l10n` fills a gap from the template, but it does
/// not fail the build, and it cannot fill a message whose placeholders differ.
/// This test closes both gaps (CLAUDE.md rule 10, road map 3.7).
/// Read inside the tests: a `test` body may call `expect`, a top-level
/// initializer may not, so reading here would crash the whole file.
Map<String, dynamic> en() => _read('lib/core/localization/arb/app_en.arb');
Map<String, dynamic> bn() => _read('lib/core/localization/arb/app_bn.arb');

Set<String> messages(Map<String, dynamic> arb) =>
    arb.keys.where((key) => !key.startsWith('@')).toSet();

void main() {
  test('both ARB files have the same message keys', () {
    final enKeys = messages(en());
    final bnKeys = messages(bn());
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
    final enArb = en();
    final bnArb = bn();
    for (final key in messages(enArb)) {
      expect(enArb[key], isA<String>(), reason: '$key (en)');
      expect(bnArb[key], isA<String>(), reason: '$key (bn)');
      expect((enArb[key] as String).trim(), isNotEmpty, reason: '$key (en)');
      expect((bnArb[key] as String).trim(), isNotEmpty, reason: '$key (bn)');
    }
  });

  test('a message and its translation use the same placeholders', () {
    final enArb = en();
    final bnArb = bn();
    final mismatched = <String>[];
    for (final key in messages(enArb)) {
      final a = _placeholders(enArb[key] as String);
      final b = _placeholders(bnArb[key] as String);
      if (a.length != b.length || !a.containsAll(b) || !b.containsAll(a)) {
        mismatched.add('$key: en $a vs bn $b');
      }
    }
    expect(mismatched, isEmpty);
  });

  test('the P3-03 vocabulary is present in both languages', () {
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
    final enKeys = messages(en());
    final bnKeys = messages(bn());
    for (final key in required) {
      expect(enKeys, contains(key), reason: '$key (en)');
      expect(bnKeys, contains(key), reason: '$key (bn)');
    }
  });
}

/// Reads one ARB file. Called inside the tests on purpose: `expect` may not run
/// while the file is still loading.
Map<String, dynamic> _read(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

/// `{name}` style placeholders of one ICU message.
Set<String> _placeholders(String message) =>
    RegExp(r'\{([A-Za-z0-9_]+)')
        .allMatches(message)
        .map((m) => m.group(1)!)
        .toSet();
