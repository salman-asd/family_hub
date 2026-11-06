import 'package:family_hub/core/audit/audit_event_type.dart';
import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/features/chores/availability/domain/availability_index.dart';
import 'package:family_hub/features/chores/availability/domain/member_availability.dart';
import 'package:family_hub/features/chores/settings/domain/chore_settings.dart';
import 'package:family_hub/features/chores/settings/domain/chore_settings_repository.dart';
import 'package:family_hub/features/chores/swaps/domain/swap_request.dart';
import 'package:family_hub/features/chores/swaps/domain/swap_rules.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../swaps/swap_test_support.dart';

/// P3-26: absences and the absence policy.
void main() {
  const familyId = SwapKit.familyId;
  late SwapKit kit;

  setUp(() => kit = SwapKit());

  final reason = ChoreSettings.defaults.absenceReasons.first.id;

  Future<AppFailure?> add(
    String actor,
    String member, {
    String id = 'a1',
    int from = 24,
    int to = 26,
    String text = 'Fever',
    String? type,
  }) async => (await kit.addAvailability(
    familyId: familyId,
    actorUid: actor,
    availabilityId: id,
    memberId: member,
    startDate: DateKey(2026, 10, from),
    endDate: DateKey(2026, 10, to),
    typeId: type ?? reason,
    reason: text,
  )).failureOrNull;

  MemberAvailability absence([String id = 'a1']) =>
      kit.fixture.swapWorld.absences[id]!;

  group('AddAvailability', () {
    test('a member records their own absence; it is active', () async {
      expect(await add('cara', 'cara'), isNull);
      expect(absence().status, AvailabilityStatus.active);
      expect(
        kit.fixture.swapWorld.audits.single.type,
        AuditEventType.choresAvailabilityAdded,
      );
    });

    test('it is pending when approval is on, except for a manager', () async {
      kit.fixture.settings.settings = ChoreSettings.defaults.copyWith(
        absenceNeedsApproval: true,
      );
      expect(await add('cara', 'cara'), isNull);
      expect(absence().status, AvailabilityStatus.pending);
      expect(await add('bob', 'bob', id: 'a2'), isNull);
      expect(absence('a2').status, AvailabilityStatus.active);
    });

    test('a member cannot record somebody else’s; a manager can', () async {
      expect(await add('cara', 'dave'), isA<PermissionDenied>());
      expect(await add('bob', 'dave'), isNull);
      expect(await add('erin', 'erin', id: 'a3'), isA<PermissionDenied>());
    });

    test('the range, the reason, the type and overlaps are checked', () async {
      expect(await add('cara', 'cara', from: 26, to: 24), isA<Validation>());
      expect(await add('cara', 'cara', text: 'x'), isA<Validation>());
      expect(await add('cara', 'cara', type: 'nonsense'), isA<Validation>());
      expect(await add('cara', 'cara'), isNull);
      expect(
        await add('cara', 'cara', id: 'a2', from: 25, to: 28),
        const Conflict(code: 'availability_overlap'),
      );
      expect(await add('cara', 'cara', id: 'a3', from: 27, to: 28), isNull);
    });

    test('a range over 366 days is refused', () async {
      final result = await kit.addAvailability(
        familyId: familyId,
        actorUid: 'cara',
        availabilityId: 'a9',
        memberId: 'cara',
        startDate: DateKey(2026, 1, 1),
        endDate: DateKey(2027, 6, 1),
        typeId: reason,
        reason: 'Long trip',
      );
      expect(result.failureOrNull, const Conflict(code: 'range_too_large'));
    });
  });

  group('CancelAvailability / DecideAvailability', () {
    test('the owner or a manager cancels; others cannot', () async {
      await add('cara', 'cara');
      final denied = await kit.cancelAvailability(
        familyId: familyId,
        actorUid: 'dave',
        availabilityId: 'a1',
      );
      expect(denied.failureOrNull, isA<PermissionDenied>());
      final ok = await kit.cancelAvailability(
        familyId: familyId,
        actorUid: 'cara',
        availabilityId: 'a1',
      );
      expect(ok.failureOrNull, isNull);
      expect(absence().status, AvailabilityStatus.cancelled);
      final again = await kit.cancelAvailability(
        familyId: familyId,
        actorUid: 'bob',
        availabilityId: 'a1',
      );
      expect(again.failureOrNull, const Conflict(code: 'concurrent_edit'));
    });

    test('only a manager decides a pending absence', () async {
      kit.seedAbsence('a1', 'cara', status: AvailabilityStatus.pending);
      final denied = await kit.decideAvailability(
        familyId: familyId,
        actorUid: 'cara',
        availabilityId: 'a1',
        approve: true,
      );
      expect(denied.failureOrNull, isA<PermissionDenied>());
      final ok = await kit.decideAvailability(
        familyId: familyId,
        actorUid: 'bob',
        availabilityId: 'a1',
        approve: true,
      );
      expect(ok.failureOrNull, isNull);
      expect(absence().status, AvailabilityStatus.active);
      expect(kit.inbox.sent.last, 'absence_decision -> cara');
      final twice = await kit.decideAvailability(
        familyId: familyId,
        actorUid: 'bob',
        availabilityId: 'a1',
        approve: false,
      );
      expect(twice.failureOrNull, const Conflict(code: 'concurrent_edit'));
    });

    test('the index counts ACTIVE absences only', () {
      kit.seedAbsence('a1', 'cara', status: AvailabilityStatus.pending);
      kit.seedAbsence('a2', 'dave');
      final index = AvailabilityIndex.fromRecords(
        kit.fixture.swapWorld.absences.values,
      );
      expect(index.isUnavailable('cara', DateKey(2026, 10, 25)), isFalse);
      expect(index.isUnavailable('dave', DateKey(2026, 10, 25)), isTrue);
    });
  });

  group('ApplyAbsencePolicy', () {
    setUp(() {
      kit.seedChore(id: 'tpl_1_20261025', day: 25);
      kit.seedChore(id: 'tpl_2_20261025', day: 25, started: true);
      kit.seedChore(id: 'tpl_3_20261025', day: 25, assignee: 'dave');
      kit.seedAbsence('a1', 'cara');
    });

    Future<Object?> apply({String actor = 'cara'}) async =>
        (await kit.applyPolicy(
          familyId: familyId,
          actorUid: actor,
          availabilityId: 'a1',
        )).valueOrNull;

    test(
      'A: the member and the managers learn how many need a cover',
      () async {
        kit.fixture.settings.policy = AbsencePolicy.askCover;
        final outcome = await kit.applyPolicy(
          familyId: familyId,
          actorUid: 'cara',
          availabilityId: 'a1',
        );

        expect(outcome.valueOrNull!.affected.map((o) => o.id), [
          'tpl_1_20261024',
          'tpl_1_20261025',
        ]);
        expect(kit.inbox.sent.toSet(), {
          'needs_cover -> cara',
          'needs_cover -> alice',
          'needs_cover -> bob',
        });
        expect(kit.fixture.swapWorld.swapRequests, isEmpty);
        expect(
          kit.stored().assigneeId,
          'cara',
          reason: 'no silent reassignment',
        );
      },
    );

    test('B: one cover request per chore, the chore is not touched', () async {
      kit.fixture.settings.policy = AbsencePolicy.autoCover;
      final outcome = (await kit.applyPolicy(
        familyId: familyId,
        actorUid: 'cara',
        availabilityId: 'a1',
      )).valueOrNull!;

      expect(outcome.requested, 2);
      expect(outcome.uncovered, 0);
      final requests = kit.fixture.swapWorld.swapRequests.values.toList();
      expect(
        requests.every(
          (r) => r.kind == SwapKind.cover && r.fromMemberId == 'cara',
        ),
        isTrue,
      );
      expect(requests.map((r) => r.toMemberId).toSet(), {
        'alice',
        'bob',
      }, reason: 'spread by workload');
      expect(
        requests.first.id,
        coverRequestId('a1', requests.first.occurrenceId),
      );
      expect(kit.stored().assigneeId, 'cara');
      expect(
        kit.inbox.sent.where((e) => e.startsWith('swap_request')),
        hasLength(2),
      );
    });

    test('B: running it again adds nothing', () async {
      kit.fixture.settings.policy = AbsencePolicy.autoCover;
      await apply();
      final again = (await kit.applyPolicy(
        familyId: familyId,
        actorUid: 'cara',
        availabilityId: 'a1',
      )).valueOrNull!;
      expect(again.requested, 0);
      expect(kit.fixture.swapWorld.swapRequests, hasLength(2));
    });

    test('B: when nobody is available it falls back to A', () async {
      kit.fixture.settings.policy = AbsencePolicy.autoCover;
      for (final m in ['alice', 'bob', 'dave']) {
        kit.seedAbsence('x_$m', m);
      }
      final outcome = (await kit.applyPolicy(
        familyId: familyId,
        actorUid: 'cara',
        availabilityId: 'a1',
      )).valueOrNull!;
      expect(outcome.requested, 0);
      expect(outcome.uncovered, 2);
      expect(kit.inbox.sent, contains('needs_cover -> cara'));
    });

    test(
      'B: a declined cover goes to the next candidate once, then to A',
      () async {
        kit.fixture.settings.policy = AbsencePolicy.autoCover;
        await apply();
        final first = kit.fixture.swapWorld.swapRequests.values.firstWhere(
          (r) => r.occurrenceId == 'tpl_1_20261024',
        );
        final declined = await kit.decline(
          familyId: familyId,
          actorUid: first.toMemberId,
          requestId: first.id,
        );
        expect(declined.failureOrNull, isNull);
        final second = kit.fixture.swapWorld.swapRequests.values.firstWhere(
          (r) => r.id.startsWith('cv2_'),
        );
        expect(second.toMemberId, isNot(first.toMemberId));
        expect(second.toMemberId, isNot('cara'));

        final again = await kit.decline(
          familyId: familyId,
          actorUid: second.toMemberId,
          requestId: second.id,
        );
        expect(again.failureOrNull, isNull);
        expect(
          kit.fixture.swapWorld.swapRequests.values.where(
            (r) => r.id.startsWith('cv2_'),
          ),
          hasLength(1),
        );
        expect(kit.inbox.sent, contains('needs_cover -> cara'));
      },
    );

    test('B: an accepted cover moves only that chore', () async {
      kit.fixture.settings.policy = AbsencePolicy.autoCover;
      await apply();
      final cover = kit.fixture.swapWorld.swapRequests.values.firstWhere(
        (r) => r.occurrenceId == 'tpl_1_20261024',
      );
      final accepted = await kit.accept(
        familyId: familyId,
        actorUid: cover.toMemberId,
        requestId: cover.id,
      );
      expect(accepted.failureOrNull, isNull);
      expect(kit.stored().assigneeId, cover.toMemberId);
      expect(kit.stored().coverForId, 'cara');
      expect(kit.stored('tpl_1_20261025').assigneeId, 'cara');
    });

    test('C: nothing is written', () async {
      kit.fixture.settings.policy = AbsencePolicy.skip;
      final outcome = (await kit.applyPolicy(
        familyId: familyId,
        actorUid: 'cara',
        availabilityId: 'a1',
      )).valueOrNull!;
      expect(outcome.affected, hasLength(2));
      expect(kit.fixture.availability.plans, isEmpty);
    });

    test(
      'only the member or a manager applies it, and only to an active absence',
      () async {
        final denied = await kit.applyPolicy(
          familyId: familyId,
          actorUid: 'dave',
          availabilityId: 'a1',
        );
        expect(denied.failureOrNull, isA<PermissionDenied>());
        kit.seedAbsence('p1', 'cara', status: AvailabilityStatus.pending);
        final pending = await kit.applyPolicy(
          familyId: familyId,
          actorUid: 'cara',
          availabilityId: 'p1',
        );
        expect(pending.failureOrNull, const Conflict(code: 'concurrent_edit'));
      },
    );
  });
}
