import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/features/chores/occurrences/domain/effective_status.dart';
import 'package:family_hub/features/chores/occurrences/domain/occurrence_generator.dart';
import 'package:family_hub/features/chores/occurrences/domain/occurrence_parts.dart';
import 'package:family_hub/features/chores/occurrences/domain/occurrence_status.dart';
import 'package:family_hub/features/chores/occurrences/domain/occurrence_write_plan.dart';
import 'package:family_hub/features/chores/occurrences/domain/subtask_sync.dart';
import 'package:family_hub/features/chores/templates/domain/chore_template.dart';
import 'package:family_hub/features/chores/templates/domain/template_parts.dart';
import 'package:flutter_test/flutter_test.dart';

import '../chores_test_helpers.dart';

/// P3-30 (D-P3-9 / D-P3-10): two phones must end in a valid state.
///
/// The pure halves of the concurrency matrix. Accepting the same swap twice and
/// "complete while the other reassigns" are decided by the rules and are in
/// `chore_swaps.test.mjs` and `chore_occurrence_parity.test.mjs`.
void main() {
  final at = DateTime.utc(2026, 10, 24, 6);

  group('two phones tick different steps', () {
    final steps = <TemplateSubtask>[
      aSubtask(id: 'step_1', required: true),
      aSubtask(id: 'step_2', required: true),
    ];

    /// Applies a patch the way Firestore does: dotted keys set, removed keys gone.
    Map<String, Object?> merge(Map<String, Object?> s, OccurrencePatch p) {
      final next = Map<String, Object?>.of(s)..addAll(p.fields);
      p.removedFields.forEach(next.remove);
      return next;
    }

    test('both orders touch disjoint keys and end with both ticks', () {
      final a = SubtaskSync.toggleSubtask(
        occurrence: anOccurrence(subtasks: steps),
        subtaskId: 'step_1',
        actorId: 'cara',
        at: at,
      ).valueOrNull!;
      final b = SubtaskSync.toggleSubtask(
        occurrence: anOccurrence(subtasks: steps),
        subtaskId: 'step_2',
        actorId: 'dave',
        at: at,
      ).valueOrNull!;

      final ab = merge(merge(<String, Object?>{}, a), b);
      final ba = merge(merge(<String, Object?>{}, b), a);
      expect(ab.keys.where((k) => k.startsWith('subtaskDone.')).toSet(), {
        'subtaskDone.step_1',
        'subtaskDone.step_2',
      });
      expect(ab['subtaskDone.step_1'], ba['subtaskDone.step_1']);
      expect(ab['subtaskDone.step_2'], ba['subtaskDone.step_2']);
    });

    test(
      'the effective status follows the merged ticks, not the stored one',
      () {
        // Each phone stored "in_progress"; together every step is ticked.
        final merged = anOccurrence(
          subtasks: steps,
          status: OccurrenceStatus.inProgress,
          subtaskDone: <String, SubtaskDone>{
            'step_1': SubtaskDone(at: at, by: 'cara'),
            'step_2': SubtaskDone(at: at, by: 'dave'),
          },
        );
        expect(effectiveStatus(merged), ChoreStatus.completed);
      },
    );
  });

  group('two devices generate the same range', () {
    final fixture = ChoresFixture();

    List<String> ids() => OccurrenceGenerator.drafts(
      templates: <ChoreTemplate>[
        ChoreTemplate(id: 'tpl_1', draft: aTemplate()),
        ChoreTemplate(
          id: 'tpl_2',
          draft: aTemplate(nameEn: 'Sweep'),
        ),
      ],
      dutyGroups: const [],
      members: fixture.roster,
      range: DateKeyRange(DateKey(2026, 10, 24), DateKey(2026, 11, 23)),
      dateKeys: fixture.dateKeys,
    ).map((d) => d.id).toList();

    test(
      'identical deterministic ids, so a race writes the same documents',
      () {
        final first = ids();
        final second = ids();
        expect(first, second);
        expect(first.toSet(), hasLength(first.length));
        expect(first, contains('tpl_1_20261024'));
      },
    );
  });
}
