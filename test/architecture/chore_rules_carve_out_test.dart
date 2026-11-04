import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// P3-30 (acceptance 10): every Phase 3 collection has its own `match` block in
/// the rules, so none of them still falls through to the generic deny-only
/// block at the bottom. Only `memberStats` (Phase 4) may stay there.
void main() {
  const carved = <String>[
    'choreTemplates',
    'dutyGroups',
    'choreOccurrences',
    'memberAvailability',
    'swapRequests',
    'notificationInbox',
  ];

  test('each chore collection has its own match block', () {
    final rules = File('firebase/firestore.rules').readAsStringSync();
    for (final name in carved) {
      expect(
        RegExp('match\\s+/$name/\\{').hasMatch(rules),
        isTrue,
        reason: '$name has no rules block',
      );
    }
    expect(
      RegExp(r'match\s+/events/\{').hasMatch(rules) &&
          RegExp(r'match\s+/comments/\{').hasMatch(rules),
      isTrue,
      reason: 'occurrence events / comments need their own blocks',
    );
  });

  test('memberStats is the only chore collection left deny-only', () {
    final rules = File('firebase/firestore.rules').readAsStringSync();
    expect(RegExp(r'match\s+/memberStats/\{').hasMatch(rules), isFalse);
  });
}
