import 'dart:convert';
import 'dart:io';

import 'package:family_hub/core/permissions/permission_settings.dart';
import 'package:family_hub/features/chores/occurrences/domain/chore_occurrence.dart';
import 'package:family_hub/features/chores/occurrences/domain/occurrence_parts.dart';
import 'package:family_hub/features/chores/occurrences/domain/occurrence_status.dart';
import 'package:family_hub/features/chores/templates/domain/template_parts.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../chores_test_helpers.dart';
import 'completion_test_support.dart';

/// P-03 (Wave R6): the Dart half of the InMemory-vs-rules parity test.
///
/// `firebase/rules_test/fixtures/occurrence_transitions.json` is run here
/// against the use cases (the in-memory backend) and in
/// `chore_occurrence_parity.test.mjs` against the emulator. Both must agree on
/// every step, so a rule that is stricter or looser than the use case (B-05,
/// B-06, M-02, M-06) fails in exactly one of the two runs.
void main() {
  const path = 'firebase/rules_test/fixtures/occurrence_transitions.json';
  final table =
      jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
  final cases = (table['cases'] as List<dynamic>).cast<Map<String, dynamic>>();

  const familyId = ChoresFixture.familyId;
  const id = 'tpl_1_20261024';
  final at = DateTime.utc(2026, 10, 24, 4);

  // Roles of the table -> the members of ChoresFixture.
  const uids = <String, String>{
    'admin': 'alice',
    'manager': 'bob',
    'assignee': 'cara',
    'plain': 'dave',
  };

  ChoreOccurrence seedFor(String seed) => switch (seed) {
    'scheduled' => anOccurrence(),
    'unassigned' => anOccurrence(assigneeId: null),
    'completed_plain' => anOccurrence(
      status: OccurrenceStatus.completed,
      completedAt: at,
      completedBy: 'cara',
    ),
    'completed_verify' => anOccurrence(
      verification: VerificationMode.required,
      status: OccurrenceStatus.completed,
      completedAt: at,
      completedBy: 'cara',
    ),
    _ => throw ArgumentError('unknown seed $seed'),
  };

  test('the table is not empty and every seed is described', () {
    expect(cases, isNotEmpty);
    final seeds = (table['seeds'] as Map<String, dynamic>).keys.toSet();
    for (final c in cases) {
      expect(seeds, contains(c['seed']), reason: c['name'] as String);
    }
  });

  for (final c in cases) {
    test(c['name'] as String, () async {
      final fixture = ChoresFixture();
      final useCases = CompletionUseCases(fixture);
      final seed = c['seed'] as String;
      fixture.backend.permissionSettings[familyId] = seed == 'completed_verify'
          ? PermissionSettings.defaults.copyWith(
              choreVerificationEnabled: true,
            )
          : PermissionSettings.defaults;
      seedOccurrence(fixture, seedFor(seed));

      final steps = (c['steps'] as List<dynamic>).cast<Map<String, dynamic>>();
      for (var i = 0; i < steps.length; i++) {
        final step = steps[i];
        final actor = uids[step['actor'] as String]!;
        final action = step['action'] as String;
        final target = uids[step['to'] as String? ?? 'plain']!;

        final failure = switch (action) {
          'skip' =>
            (await useCases.skip(
              familyId: familyId,
              actorUid: actor,
              occurrenceId: id,
              reason: 'অসুস্থ',
              kind: SkipReason.absence,
            )).failureOrNull,
          'unskip' =>
            (await useCases.unskip(
              familyId: familyId,
              actorUid: actor,
              occurrenceId: id,
            )).failureOrNull,
          'reassign' =>
            (await useCases.reassign(
              familyId: familyId,
              actorUid: actor,
              occurrenceId: id,
              toMemberId: target,
              reason: 'ছুটিতে',
            )).failureOrNull,
          'verify' =>
            (await useCases.verify(
              familyId: familyId,
              actorUid: actor,
              occurrenceId: id,
            )).failureOrNull,
          'complete' =>
            (await useCases.complete(
              familyId: familyId,
              actorUid: actor,
              occurrenceId: id,
            )).failureOrNull,
          'uncomplete' =>
            (await useCases.uncomplete(
              familyId: familyId,
              actorUid: actor,
              occurrenceId: id,
            )).failureOrNull,
          _ => throw ArgumentError('unknown action $action'),
        };

        final allowed = step['expect'] == 'allow';
        expect(
          failure == null,
          allowed,
          reason:
              'step ${i + 1} ($actor $action): expected '
              '${step['expect']}, got ${failure ?? 'success'}',
        );
      }
    });
  }
}
