import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/features/family/domain/invitation.dart';
import 'package:family_hub/features/family/domain/member_role.dart';
import 'package:family_hub/features/family/domain/membership.dart';
import 'package:family_hub/features/family/domain/usecases/approve_member.dart';
import 'package:family_hub/features/family/domain/usecases/cancel_join_request.dart';
import 'package:family_hub/features/family/domain/usecases/create_family.dart';
import 'package:family_hub/features/family/domain/usecases/create_invitation.dart';
import 'package:family_hub/features/family/domain/usecases/disable_member.dart';
import 'package:family_hub/features/family/domain/usecases/join_with_code.dart';
import 'package:family_hub/features/family/domain/usecases/leave_family.dart';
import 'package:family_hub/features/family/domain/usecases/revoke_invitation.dart';
import 'package:family_hub/features/family/domain/usecases/transfer_admin.dart';
import 'package:flutter_test/flutter_test.dart';

import '../family_test_helpers.dart';

/// Walks docs/membership_state_machine.md.
void main() {
  late Fixture f;
  late CreateFamily createFamily;
  late CreateInvitation invite;
  late JoinWithCode join;
  late ApproveMember approve;
  late DisableMember disable;
  late LeaveFamily leave;
  late CancelJoinRequest cancel;
  late RevokeInvitation revoke;
  late TransferAdmin transfer;

  setUp(() {
    f = Fixture()
      ..seedFamily({
        'admin': (MemberRole.admin, MembershipStatus.active),
        'mod': (MemberRole.moderator, MembershipStatus.active),
        'kid': (MemberRole.member, MembershipStatus.active),
        'off': (MemberRole.member, MembershipStatus.disabled),
      })
      ..profile('newcomer')
      ..profile('kid')
      ..profile('off')
      ..profile('admin');
    createFamily = CreateFamily(
      families: f.backend,
      profiles: f.backend,
      clock: f.clock,
      newId: f.ids.call,
    );
    invite = CreateInvitation(
      families: f.backend,
      codes: f.codes,
      clock: f.clock,
      newId: f.ids.call,
    );
    join = JoinWithCode(
      families: f.backend,
      profiles: f.backend,
      clock: f.clock,
      newId: f.ids.call,
    );
    approve = ApproveMember(f.runner);
    disable = DisableMember(f.runner);
    leave = LeaveFamily(families: f.backend, clock: f.clock, newId: f.ids.call);
    cancel = CancelJoinRequest(
      families: f.backend,
      clock: f.clock,
      newId: f.ids.call,
    );
    revoke = RevokeInvitation(
      families: f.backend,
      clock: f.clock,
      newId: f.ids.call,
    );
    transfer = TransferAdmin(
      families: f.backend,
      clock: f.clock,
      newId: f.ids.call,
    );
  });

  Future<Invitation> newCode() async =>
      (await invite(actorUid: 'admin', familyId: 'fam')).valueOrNull!;

  Future<Membership> pointer(String uid) async =>
      (await f.backend.getUserFamilyPointer(uid)).valueOrNull!;

  group('one family per user (rule 17)', () {
    test('an ACTIVE member cannot create a family', () async {
      final r = await createFamily(actorUid: 'kid', name: 'Other');
      expect(r.failureOrNull, const Conflict(code: 'already_in_family'));
      expect(f.backend.families.keys, ['fam']);
    });

    test('an ACTIVE member cannot join another family', () async {
      f.backend
        ..families['fam2'] = f.backend.families['fam']!
        ..members['fam2'] = {};
      final code = await newCode();
      // Code of famA used by a person who is active in another family.
      f.backend.userFamily['newcomer'] = 'fam2';
      f.backend.members['fam2']!['newcomer'] =
          f.backend.members['fam']!['kid']!.copyWith(fullName: 'x');
      final r = await join(actorUid: 'newcomer', rawCode: code.code);
      expect(r.failureOrNull, const Conflict(code: 'already_in_family'));
    });

    test('a PENDING person cannot create a family', () async {
      final code = await newCode();
      await join(actorUid: 'newcomer', rawCode: code.code);
      final r = await createFamily(actorUid: 'newcomer', name: 'Mine');
      expect(r.failureOrNull, const Conflict(code: 'already_in_family'));
    });

    test('a member DISABLED by an admin cannot create or join elsewhere',
        () async {
      expect(
        (await createFamily(actorUid: 'off', name: 'Mine')).failureOrNull,
        const Conflict(code: 'already_in_family'),
      );
      // Joining the SAME family falls through to the existing-member rule.
      final code = await newCode();
      final other = await join(actorUid: 'off', rawCode: code.code);
      expect(other.failureOrNull, const Conflict(code: 'already_member'));
    });

    test('an admin can re-enable a disabled member', () async {
      final r = await approve(actorUid: 'admin', familyId: 'fam', targetUid: 'off');
      expect(r.isSuccess, isTrue);
      expect((await pointer('off')).status, MembershipStatus.active);
    });

    test('the pointer read failing (offline) fails fast and writes nothing',
        () async {
      f.backend.failNextPointerRead = const Network();
      final writesBefore = f.backend.writes;
      final r = await createFamily(actorUid: 'newcomer', name: 'Mine');
      expect(r.failureOrNull, const Network());
      expect(f.backend.writes, writesBefore);
    });
  });

  group('leave', () {
    test('an active member leaves: history kept, routed as none', () async {
      final r = await leave(actorUid: 'kid', familyId: 'fam');
      final member = r.valueOrNull!;
      expect(member.status, MembershipStatus.disabled);
      expect(member.leftAt, f.clock.nowUtc());
      expect(member.removedAt, f.clock.nowUtc());
      expect(f.backend.members['fam']!.containsKey('kid'), isTrue);
      expect((await pointer('kid')).status, MembershipStatus.none);
      expect(f.backend.events.last.type, 'member.left');
    });

    test('the ONLY admin cannot leave', () async {
      final r = await leave(actorUid: 'admin', familyId: 'fam');
      expect(r.failureOrNull, const Conflict(code: 'last_admin'));
      expect(f.backend.members['fam']!['admin']!.isActive, isTrue);
    });

    test('after TransferAdmin the old admin can leave', () async {
      final t = await transfer(
        actorUid: 'admin',
        familyId: 'fam',
        targetUid: 'mod',
      );
      expect(t.isSuccess, isTrue, reason: '${t.failureOrNull}');
      expect((await leave(actorUid: 'admin', familyId: 'fam')).isSuccess, isTrue);
    });

    test('a pending or disabled member cannot use leave', () async {
      expect(
        (await leave(actorUid: 'off', familyId: 'fam')).failureOrNull,
        const PermissionDenied(),
      );
    });

    test('left, then creates a NEW family', () async {
      await leave(actorUid: 'kid', familyId: 'fam');
      final r = await createFamily(actorUid: 'kid', name: 'Second home');
      expect(r.isSuccess, isTrue);
      expect(f.backend.families.length, 2);
    });

    test('left, then re-joins the same family with a fresh code', () async {
      await leave(actorUid: 'kid', familyId: 'fam');
      final code = await newCode();
      final r = await join(actorUid: 'kid', rawCode: code.code);
      final member = r.valueOrNull!;
      expect(member.status, MembershipStatus.pending);
      expect(member.leftAt, isNull);
      expect(member.isRemoved, isFalse);
    });
  });

  group('leave edge cases', () {
    test('a plain member can leave even if the family has no active admin',
        () async {
      f = Fixture()
        ..seedFamily({'kid': (MemberRole.member, MembershipStatus.active)});
      leave =
          LeaveFamily(families: f.backend, clock: f.clock, newId: f.ids.call);
      final result = await leave(actorUid: 'kid', familyId: 'fam');
      expect(result.isSuccess, isTrue);
    });
  });

  group('cancel a join request', () {
    test('a pending person cancels, then is free again', () async {
      final code = await newCode();
      await join(actorUid: 'newcomer', rawCode: code.code);
      final r = await cancel(actorUid: 'newcomer', familyId: 'fam');
      expect(r.valueOrNull!.removedAt, isNotNull);
      expect((await pointer('newcomer')).status, MembershipStatus.none);
      expect(f.backend.events.last.type, 'member.cancelled');

      final again = await createFamily(actorUid: 'newcomer', name: 'Mine');
      expect(again.isSuccess, isTrue);
    });

    test('an active member cannot "cancel"', () async {
      final r = await cancel(actorUid: 'kid', familyId: 'fam');
      expect(r.failureOrNull, const Conflict(code: 'not_pending'));
    });

    test('a stranger has nothing to cancel', () async {
      final r = await cancel(actorUid: 'newcomer', familyId: 'fam');
      expect(r.failureOrNull, const NotFound(entity: 'member'));
    });
  });

  group('revoke an invitation', () {
    test('a manager revokes an active code; joining then fails', () async {
      final code = await newCode();
      final r = await revoke(actorUid: 'mod', familyId: 'fam', code: code.code);
      expect(r.valueOrNull!.status, InvitationStatus.revoked);
      expect(f.backend.invitations[code.code]!.status, InvitationStatus.revoked);

      final j = await join(actorUid: 'newcomer', rawCode: code.code);
      expect(j.failureOrNull, const Conflict(code: 'code_revoked'));
    });

    test('a plain member may not revoke', () async {
      final code = await newCode();
      final r = await revoke(actorUid: 'kid', familyId: 'fam', code: code.code);
      expect(r.failureOrNull, const PermissionDenied());
      expect(f.backend.invitations[code.code]!.status, InvitationStatus.active);
    });

    test('a used code cannot be revoked', () async {
      final code = await newCode();
      await join(actorUid: 'newcomer', rawCode: code.code);
      final r = await revoke(actorUid: 'admin', familyId: 'fam', code: code.code);
      expect(r.failureOrNull, const Conflict(code: 'not_active'));
    });

    test('an expired code cannot be revoked', () async {
      final code = await newCode();
      f.clock.setTo(code.expiresAt);
      final r = await revoke(actorUid: 'admin', familyId: 'fam', code: code.code);
      expect(r.failureOrNull, const Conflict(code: 'not_active'));
    });

    test('a code of another family is NotFound', () async {
      final code = await newCode();
      final r = await revoke(actorUid: 'admin', familyId: 'other', code: code.code);
      expect(r.isFailure, isTrue);
    });
  });

  group('idempotent retries', () {
    test('a repeated join with the same code returns the same pending member',
        () async {
      final code = await newCode();
      final first = await join(
        actorUid: 'newcomer',
        rawCode: code.code,
        eventId: 'evt-j',
      );
      final second = await join(
        actorUid: 'newcomer',
        rawCode: code.code,
        eventId: 'evt-j',
      );
      expect(second.valueOrNull, first.valueOrNull);
      expect(f.backend.events.where((e) => e.id == 'evt-j').length, 1);
    });
  });

  group('state machine table (docs/membership_state_machine.md)', () {
    // from-state -> action -> allowed?
    test('disabled by admin stays blocked until re-enabled', () async {
      final d = await disable(actorUid: 'admin', familyId: 'fam', targetUid: 'kid');
      expect(d.isSuccess, isTrue);
      expect(
        (await createFamily(actorUid: 'kid', name: 'x')).failureOrNull,
        const Conflict(code: 'already_in_family'),
      );
      await approve(actorUid: 'admin', familyId: 'fam', targetUid: 'kid');
      expect((await leave(actorUid: 'kid', familyId: 'fam')).isSuccess, isTrue);
      expect((await createFamily(actorUid: 'kid', name: 'x')).isSuccess, isTrue);
    });
  });
}
