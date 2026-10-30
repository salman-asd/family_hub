import 'package:family_hub/core/audit/audit_event_type.dart';
import 'package:family_hub/core/firebase/fake_tx_runner.dart';
import 'package:family_hub/core/firebase/firestore_paths.dart';
import 'package:family_hub/features/chores/occurrences/data/occurrence_write_stager.dart';
import 'package:family_hub/features/chores/occurrences/domain/occurrence_write_plan.dart';
import 'package:family_hub/features/notifications/domain/inbox_port.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../chores_test_helpers.dart';

/// B-10: inbox rows and audit entries are written under the id the INTENT
/// carries, so a retry overwrites the same row instead of adding a second one.
void main() {
  const familyId = ChoresFixture.familyId;
  final at = DateTime.utc(2026, 10, 24, 9);

  NewInboxItem inbox(String id) => NewInboxItem(
    id: id,
    toMemberId: 'cara',
    type: InboxType.choreReopened,
    refType: 'occurrence',
    refId: 'tpl_1_20261024',
    params: const <String, String>{'name': 'বাসন ধোয়া'},
  );

  NewAudit audit(String id) => NewAudit(
    id: id,
    type: AuditEventType.choresOccurrenceReopened,
    refId: 'tpl_1_20261024',
  );

  OccurrenceWritePlan plan({
    required String inboxId,
    required String auditId,
  }) => OccurrenceWritePlan(
    actorId: 'bob',
    at: at,
    inbox: <NewInboxItem>[inbox(inboxId)],
    audits: <NewAudit>[audit(auditId)],
  );

  Future<FakeTxRunner> stageAll(List<OccurrenceWritePlan> plans) async {
    final runner = FakeTxRunner();
    for (final p in plans) {
      await runner.runBatch(
        (batch) => OccurrenceWriteStager.stage(batch, familyId, p),
      );
    }
    return runner;
  }

  Iterable<String> keys(FakeTxRunner runner, String collection) =>
      runner.store.keys.where((path) => path.startsWith('$collection/'));

  test('the same intent applied twice writes ONE inbox row and ONE audit', () async {
    final same = plan(inboxId: 'inbox_1', auditId: 'audit_1');
    final runner = await stageAll(<OccurrenceWritePlan>[same, same]);

    expect(keys(runner, FirestorePaths.inbox(familyId)), <String>[
      FirestorePaths.inboxDoc(familyId, 'inbox_1'),
    ]);
    expect(keys(runner, FirestorePaths.activity(familyId)), <String>[
      FirestorePaths.activityDoc(familyId, 'audit_1'),
    ]);
    expect(keys(runner, FirestorePaths.auditLogs(familyId)), <String>[
      FirestorePaths.auditLogDoc(familyId, 'audit_1'),
    ]);
  });

  test('a rebuilt plan with the same ids is the same row', () async {
    final runner = await stageAll(<OccurrenceWritePlan>[
      plan(inboxId: 'inbox_1', auditId: 'audit_1'),
      plan(inboxId: 'inbox_1', auditId: 'audit_1'),
    ]);

    expect(keys(runner, FirestorePaths.inbox(familyId)), hasLength(1));
  });

  test('two different intents write two rows', () async {
    final runner = await stageAll(<OccurrenceWritePlan>[
      plan(inboxId: 'inbox_1', auditId: 'audit_1'),
      plan(inboxId: 'inbox_2', auditId: 'audit_2'),
    ]);

    expect(keys(runner, FirestorePaths.inbox(familyId)), hasLength(2));
    expect(keys(runner, FirestorePaths.activity(familyId)), hasLength(2));
  });

  test('two items of ONE plan never share a row', () async {
    final runner = await stageAll(<OccurrenceWritePlan>[
      OccurrenceWritePlan(
        actorId: 'bob',
        at: at,
        inbox: <NewInboxItem>[inbox('inbox_1'), inbox('inbox_2')],
        audits: <NewAudit>[audit('audit_1'), audit('audit_2')],
      ),
    ]);

    expect(keys(runner, FirestorePaths.inbox(familyId)), hasLength(2));
    expect(keys(runner, FirestorePaths.activity(familyId)), hasLength(2));
  });

  test('the stored row is keyed by the intent id, not by a hash', () async {
    final runner = await stageAll(<OccurrenceWritePlan>[
      plan(inboxId: 'inbox_1', auditId: 'audit_1'),
    ]);

    expect(
      runner.store[FirestorePaths.inboxDoc(familyId, 'inbox_1')]?['type'],
      InboxType.choreReopened,
    );
    expect(
      runner.store[FirestorePaths.activityDoc(familyId, 'audit_1')]?['type'],
      AuditEventType.choresOccurrenceReopened,
    );
  });

  test('an unstamped item is a programming error, not a random row', () async {
    final runner = FakeTxRunner();
    for (final unstamped in <OccurrenceWritePlan>[
      plan(inboxId: '', auditId: 'audit_1'),
      plan(inboxId: 'inbox_1', auditId: ''),
    ]) {
      await expectLater(
        runner.runBatch(
          (batch) => OccurrenceWriteStager.stage(batch, familyId, unstamped),
        ),
        throwsStateError,
      );
    }
    expect(runner.store, isEmpty);
  });
}
