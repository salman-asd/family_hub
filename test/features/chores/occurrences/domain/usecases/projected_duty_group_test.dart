import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/features/chores/occurrences/domain/occurrence_generator.dart';
import 'package:family_hub/features/chores/occurrences/domain/occurrence_id.dart';
import 'package:family_hub/features/chores/templates/domain/template_parts.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../chores_test_helpers.dart';
import 'completion_test_support.dart';

/// B-08: the draft behind a PROJECTED item must be the one the generator and
/// the calendar projection build (C-9), duty-group rotation included.
void main() {
  late ChoresFixture fixture;
  late CompletionUseCases useCases;

  const familyId = ChoresFixture.familyId;
  const id = 'tpl_1_20261024';

  setUp(() {
    fixture = ChoresFixture();
    useCases = CompletionUseCases(fixture);
    // Saturday 2026-10-24 is cycle 3 of a weekly rotation anchored on
    // 2026-10-03, so index 3 mod 3 = 0: `cara` is on duty.
    fixture.chores.dutyGroups.groups[familyId] = {
      'group_1': aDutyGroup(
        rotation: aRotation(members: const <String>['cara', 'dave', 'alice']),
      ),
    };
    seedTemplate(
      fixture,
      wrapTemplate(
        aTemplate(
          assignee: const AssigneeSpec(
            strategy: AssigneeStrategy.rotation,
            dutyGroupId: 'group_1',
          ),
        ),
      ),
    );
  });

  test('a plain member on duty completes a projected rotation chore', () async {
    final result = await useCases.complete(
      familyId: familyId,
      actorUid: 'cara',
      occurrenceId: id,
    );

    expect(result.failureOrNull, isNull);
    final created = fixture.occurrences.plans.last.creates.single;
    expect(created.id, id);
    expect(created.plannedAssigneeId, 'cara');
    expect(created.assigneeId, 'cara');
    expect(
      fixture.occurrences.occurrences[familyId]![id]!.assigneeId,
      'cara',
      reason: 'the materialized document must never be unassigned',
    );
  });

  test('a member who is NOT on duty may not complete it', () async {
    final result = await useCases.complete(
      familyId: familyId,
      actorUid: 'dave',
      occurrenceId: id,
    );

    expect(result.failureOrNull, isA<PermissionDenied>());
    expect(fixture.occurrences.plans, isEmpty);
  });

  test('the materialized draft equals the generator output (C-9)', () async {
    await useCases.complete(
      familyId: familyId,
      actorUid: 'cara',
      occurrenceId: id,
    );

    final expected = OccurrenceGenerator.drafts(
      templates: fixture.chores.templates[familyId]!.values.toList(),
      dutyGroups: fixture.chores.dutyGroups.groups[familyId]!.values.toList(),
      members: (await fixture.families.getMembers(familyId)).valueOrNull!,
      range: DateKeyRange(DateKey(2026, 10, 24), DateKey(2026, 10, 24)),
      dateKeys: fixture.dateKeys,
    ).firstWhere((draft) => draft.id == id);
    final created = fixture.occurrences.plans.last.creates.single;
    expect(created.plannedAssigneeId, expected.plannedAssigneeId);
    expect(created.needsCover, expected.needsCover);
    expect(OccurrenceId.parse(created.id).isSuccess, isTrue);
  });
}
