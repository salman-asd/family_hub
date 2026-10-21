import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Reads a closed list out of `firebase/firestore.rules` (H5).
///
/// The rules keep every closed set in ONE place as
/// `function name() { return ['a', 'b']; }`; the mirror tests compare the Dart
/// constants/mappers against those literals, so a change on either side that is
/// not matched by the other fails the build.
Set<String> rulesList(String functionName) {
  final file = File('firebase/firestore.rules');
  expect(
    file.existsSync(),
    isTrue,
    reason: 'run tests from the repository root (firebase/firestore.rules)',
  );
  final source = file.readAsStringSync();
  final match = RegExp(
    'function\\s+$functionName\\(\\)\\s*\\{\\s*return\\s*\\[(.*?)\\];',
    dotAll: true,
  ).firstMatch(source);
  expect(
    match,
    isNotNull,
    reason:
        'function $functionName() returning a list was not found in the rules',
  );
  return RegExp("'([^']*)'")
      .allMatches(match!.group(1)!)
      .map((m) => m.group(1)!)
      .toSet();
}

/// The whole `firebase/firestore.rules` text (H12).
String rulesSource() {
  final file = File('firebase/firestore.rules');
  expect(file.existsSync(), isTrue, reason: 'run tests from the repository root');
  return file.readAsStringSync();
}
