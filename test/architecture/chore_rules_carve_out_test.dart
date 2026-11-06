import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// P3-30 (acceptance 10): every Phase 3 collection has its own `match` block in
/// the rules, so none of them still falls through to the generic deny-only
/// block at the bottom.
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

  test('memberStats reads are owner-only', () {
    final rules = File('firebase/firestore.rules').readAsStringSync();
    final block = rules.split(RegExp(r'match\s+/memberStats/\{')).last;
    expect(
      RegExp(r'allow read:\s*if isSelf\(uid\) && isActiveMember\(f\);')
          .hasMatch(block),
      isTrue,
    );
  });
}
