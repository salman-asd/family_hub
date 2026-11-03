import 'package:family_hub/core/audit/audit_event_type.dart';
import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/features/chores/occurrences/domain/occurrence_parts.dart';
import 'package:family_hub/features/chores/occurrences/domain/occurrence_write_plan.dart';
import 'package:family_hub/features/chores/settings/domain/chore_settings.dart';
import 'package:family_hub/features/chores/swaps/domain/swap_request.dart';
import 'package:flutter_test/flutter_test.dart';

import '../swap_test_support.dart';

/// P3-26: swap requests, accept, decline, cancel and expiry.
void main() {
  const familyId = SwapKit.familyId;
  const occId = SwapKit.occId;
  late SwapKit kit;

  setUp(() => kit = SwapKit());

  Future<AppFailure?> ask(String from, String to, {String id = 'r1', String reason = 'I am travelling'}) async =>
      (await kit.request(
        familyId: familyId,
        actorUid: from,
        occurrenceId: occId,
        requestId: id,
        toMemberId: to,
        reason: reason,
      )).failureOrNull;

  Future<AppFailure?> take(String uid, {String id = 'r1'}) async =>
      (await kit.accept(familyId: familyId, actorUid: uid, requestId: id)).failureOrNull;

  SwapRequest req([String id = 'r1']) => kit.fixture.swapWorld.swapRequests[id]!;

  group('RequestSwap', () {
    test('the assignee asks; nothing changes on the chore yet', () async {
      expect(await ask('cara', 'dave'), isNull);

      expect(req().isPending, isTrue);
      expect(req().kind, SwapKind.swap);
      expect(req().expiresAt, DateTime.utc(2026, 10, 24, 15), reason: 'due 17:00 - 120 min');
      expect(kit.stored().assigneeId, 'cara');
      expect(kit.inbox.sent, ['swap_request -> dave']);
      expect(
        kit.fixture.swapWorld.audits.single.type,
        AuditEventType.choresSwapRequested,
      );
    });

    test('swaps can be switched off', () async {
      kit.fixture.settings.settings = ChoreSettings.defaults.copyWith(swapsEnabled: false);
      expect(await ask('cara', 'dave'), const Conflict(code: 'swaps_disabled'));
    });

    test('only the assignee asks, a started chore cannot move', () async {
      expect(await ask('dave', 'alice'), isA<PermissionDenied>());
      kit.seedChore(started: true);
      expect(await ask('cara', 'dave'), const Conflict(code: 'occurrence_started'));
    });

    test('the reason, the recipient and the day are checked', () async {
      expect(await ask('cara', 'dave', reason: 'x'), isA<Validation>());
      expect(await ask('cara', 'cara'), isA<Validation>());
      expect(await ask('cara', 'erin'), isA<Validation>(), reason: 'pending member');
      kit.seedAbsence('a1', 'dave');
      expect(await ask('cara', 'dave'), const Conflict(code: 'member_unavailable'));
      expect(kit.fixture.swapWorld.swapRequests, isEmpty);
    });

    test('one pending request per chore; the same intent can be retried', () async {
      expect(await ask('cara', 'dave'), isNull);
      expect(await ask('cara', 'dave'), isNull, reason: 'same id: a retry');
      expect(await ask('cara', 'alice', id: 'r2'), const Conflict(code: 'swap_not_pending'));
    });

    test('a request that would already have lapsed is refused', () async {
      kit.fixture.clock.advance(const Duration(hours: 7));
      expect(await ask('cara', 'dave'), const Conflict(code: 'swap_expired'));
    });
  });

  group('AcceptSwap', () {
    setUp(() async => ask('cara', 'dave'));

    test('moves the chore, keeps the plan, records who and why', () async {
      expect(await take('dave'), isNull);

      expect(kit.stored().assigneeId, 'dave');
      expect(kit.stored().plannedAssigneeId, 'cara', reason: 'rotation untouched');
      expect(kit.stored().assignmentSource, AssignmentSource.swap);
      expect(req().status, SwapStatus.accepted);
      final event = kit.fixture.occurrences.plans.last.events.single;
      expect(event.type, OccurrenceEventType.swapped);
      expect(event.fromAssigneeId, 'cara');
      expect(event.toAssigneeId, 'dave');
      expect(event.reason, 'I am travelling');
      expect(event.requestId, 'r1');
      expect(kit.inbox.sent.last, 'swap_result -> cara');
    });

    test('only the recipient, and only once', () async {
      expect(await take('bob'), const Conflict(code: 'not_a_recipient'));
      expect(await take('dave'), isNull);
      expect(await take('dave'), const Conflict(code: 'swap_not_pending'));
      expect(kit.fixture.swaps.plans.where((p) => p.changes.isNotEmpty), hasLength(1));
    });

    test('an expired request cannot be accepted', () async {
      kit.fixture.clock.advance(const Duration(hours: 7));
      expect(await take('dave'), const Conflict(code: 'swap_expired'));
      expect(kit.stored().assigneeId, 'cara');
    });

    test('a chore that moved or started meanwhile is refused', () async {
      kit.seedChore(assignee: 'bob');
      expect(await take('dave'), const Conflict(code: 'concurrent_edit'));
      kit.seedChore(started: true);
      expect(await take('dave'), const Conflict(code: 'concurrent_edit'));
    });

    test('a recipient who became unavailable cannot accept', () async {
      kit.seedAbsence('a1', 'dave');
      expect(await take('dave'), const Conflict(code: 'member_unavailable'));
    });
  });

  group('DeclineSwap, CancelSwap, ExpireSwaps', () {
    setUp(() async => ask('cara', 'dave'));

    test('decline leaves the chore alone and tells the requester', () async {
      final result = await kit.decline(
        familyId: familyId,
        actorUid: 'dave',
        requestId: 'r1',
        reason: 'Busy',
      );
      expect(result.failureOrNull, isNull);
      expect(req().status, SwapStatus.declined);
      expect(req().responseReason, 'Busy');
      expect(kit.stored().assigneeId, 'cara');
      expect(kit.inbox.sent.last, 'swap_result -> cara');
      final again = await kit.decline(familyId: familyId, actorUid: 'dave', requestId: 'r1');
      expect(again.failureOrNull, const Conflict(code: 'swap_not_pending'));
    });

    test('only the recipient declines', () async {
      final result = await kit.decline(familyId: familyId, actorUid: 'bob', requestId: 'r1');
      expect(result.failureOrNull, const Conflict(code: 'not_a_recipient'));
    });

    test('a plain member who is neither requester nor manager cannot cancel', () async {
      final denied = await kit.cancel(familyId: familyId, actorUid: 'dave', requestId: 'r1');
      expect(denied.failureOrNull, isA<PermissionDenied>());
      expect(req().isPending, isTrue);
    });

    test('the requester cancels and the recipient is told; a manager may too', () async {
      final ok = await kit.cancel(familyId: familyId, actorUid: 'cara', requestId: 'r1');
      expect(ok.failureOrNull, isNull);
      expect(req().status, SwapStatus.cancelled);
      expect(kit.inbox.sent.last, 'swap_result -> dave');

      await ask('cara', 'dave', id: 'r2');
      final byManager = await kit.cancel(familyId: familyId, actorUid: 'bob', requestId: 'r2');
      expect(byManager.failureOrNull, isNull);
    });

    test('expiry marks lapsed requests once', () async {
      kit.fixture.clock.advance(const Duration(hours: 7));
      final first = await kit.expire(familyId: familyId, actorUid: 'dave');
      expect(first.valueOrNull, 1);
      expect(req().status, SwapStatus.expired);
      expect(kit.inbox.sent.last, 'swap_result -> cara');
      final second = await kit.expire(familyId: familyId, actorUid: 'dave');
      expect(second.valueOrNull, 0, reason: 'idempotent');
    });

    test('a pending member cannot expire anything', () async {
      final result = await kit.expire(familyId: familyId, actorUid: 'erin');
      expect(result.failureOrNull, isA<PermissionDenied>());
    });
  });
}
