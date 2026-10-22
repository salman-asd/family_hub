import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/permissions/permissions.dart';
import 'package:family_hub/features/family/domain/member_role.dart';
import 'package:family_hub/features/family/domain/membership.dart';
import 'package:family_hub/features/family/domain/permission_access.dart';
import 'package:family_hub/features/family/domain/usecases/approve_member.dart';
import 'package:family_hub/features/family/domain/usecases/change_role.dart';
import 'package:family_hub/features/family/domain/usecases/create_invitation.dart';
import 'package:family_hub/features/family/domain/usecases/disable_member.dart';
import 'package:flutter_test/flutter_test.dart';

import '../family_test_helpers.dart';

/// Step 10 replaced the Step 9 "set of allowed roles" with
/// `PermissionPolicy`.  These tests pin the new entry point
/// ([requirePermission]) and the use cases that now go through it.
void main() {
  late Fixture f;

  setUp(() {
    f = Fixture()
      ..seedFamily({
        'admin': (MemberRole.admin, MembershipStatus.active),
        'mod': (MemberRole.moderator, MembershipStatus.active),
        'kid': (MemberRole.member, MembershipStatus.active),
        'wait': (MemberRole.member, MembershipStatus.pending),
        'off': (MemberRole.member, MembershipStatus.disabled),
      });
    // A rejected member: the document survives with removedAt set.
    f.backend.members['fam']!['gone'] = f.backend.members['fam']!['wait']!
        .copyWith(fullName: 'Person gone', removedAt: f.clock.nowUtc());
  });

  /// Runs [requirePermission] and asserts both the answer and that a denial
  /// writes nothing and that an allow returns the acting member.
  Future<void> check(
    String actor,
    Permission permission, {
    required bool allowed,
    String? ownerId,
  }) async {
    final r = await requirePermission(
      f.backend,
      familyId: 'fam',
      actorUid: actor,
      permission: permission,
      ownerId: ownerId,
    );
    if (allowed) {
      expect(
        r.isSuccess,
        isTrue,
        reason: '$actor should hold ${permission.name}',
      );
      expect(r.valueOrNull?.uid, actor);
    } else {
      expect(
        r.failureOrNull,
        const PermissionDenied(),
        reason: '$actor must not hold ${permission.name}',
      );
      expect(f.backend.writes, 0);
    }
  }

  Future<void> allow(String actor, Permission permission, {String? ownerId}) =>
      check(actor, permission, allowed: true, ownerId: ownerId);

  Future<void> deny(String actor, Permission permission, {String? ownerId}) =>
      check(actor, permission, allowed: false, ownerId: ownerId);

  group('requirePermission', () {
    test('returns the acting member when the matrix allows', () async {
      final r = await requirePermission(
        f.backend,
        familyId: 'fam',
        actorUid: 'admin',
        permission: Permission.inviteMembers,
      );
      expect(r.isSuccess, isTrue);
      expect(r.valueOrNull?.uid, 'admin');
      expect(
        f.backend.writes,
        0,
        reason: 'checking a permission writes nothing',
      );
    });

    test('allows a moderator to invite', () async {
      await allow('mod', Permission.inviteMembers);
    });

    test('denies a plain member inviting', () async {
      await deny('kid', Permission.inviteMembers);
    });

    test(
      'denies a moderator changing a role (changeRoles is admin-only)',
      () async {
        await deny('mod', Permission.changeRoles);
      },
    );

    test('denies a pending member doing anything', () async {
      for (final permission in Permission.values) {
        await deny('wait', permission);
      }
    });

    test('denies a disabled member doing anything', () async {
      for (final permission in Permission.values) {
        await deny('off', permission);
      }
    });

    test('denies a rejected (soft-deleted) member', () async {
      await deny('gone', Permission.commentOnChore);
    });

    test('denies somebody with no member document at all', () async {
      await deny('stranger', Permission.viewFamilyReports);
    });

    test('denies an unauthenticated-looking unknown uid', () async {
      await deny('', Permission.addOwnExpense);
    });

    test('an ownership permission needs the right ownerId', () async {
      await allow('kid', Permission.completeOwnChore, ownerId: 'kid');
      await deny('kid', Permission.completeOwnChore, ownerId: 'admin');
      await deny('kid', Permission.completeOwnChore);
    });

    test('a manager cannot verify their own chore', () async {
      const on = PermissionSettings(choreVerificationEnabled: true);
      const template = PermissionTemplate(verificationEnabled: true);
      final own = await requirePermission(
        f.backend,
        familyId: 'fam',
        actorUid: 'admin',
        permission: Permission.verifyChore,
        ownerId: 'admin',
        settings: on,
        template: template,
      );
      expect(own.failureOrNull, const PermissionDenied());

      final somebodyElse = await requirePermission(
        f.backend,
        familyId: 'fam',
        actorUid: 'admin',
        permission: Permission.verifyChore,
        ownerId: 'kid',
        settings: on,
        template: template,
      );
      expect(somebodyElse.isSuccess, isTrue);
    });
  });

  group('use cases ask the policy first', () {
    test('a moderator may invite', () async {
      final invite = CreateInvitation(
        families: f.backend,
        codes: f.codes,
        clock: f.clock,
        newId: f.ids.call,
      );
      final r = await invite(actorUid: 'mod', familyId: 'fam');
      expect(r.isSuccess, isTrue);
      expect(r.valueOrNull?.role, MemberRole.member);
    });

    test('a plain member may not invite, and nothing is written', () async {
      final invite = CreateInvitation(
        families: f.backend,
        codes: f.codes,
        clock: f.clock,
        newId: f.ids.call,
      );
      final r = await invite(actorUid: 'kid', familyId: 'fam');
      expect(r.failureOrNull, const PermissionDenied());
      expect(f.backend.writes, 0);
    });

    test('a pending member may not approve, and nothing is written', () async {
      final approve = ApproveMember(f.runner);
      final r = await approve(
        actorUid: 'wait',
        familyId: 'fam',
        targetUid: 'wait',
      );
      expect(r.failureOrNull, const PermissionDenied());
      expect(f.backend.writes, 0);
    });

    test('a moderator may approve but may not change a role', () async {
      final approve = ApproveMember(f.runner);
      final approved = await approve(
        actorUid: 'mod',
        familyId: 'fam',
        targetUid: 'wait',
      );
      expect(approved.isSuccess, isTrue);

      final changeRole = ChangeRole(f.runner);
      final denied = await changeRole(
        actorUid: 'mod',
        familyId: 'fam',
        targetUid: 'kid',
        newRole: MemberRole.moderator,
      );
      expect(denied.failureOrNull, const PermissionDenied());
      expect(f.backend.members['fam']!['kid']!.role, MemberRole.member);
    });

    test('a plain member may not disable anybody', () async {
      final disable = DisableMember(f.runner);
      final r = await disable(
        actorUid: 'kid',
        familyId: 'fam',
        targetUid: 'mod',
      );
      expect(r.failureOrNull, const PermissionDenied());
      expect(f.backend.members['fam']!['mod']!.status, MembershipStatus.active);
    });
  });

  group('leavesNoActiveAdmin', () {
    test('is false while another active admin remains', () {
      final members = f.backend.members['fam']!.values.toList();
      final kid = f.backend.members['fam']!['kid']!;
      expect(
        leavesNoActiveAdmin(members, kid.copyWith(role: MemberRole.admin)),
        isFalse,
      );
    });

    test('is true when the only admin is demoted', () {
      final members = f.backend.members['fam']!.values.toList();
      final admin = f.backend.members['fam']!['admin']!;
      expect(
        leavesNoActiveAdmin(members, admin.copyWith(role: MemberRole.member)),
        isTrue,
      );
    });

    test('is true when the only admin is disabled or removed', () {
      final members = f.backend.members['fam']!.values.toList();
      final admin = f.backend.members['fam']!['admin']!;
      expect(
        leavesNoActiveAdmin(
          members,
          admin.copyWith(status: MembershipStatus.disabled),
        ),
        isTrue,
      );
      expect(
        leavesNoActiveAdmin(
          members,
          admin.copyWith(removedAt: f.clock.nowUtc()),
        ),
        isTrue,
      );
    });
  });
}
