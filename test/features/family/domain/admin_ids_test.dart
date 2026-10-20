import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/features/family/domain/member_role.dart';
import 'package:family_hub/features/family/domain/membership.dart';
import 'package:family_hub/features/family/domain/permission_access.dart';
import 'package:family_hub/features/family/domain/usecases/change_role.dart';
import 'package:family_hub/features/family/domain/usecases/disable_member.dart';
import 'package:family_hub/features/family/domain/usecases/leave_family.dart';
import 'package:family_hub/features/family/domain/usecases/transfer_admin.dart';
import 'package:flutter_test/flutter_test.dart';

import '../family_test_helpers.dart';

/// H6: `families/{f}.adminIds` is rewritten in the SAME batch whenever the
/// active-admin set changes, and only then (the rules check the rest).
void main() {
  late Fixture f;

  setUp(() {
    f = Fixture()
      ..seedFamily({
        'a1': (MemberRole.admin, MembershipStatus.active),
        'a2': (MemberRole.admin, MembershipStatus.active),
        'mod': (MemberRole.moderator, MembershipStatus.active),
        'kid': (MemberRole.member, MembershipStatus.active),
      });
  });

  LeaveFamily leave() => LeaveFamily(
        families: f.backend,
        clock: f.clock,
        newId: f.ids.call,
      );

  test('the seed mirrors the active admins', () {
    expect(f.backend.adminIds['fam'], ['a1', 'a2']);
  });

  test('a member leaving does not touch adminIds', () async {
    f.backend.adminIds['fam'] = ['sentinel'];
    final r = await leave()(actorUid: 'kid', familyId: 'fam');
    expect(r.isSuccess, isTrue);
    expect(f.backend.adminIds['fam'], ['sentinel']);
  });

  test('an admin leaving rewrites adminIds without them', () async {
    final r = await leave()(actorUid: 'a1', familyId: 'fam');
    expect(r.isSuccess, isTrue);
    expect(f.backend.adminIds['fam'], ['a2']);
  });

  test('the only admin cannot leave and nothing is written', () async {
    f.backend.members['fam']!['a2'] =
        f.backend.members['fam']!['a2']!.copyWith(role: MemberRole.member);
    final r = await leave()(actorUid: 'a1', familyId: 'fam');
    expect(r.failureOrNull, const Conflict(code: 'last_admin'));
    expect(f.backend.writes, 0);
  });

  test('disabling an admin rewrites adminIds', () async {
    final r = await DisableMember(f.runner)(
      actorUid: 'a1',
      familyId: 'fam',
      targetUid: 'a2',
    );
    expect(r.isSuccess, isTrue);
    expect(f.backend.adminIds['fam'], ['a1']);
  });

  test('transfer admin writes the new set in one batch', () async {
    final r = await TransferAdmin(
      families: f.backend,
      clock: f.clock,
      newId: f.ids.call,
    )(actorUid: 'a1', familyId: 'fam', targetUid: 'kid');
    expect(r.isSuccess, isTrue);
    expect(f.backend.writes, 1);
    expect(f.backend.adminIds['fam']!.toSet(), {'a2', 'kid'});
  });

  test('a role change that keeps the admin set leaves adminIds alone', () async {
    f.backend.adminIds['fam'] = ['sentinel'];
    final r = await ChangeRole(f.runner)(
      actorUid: 'a1',
      familyId: 'fam',
      targetUid: 'kid',
      newRole: MemberRole.moderator,
    );
    expect(r.isSuccess, isTrue);
    expect(f.backend.adminIds['fam'], ['sentinel']);
  });

  test('a fourth admin is refused (decision D4)', () async {
    f.backend.members['fam']!['mod'] =
        f.backend.members['fam']!['mod']!.copyWith(role: MemberRole.admin);
    final r = await ChangeRole(f.runner)(
      actorUid: 'a1',
      familyId: 'fam',
      targetUid: 'kid',
      newRole: MemberRole.admin,
    );
    expect(r.failureOrNull, const Conflict(code: 'too_many_admins'));
    expect(maxActiveAdmins, 3);
  });
}
