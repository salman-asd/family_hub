import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/features/chores/availability/domain/availability_index.dart';
import 'package:family_hub/features/chores/occurrences/domain/occurrence_draft.dart';
import 'package:family_hub/features/chores/occurrences/domain/usecases/drafts_for.dart';
import 'package:family_hub/features/chores/settings/domain/chore_settings_repository.dart';
import 'package:family_hub/features/chores/templates/domain/template_parts.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../chores_test_helpers.dart';
import 'completion_test_support.dart';

/// B-08: the shared draft loader reads duty groups, the absence policy and the
/// roster, so every caller sees the same draft (C-9).
void main() {
  late ChoresFixture fixture;

  const familyId = ChoresFixture.familyId;
  final day = DateKey(2026, 10, 24);

  setUp(() {
    fixture = ChoresFixture();
    fixture.chores.dutyGroups.groups[familyId] = {
      'group_1': aDutyGroup(
        rotation: aRotation(members: const <String>['cara', 'dave', 'alice']),
      ),
    };
  });

  final template = wrapTemplate(
    aTemplate(
      assignee: const AssigneeSpec(
        strategy: AssigneeStrategy.rotation,
        dutyGroupId: 'group_1',
      ),
    ),
  );

  Future<List<OccurrenceDraft>> build({AvailabilityIndex? index}) async {
    final result = await draftsFor(
      familyId: familyId,
      templates: [template],
      range: DateKeyRange(day, day),
      dutyGroups: fixture.chores.dutyGroups,
      settings: fixture.settings,
      families: fixture.families,
      dateKeys: fixture.dateKeys,
      availabilityIndex: index ?? AvailabilityIndex.empty,
    );
    return result.valueOrNull!;
  }

  final caraAway = AvailabilityIndex(<AvailabilitySpan>[
    AvailabilitySpan(memberId: 'cara', startDate: day, endDate: day),
  ]);

  test('a duty-group rotation resolves the member on duty', () async {
    final drafts = await build();
    expect(drafts.single.plannedAssigneeId, 'cara');
  });

  test('the stored absence policy decides the flag', () async {
    fixture.settings.policy = AbsencePolicy.askCover;
    expect((await build(index: caraAway)).single.needsCover, isTrue);

    fixture.settings.policy = AbsencePolicy.skip;
    expect((await build(index: caraAway)).single.needsCover, isFalse);
  });

  test('a failing read is returned, not swallowed', () async {
    fixture.chores.dutyGroups.nextReadFailure = const Network();
    final result = await draftsFor(
      familyId: familyId,
      templates: [template],
      range: DateKeyRange(day, day),
      dutyGroups: fixture.chores.dutyGroups,
      settings: fixture.settings,
      families: fixture.families,
      dateKeys: fixture.dateKeys,
    );
    expect(result.failureOrNull, const Network());
  });
}
