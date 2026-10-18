import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/features/family/domain/invitation.dart';
import 'package:family_hub/features/family/domain/invite_code_generator.dart';
import 'package:family_hub/features/family/domain/member_role.dart';
import 'package:family_hub/features/family/domain/membership.dart';
import 'package:family_hub/features/family/domain/usecases/create_invitation.dart';
import 'package:family_hub/features/family/domain/usecases/join_with_code.dart';
import 'package:flutter_test/flutter_test.dart';

import '../family_test_helpers.dart';

void main() {
  late Fixture f;
  late CreateInvitation create;
  late JoinWithCode join;

  setUp(() {
    f = Fixture()
      ..seedFamily({
        'admin': (MemberRole.admin, MembershipStatus.active),
        'mod': (MemberRole.moderator, MembershipStatus.active),
        'kid': (MemberRole.member, MembershipStatus.active),
      })
      ..profile('newcomer');
    create = CreateInvitation(
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
  });

  group('InviteCodeGenerator', () {
    test('codes are 8 characters from the unambiguous alphabet', () {
      final gen = InviteCodeGenerator();
      for (var i = 0; i < 200; i++) {
        final code = gen.next();
        expect(code.length, 8);
        expect(InviteCodeGenerator.isWellFormed(code), isTrue, reason: code);
      }
      for (final bad in ['0', 'O', '1', 'I', 'L']) {
        expect(InviteCodeGenerator.alphabet.contains(bad), isFalse);
      }
    });

    test('normalize upper-cases and strips spaces and dashes', () {
      expect(InviteCodeGenerator.normalize(' ab2c-d3ef '), 'AB2CD3EF');
    });
  });

  group('CreateInvitation', () {
    test('admin creates a member code that expires in 7 days', () async {
      final inv =
          (await create(actorUid: 'admin', familyId: 'fam')).valueOrNull!;
      expect(inv.role, MemberRole.member);
      expect(inv.status, InvitationStatus.active);
      expect(inv.expiresAt, f.clock.nowUtc().add(const Duration(days: 7)));
      expect(f.backend.invitations[inv.code], inv);
      expect(f.backend.events.single.type, 'invitation.created');
    });

    test('a moderator may invite', () async {
      expect((await create(actorUid: 'mod', familyId: 'fam')).isSuccess, isTrue);
    });

    test('a plain member may not', () async {
      final r = await create(actorUid: 'kid', familyId: 'fam');
      expect(r.failureOrNull, const PermissionDenied());
      expect(f.backend.invitations, isEmpty);
    });

    test('a stranger may not', () async {
      final r = await create(actorUid: 'nobody', familyId: 'fam');
      expect(r.failureOrNull, const PermissionDenied());
    });
  });

  group('JoinWithCode', () {
    Future<Invitation> invite() async =>
        (await create(actorUid: 'admin', familyId: 'fam')).valueOrNull!;

    test('a valid code creates a PENDING member, never an active one', () async {
      final inv = await invite();
      final member =
          (await join(actorUid: 'newcomer', rawCode: inv.code)).valueOrNull!;
      expect(member.status, MembershipStatus.pending);
      expect(member.role, MemberRole.member);
      expect(member.inviteCode, inv.code);
      expect(f.backend.members['fam']!['newcomer'], member);
      expect(f.backend.userFamily['newcomer'], 'fam');
    });

    test('lower case and dashes are accepted', () async {
      final inv = await invite();
      final typed = inv.code.toLowerCase().replaceRange(4, 4, '-');
      expect((await join(actorUid: 'newcomer', rawCode: typed)).isSuccess, isTrue);
    });

    test('a malformed code is rejected before any lookup', () async {
      final r = await join(actorUid: 'newcomer', rawCode: 'abc');
      expect(r.failureOrNull, const Validation('code', 'invalid'));
    });

    test('an unknown code is NotFound', () async {
      final r = await join(actorUid: 'newcomer', rawCode: 'ABCDEFGH');
      expect(r.failureOrNull, const NotFound(entity: 'invitation'));
    });

    test('a code can be used only once', () async {
      final inv = await invite();
      f.profile('second');
      expect((await join(actorUid: 'newcomer', rawCode: inv.code)).isSuccess, isTrue);
      final again = await join(actorUid: 'second', rawCode: inv.code);
      expect(again.failureOrNull, const Conflict(code: 'code_used'));
      expect(f.backend.members['fam']!.containsKey('second'), isFalse);
    });

    test('an expired code is rejected (exactly at expiry too)', () async {
      final inv = await invite();
      f.clock.setTo(inv.expiresAt);
      final r = await join(actorUid: 'newcomer', rawCode: inv.code);
      expect(r.failureOrNull, const Conflict(code: 'code_expired'));
    });

    test('still valid one second before expiry', () async {
      final inv = await invite();
      f.clock.setTo(inv.expiresAt.subtract(const Duration(seconds: 1)));
      expect((await join(actorUid: 'newcomer', rawCode: inv.code)).isSuccess, isTrue);
    });

    test('a revoked code is rejected', () async {
      final inv = await invite();
      f.backend.invitations[inv.code] = Invitation(
        code: inv.code,
        familyId: inv.familyId,
        role: inv.role,
        expiresAt: inv.expiresAt,
        createdBy: inv.createdBy,
        createdAt: inv.createdAt,
        status: InvitationStatus.revoked,
      );
      final r = await join(actorUid: 'newcomer', rawCode: inv.code);
      expect(r.failureOrNull, const Conflict(code: 'code_revoked'));
    });

    test('joining needs a profile', () async {
      final inv = await invite();
      final r = await join(actorUid: 'noprofile', rawCode: inv.code);
      expect(r.failureOrNull, const Validation('profile', 'required'));
    });

    test('an existing member cannot join the same family again', () async {
      final inv = await invite();
      f.profile('kid');
      final r = await join(actorUid: 'kid', rawCode: inv.code);
      expect(r.failureOrNull, const Conflict(code: 'already_member'));
    });

    test('a pending member cannot act as a manager', () async {
      final inv = await invite();
      await join(actorUid: 'newcomer', rawCode: inv.code);
      final r = await create(actorUid: 'newcomer', familyId: 'fam');
      expect(r.failureOrNull, const PermissionDenied());
    });

    test('a rejected person may join again with a fresh code', () async {
      var inv = await invite();
      await join(actorUid: 'newcomer', rawCode: inv.code);
      final rejected =
          f.backend.members['fam']!['newcomer']!.copyWith(removedAt: f.clock.nowUtc());
      f.backend.members['fam']!['newcomer'] = rejected;
      inv = await invite();
      expect((await join(actorUid: 'newcomer', rawCode: inv.code)).isSuccess, isTrue);
    });
  });
}
