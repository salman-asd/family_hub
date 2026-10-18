import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/features/family/domain/member_role.dart';
import 'package:family_hub/features/family/domain/membership.dart';
import 'package:family_hub/features/family/domain/usecases/approve_member.dart';
import 'package:family_hub/features/family/domain/usecases/change_role.dart';
import 'package:family_hub/features/family/domain/usecases/disable_member.dart';
import 'package:family_hub/features/family/domain/usecases/reject_member.dart';
import 'package:family_hub/features/family/domain/usecases/transfer_admin.dart';
import 'package:flutter_test/flutter_test.dart';

import '../family_test_helpers.dart';

void main() {
  late Fixture f;
  late ApproveMember approve;
  late RejectMember reject;
  late DisableMember disable;
  late ChangeRole changeRole;
  late TransferAdmin transfer;

  setUp(() {
    f = Fixture()
      ..seedFamily({
        'admin': (MemberRole.admin, MembershipStatus.active),
        'mod': (MemberRole.moderator, MembershipStatus.active),
        'kid': (MemberRole.member, MembershipStatus.active),
        'wait': (MemberRole.member, MembershipStatus.pending),
      });
    approve = ApproveMember(f.runner);
    reject = RejectMember(f.runner, f.clock);
    disable = DisableMember(f.runner);
    changeRole = ChangeRole(f.runner);
    transfer = TransferAdmin(
      families: f.backend,
      clock: f.clock,
      newId: f.ids.call,
    );
  });

  MembershipStatus statusOf(String uid) => f.backend.members['fam']![uid]!.status;
  MemberRole roleOf(String uid) => f.backend.members['fam']![uid]!.role;

  group('approve', () {
    test('admin approves a pending member', () async {
      final r = await approve(actorUid: 'admin', familyId: 'fam', targetUid: 'wait');
      expect(r.isSuccess, isTrue);
      expect(statusOf('wait'), MembershipStatus.active);
      expect(f.backend.events.single.type, 'member.approved');
    });

    test('a moderator may approve', () async {
      final r = await approve(actorUid: 'mod', familyId: 'fam', targetUid: 'wait');
      expect(r.isSuccess, isTrue);
    });

    test('a plain member may not, and nothing changes', () async {
      final r = await approve(actorUid: 'kid', familyId: 'fam', targetUid: 'wait');
      expect(r.failureOrNull, const PermissionDenied());
      expect(statusOf('wait'), MembershipStatus.pending);
      expect(f.backend.writes, 0);
    });

    test('a PENDING member cannot approve themselves or others', () async {
      final r = await approve(actorUid: 'wait', familyId: 'fam', targetUid: 'wait');
      expect(r.failureOrNull, const PermissionDenied());
      expect(statusOf('wait'), MembershipStatus.pending);
    });

    test('approving an already active member is a conflict', () async {
      final r = await approve(actorUid: 'admin', familyId: 'fam', targetUid: 'kid');
      expect(r.failureOrNull, const Conflict(code: 'already_active'));
    });

    test('an unknown target is NotFound', () async {
      final r = await approve(actorUid: 'admin', familyId: 'fam', targetUid: 'ghost');
      expect(r.failureOrNull, const NotFound(entity: 'member'));
    });
  });

  group('reject', () {
    test('rejecting soft-deletes the request', () async {
      final r = await reject(actorUid: 'mod', familyId: 'fam', targetUid: 'wait');
      expect(r.isSuccess, isTrue);
      final m = f.backend.members['fam']!['wait']!;
      expect(m.removedAt, f.clock.nowUtc());
      // The record is kept (soft delete) but is no longer listed.
      expect((await f.backend.getMembers('fam')).valueOrNull!.map((m) => m.uid),
          isNot(contains('wait')));
    });

    test('only pending requests can be rejected', () async {
      final r = await reject(actorUid: 'admin', familyId: 'fam', targetUid: 'kid');
      expect(r.failureOrNull, const Conflict(code: 'not_pending'));
    });
  });

  group('disable', () {
    test('admin disables a member', () async {
      final r = await disable(actorUid: 'admin', familyId: 'fam', targetUid: 'kid');
      expect(r.isSuccess, isTrue);
      expect(statusOf('kid'), MembershipStatus.disabled);
    });

    test('a moderator may not disable', () async {
      final r = await disable(actorUid: 'mod', familyId: 'fam', targetUid: 'kid');
      expect(r.failureOrNull, const PermissionDenied());
    });

    test('the only admin cannot be disabled (last-admin guard)', () async {
      final r = await disable(actorUid: 'admin', familyId: 'fam', targetUid: 'admin');
      expect(r.failureOrNull, const Conflict(code: 'last_admin'));
      expect(statusOf('admin'), MembershipStatus.active);
    });

    test('with two admins one may be disabled', () async {
      await changeRole(
        actorUid: 'admin',
        familyId: 'fam',
        targetUid: 'mod',
        newRole: MemberRole.admin,
      );
      final r = await disable(actorUid: 'admin', familyId: 'fam', targetUid: 'mod');
      expect(r.isSuccess, isTrue);
    });

    test('a disabled member is re-enabled by approving', () async {
      await disable(actorUid: 'admin', familyId: 'fam', targetUid: 'kid');
      await approve(actorUid: 'admin', familyId: 'fam', targetUid: 'kid');
      expect(statusOf('kid'), MembershipStatus.active);
    });

    test('a disabled member can no longer manage anything', () async {
      await disable(actorUid: 'admin', familyId: 'fam', targetUid: 'mod');
      final r = await approve(actorUid: 'mod', familyId: 'fam', targetUid: 'wait');
      expect(r.failureOrNull, const PermissionDenied());
    });
  });

  group('change role', () {
    test('admin promotes a member to moderator', () async {
      final r = await changeRole(
        actorUid: 'admin',
        familyId: 'fam',
        targetUid: 'kid',
        newRole: MemberRole.moderator,
      );
      expect(r.isSuccess, isTrue);
      expect(roleOf('kid'), MemberRole.moderator);
    });

    test('the only admin cannot be demoted (last-admin guard)', () async {
      final r = await changeRole(
        actorUid: 'admin',
        familyId: 'fam',
        targetUid: 'admin',
        newRole: MemberRole.member,
      );
      expect(r.failureOrNull, const Conflict(code: 'last_admin'));
      expect(roleOf('admin'), MemberRole.admin);
    });

    test('a member cannot make themselves admin', () async {
      final r = await changeRole(
        actorUid: 'kid',
        familyId: 'fam',
        targetUid: 'kid',
        newRole: MemberRole.admin,
      );
      expect(r.failureOrNull, const PermissionDenied());
      expect(roleOf('kid'), MemberRole.member);
    });

    test('a moderator cannot change roles', () async {
      final r = await changeRole(
        actorUid: 'mod',
        familyId: 'fam',
        targetUid: 'kid',
        newRole: MemberRole.moderator,
      );
      expect(r.failureOrNull, const PermissionDenied());
    });

    test('setting the same role is a conflict', () async {
      final r = await changeRole(
        actorUid: 'admin',
        familyId: 'fam',
        targetUid: 'kid',
        newRole: MemberRole.member,
      );
      expect(r.failureOrNull, const Conflict(code: 'same_role'));
    });
  });

  group('transfer admin', () {
    test('moves the role in ONE write; the family always has an admin', () async {
      final r = await transfer(actorUid: 'admin', familyId: 'fam', targetUid: 'kid');
      expect(r.isSuccess, isTrue);
      expect(roleOf('kid'), MemberRole.admin);
      expect(roleOf('admin'), MemberRole.member);
      expect(f.backend.writes, 1);
      expect(f.backend.events.single.type, 'member.admin_transferred');
    });

    test('the target must be an active member', () async {
      final r = await transfer(actorUid: 'admin', familyId: 'fam', targetUid: 'wait');
      expect(r.failureOrNull, const Conflict(code: 'not_active'));
      expect(roleOf('admin'), MemberRole.admin);
    });

    test('cannot transfer to yourself', () async {
      final r = await transfer(actorUid: 'admin', familyId: 'fam', targetUid: 'admin');
      expect(r.failureOrNull, const Conflict(code: 'same_member'));
    });

    test('only an admin may transfer', () async {
      final r = await transfer(actorUid: 'mod', familyId: 'fam', targetUid: 'kid');
      expect(r.failureOrNull, const PermissionDenied());
    });
  });
}
