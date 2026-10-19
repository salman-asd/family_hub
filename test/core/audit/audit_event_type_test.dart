import 'package:family_hub/core/audit/audit_event_type.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/rules_source.dart';

void main() {
  test('AuditEventType.all matches eventTypes() in firestore.rules', () {
    final inRules = rulesList('eventTypes');
    expect(
      AuditEventType.all.toSet(),
      inRules,
      reason: 'a type exists in only one of the two lists',
    );
    expect(
      AuditEventType.all.toSet().length,
      AuditEventType.all.length,
      reason: 'AuditEventType.all must not repeat a type',
    );
  });
}
