import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/features/chores/occurrences/domain/chore_item.dart';
import 'package:family_hub/features/chores/occurrences/domain/chore_occurrence.dart';
import 'package:family_hub/features/chores/occurrences/domain/effective_status.dart';
import 'package:family_hub/features/chores/occurrences/domain/occurrence_state_machine.dart';
import 'package:family_hub/features/chores/occurrences/domain/occurrence_status.dart';
import 'package:family_hub/features/chores/occurrences/domain/usecases/occurrence_action.dart';
import 'package:family_hub/features/chores/occurrences/domain/usecases/repair_status.dart';
import 'package:family_hub/features/chores/templates/domain/template_parts.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../chores_test_helpers.dart';
import 'completion_test_support.dart';

/// Wave R4: Q-02 (reads per action), Q-03 (repair), Q-04 (copyWith) and
/// Q-05 (specific failure codes).
void main() {
  late ChoresFixture fixture;
  late CompletionUseCases useCases;
  final at = DateTime.utc(2026, 10, 24, 4);
  const id = 'tpl_1_20261024';
  const f = ChoresFixture.familyId;

  setUp(() {
    fixture = ChoresFixture();
    useCases = CompletionUseCases(fixture);
  });

  ChoreOccurrence? stored() => fixture.occurrences.occurrences[f]?[id];

  group('Q-02: one member read and one settings read per action', () {
    void expectOneRead() {
      expect(fixture.backend.memberReads, 1);
      expect(fixture.backend.permissionReads, 1);
    }

    setUp(() {
      seedOccurrence(
        fixture,
        anOccurrence(subtasks: <TemplateSubtask>[aSubtask(id: 'a')]),
      );
    });

    test('toggleSubtask', () async {
      final r = await useCases.toggleSubtask(
        familyId: f,
        actorUid: 'cara',
        occurrenceId: id,
        subtaskId: 'a',
      );
      expect(r.failureOrNull, isNull);
      expectOneRead();
    });

    test('toggleParent', () async {
      final r = await useCases.toggleParent(
        familyId: f,
        actorUid: 'cara',
        occurrenceId: id,
      );
      expect(r.failureOrNull, isNull);
      expectOneRead();
    });

    test('complete', () async {
      final r = await useCases.complete(
        familyId: f,
        actorUid: 'cara',
        occurrenceId: id,
      );
      expect(r.failureOrNull, isNull);
      expectOneRead();
    });

    test('skip', () async {
      final r = await useCases.skip(
        familyId: f,
        actorUid: 'alice',
        occurrenceId: id,
        reason: 'visitors today',
      );
      expect(r.failureOrNull, isNull);
      expectOneRead();
    });
  });

  group('Q-03: repair never changes the effective status', () {
    final steps = <TemplateSubtask>[
      aSubtask(id: 'a', required: true),
      aSubtask(id: 'b', required: true),
    ];
    SubtaskDone tick() => SubtaskDone(at: at, by: 'cara');

    final cases = <String, ChoreOccurrence>{
      'scheduled': anOccurrence(subtasks: steps),
      'stale cache': anOccurrence(
        subtasks: steps,
        status: OccurrenceStatus.completed,
      ),
      'in progress': anOccurrence(
        subtasks: steps,
        subtaskDone: <String, SubtaskDone>{'a': tick()},
      ),
      'all ticked, cache behind': anOccurrence(
        subtasks: steps,
        status: OccurrenceStatus.inProgress,
        subtaskDone: <String, SubtaskDone>{'a': tick(), 'b': tick()},
      ),
    };

    for (final entry in cases.entries) {
      test(entry.key, () async {
        final before = effectiveStatus(entry.value);
        seedOccurrence(fixture, entry.value);
        final r = await useCases.repair(
          familyId: f,
          actorUid: 'dave',
          occurrenceId: id,
        );
        expect(r.failureOrNull, isNull);
        expect(effectiveStatus(stored()!), before);
        expect(RepairStatus.needsRepair(stored()!), isFalse);
      });
    }

    test('a reopened chore stays in progress after repair', () async {
      seedOccurrence(
        fixture,
        anOccurrence(
          subtasks: steps,
          status: OccurrenceStatus.completed,
          completedAt: at,
          completedBy: 'cara',
          subtaskDone: <String, SubtaskDone>{'a': tick(), 'b': tick()},
        ),
      );
      final reopened = await useCases.reopen(
        familyId: f,
        actorUid: 'cara',
        occurrenceId: id,
        reason: 'not clean enough',
      );
      expect(reopened.failureOrNull, isNull);
      final before = effectiveStatus(stored()!);
      expect(before, isNot(ChoreStatus.completed));

      final r = await useCases.repair(
        familyId: f,
        actorUid: 'dave',
        occurrenceId: id,
      );
      expect(r.failureOrNull, isNull);
      expect(effectiveStatus(stored()!), before);
    });
  });

  group('Q-04: ChoreItem.copyWith', () {
    test('keeps every field, changes only what is named', () {
      final item = ChoreItem.fromOccurrence(
        anOccurrence(
          slotKey: 'evening',
          subtasks: <TemplateSubtask>[aSubtask(id: 'a')],
          verification: VerificationMode.required,
          estimatedMinutes: 20,
          instructions: 'wipe',
        ),
      );
      final same = item.copyWith();
      expect(same, item);

      final overdue = item.copyWith(status: ChoreStatus.overdue);
      expect(overdue.status, ChoreStatus.overdue);
      expect(overdue.copyWith(status: item.status), item);
      expect(overdue.slotKey, 'evening');
      expect(overdue.estimatedMinutes, 20);
      expect(overdue.verification, VerificationMode.required);
    });

    test('an explicit null clears a nullable field', () {
      final item = ChoreItem.fromOccurrence(anOccurrence());
      expect(item.assigneeId, 'cara');
      expect(item.copyWith(assigneeId: null).assigneeId, isNull);
      expect(item.copyWith().assigneeId, 'cara');
    });
  });

  group('Q-05: stateFailure names the real reason', () {
    OccurrenceContext ctx(
      ChoreOccurrence occurrence, {
      String uid = 'cara',
    }) => OccurrenceContext.build(
      occurrence: occurrence,
      member: fixture.backend.members[f]![uid]!,
      settings: fixture.backend.permissionSettings[f]!,
    );

    test('a member acting on another member\'s chore', () {
      expect(
        stateFailure(ctx(anOccurrence(), uid: 'dave'), OccurrenceAction.tickSubtask),
        const Conflict(code: 'not_assigned_to_you'),
      );
    });

    test('manager-only actions by a member are PermissionDenied', () {
      for (final action in <OccurrenceAction>[
        OccurrenceAction.skip,
        OccurrenceAction.reassign,
        OccurrenceAction.recordException,
        OccurrenceAction.unskip,
        OccurrenceAction.softDelete,
      ]) {
        expect(
          stateFailure(ctx(anOccurrence()), action),
          isA<PermissionDenied>(),
          reason: '$action',
        );
      }
    });

    test('state reasons for a manager', () {
      const manager = 'alice';
      final done = anOccurrence(
        status: OccurrenceStatus.completed,
        completedAt: at,
        completedBy: 'cara',
      );
      expect(
        stateFailure(ctx(done, uid: manager), OccurrenceAction.skip),
        const Conflict(code: 'already_completed'),
      );
      expect(
        stateFailure(ctx(done, uid: manager), OccurrenceAction.checkParent),
        const Conflict(code: 'already_completed'),
      );
      expect(
        stateFailure(ctx(anOccurrence(), uid: manager), OccurrenceAction.uncheckParent),
        const Conflict(code: 'not_completed'),
      );
      expect(
        stateFailure(
          ctx(
            anOccurrence(
              subtasks: <TemplateSubtask>[aSubtask(id: 'a')],
              subtaskDone: <String, SubtaskDone>{
                'a': SubtaskDone(at: at, by: 'cara'),
              },
            ),
            uid: manager,
          ),
          OccurrenceAction.softDelete,
        ),
        const Conflict(code: 'occurrence_started'),
      );
    });

    test('no failure when the table allows the action', () {
      expect(
        stateFailure(ctx(anOccurrence()), OccurrenceAction.tickSubtask),
        isNull,
      );
    });

    test('acceptSwap without an accepted request', () {
      expect(
        stateFailure(ctx(anOccurrence()), OccurrenceAction.acceptSwap),
        const Conflict(code: 'not_a_recipient'),
      );
    });
  });
}
