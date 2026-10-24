import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../support/rules_source.dart';

/// H13: the sign-off documents exist and the security review names every
/// top-level and nested collection that has a `match` block in the rules, so a
/// new collection cannot ship without being reviewed.
void main() {
  const docs = <String>[
    'docs/phase1_evidence.md',
    'docs/phase1_security_review.md',
    'docs/phase1_manual_test.md',
    'tools/phase1_evidence.sh',
    'tools/coverage_summary.dart',
  ];

  test('the Phase 1 sign-off files exist', () {
    for (final path in docs) {
      expect(File(path).existsSync(), isTrue, reason: '$path is missing');
    }
  });

  test('the security review mentions every collection in the rules', () {
    final review = File('docs/phase1_security_review.md').readAsStringSync();
    final matched = RegExp(r'match\s+/([A-Za-z]+)/\{')
        .allMatches(rulesSource())
        .map((m) => m.group(1)!)
        .toSet();
    final missing = matched.where((c) => !review.contains(c)).toList();
    expect(missing, isEmpty, reason: 'Review these collections: $missing');
  });
}
