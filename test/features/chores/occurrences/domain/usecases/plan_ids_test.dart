import 'package:family_hub/core/audit/audit_event_type.dart';
import 'package:family_hub/core/permissions/permission_settings.dart';
import 'package:family_hub/features/chores/occurrences/domain/occurrence_write_plan.dart';
import 'package:family_hub/features/chores/occurrences/domain/usecases/occurrence_action.dart';
import 'package:family_hub/features/chores/occurrences/domain/usecases/occurrence_action_writer.dart';
import 'package:family_hub/features/notifications/domain/inbox_port.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../chores_test_helpers.dart';

/// B-10: every event, audit entry and inbox row of a plan gets its OWN id,
/// drawn ONCE per user intent.
void main() {
  OccurrenceWritePlan build(SeqIds ids) {
    final context = OccurrenceContext.build(
      occurrence: anOccurrence(),
      member: aMember(uid: 'bob'),
      settings: PermissionSettings.defaults,
    );
    return OccurrenceActionWriter.planFor(
      context: context,
      at: DateTime.utc(2026, 10, 24, 9),
      patch: const OccurrencePatch(
        occurrenceId: 'tpl_1_20261024',
        fields: <String, Object?>{'status': 'in_progress'},
      ),
      event: const NewEvent(
        occurrenceId: 'tpl_1_20261024',
        type: OccurrenceEventType.reopened,
        reason: 'ঠিকমতো হয়নি',
      ),
      inbox: choreInboxItem(
        type: InboxType.choreReopened,
        toMemberId: 'cara',
        occurrenceId: 'tpl_1_20261024',
        params: const <String, String>{'name': 'বাসন ধোয়া'},
      ),
      audit: const RequiredAudit(type: AuditEventType.choresOccurrenceReopened),
      newId: ids.call,
    );
  }

  test('event, audit and inbox row each carry a distinct, non-empty id', () {
    final plan = build(SeqIds());

    final ids = <String>[
      plan.events.single.id,
      plan.audits.single.id,
      plan.inbox.single.id,
    ];
    expect(ids.every((id) => id.isNotEmpty), isTrue);
    expect(ids.toSet(), hasLength(3));
  });

  test('the same intent (same id source) yields the same ids', () {
    final first = build(SeqIds());
    final second = build(SeqIds());

    expect(second.audits.single.id, first.audits.single.id);
    expect(second.inbox.single.id, first.inbox.single.id);
    expect(second.events.single.id, first.events.single.id);
  });

  test('an id that is already set is kept (a retry reuses it)', () {
    final context = OccurrenceContext.build(
      occurrence: anOccurrence(),
      member: aMember(uid: 'bob'),
      settings: PermissionSettings.defaults,
    );
    final plan = OccurrenceActionWriter.planFor(
      context: context,
      at: DateTime.utc(2026, 10, 24, 9),
      patch: null,
      inbox: const NewInboxItem(
        id: 'inbox_fixed',
        toMemberId: 'cara',
        type: InboxType.choreReopened,
        refType: 'occurrence',
        refId: 'tpl_1_20261024',
      ),
      newId: SeqIds().call,
    );

    expect(plan.inbox.single.id, 'inbox_fixed');
  });
}
