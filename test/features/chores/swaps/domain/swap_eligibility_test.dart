import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/features/chores/availability/domain/availability_index.dart';
import 'package:family_hub/features/chores/swaps/domain/swap_eligibility.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../chores_test_helpers.dart';

void main() {
  test('only active members who are free that day are offered', () async {
    final fixture = ChoresFixture();
    final members = (await fixture.families.getMembers(ChoresFixture.familyId))
        .valueOrNull!;
    final day = DateKey(2026, 10, 24);
    final away = AvailabilityIndex(<AvailabilitySpan>[
      AvailabilitySpan(memberId: 'dave', startDate: day, endDate: day),
    ]);

    final ids = eligibleRecipients(
      members: members,
      requesterId: 'cara',
      day: day,
      index: away,
    ).map((m) => m.uid).toList();

    expect(ids, isNot(contains('cara')), reason: 'not the requester');
    expect(ids, isNot(contains('dave')), reason: 'away that day');
    expect(ids, isNot(contains('erin')), reason: 'pending member');
    expect(ids, containsAll(<String>['alice', 'bob']));
  });

  test(
    'the family order is kept and a free day offers everybody active',
    () async {
      final fixture = ChoresFixture();
      final members = (await fixture.families.getMembers(
        ChoresFixture.familyId,
      )).valueOrNull!;
      final ids = eligibleRecipients(
        members: members,
        requesterId: 'alice',
        day: DateKey(2026, 10, 24),
        index: AvailabilityIndex.empty,
      ).map((m) => m.uid).toList();
      expect(ids, <String>['bob', 'cara', 'dave']);
    },
  );
}
