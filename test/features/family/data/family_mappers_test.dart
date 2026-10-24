import 'package:family_hub/core/firebase/base_mapper.dart';
import 'package:family_hub/core/utils/clock.dart';
import 'package:family_hub/features/family/data/family_mappers.dart';
import 'package:family_hub/features/family/domain/invitation.dart';
import 'package:family_hub/features/family/domain/member.dart';
import 'package:family_hub/features/family/domain/member_role.dart';
import 'package:family_hub/features/family/domain/membership.dart';
import 'package:family_hub/features/family/domain/module_flags.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('member round-trips through a map, including removal', () {
    final removed = DateTime.utc(2026, 10, 1, 5);
    final m = Member(
      uid: 'u1',
      role: MemberRole.moderator,
      status: MembershipStatus.pending,
      fullName: 'করিম রহমান',
      nickname: 'করিম',
      relationship: 'father',
      spouseId: 'u2',
      avatarKey: 'p3',
      inviteCode: 'ABCD2345',
      removedAt: removed,
    );
    final map = FamilyMappers.memberToMap(m, _meta());
    expect(FamilyMappers.memberFromMap(map), m);
    expect(map['schemaVersion'], 1);
    expect(map['createdBy'], 'u1');
  });

  test('an unknown status never becomes active', () {
    final m = FamilyMappers.memberFromMap({'uid': 'u', 'status': 'weird'});
    expect(m.status, MembershipStatus.pending);
    expect(
      FamilyMappers.memberFromMap({'uid': 'u', 'role': 'root'}).role,
      MemberRole.member,
    );
  });

  test('membership: removed or missing members map to none', () {
    const live = Member(
      uid: 'u',
      role: MemberRole.admin,
      status: MembershipStatus.active,
      fullName: 'A',
      relationship: 'other',
    );
    expect(FamilyMappers.membershipFromMember('f', null), Membership.none);
    expect(
      FamilyMappers.membershipFromMember(
        'f',
        live.copyWith(removedAt: DateTime.utc(2026)),
      ),
      Membership.none,
    );
    expect(
      FamilyMappers.membershipFromMember('f', live),
      const Membership(
        status: MembershipStatus.active,
        familyId: 'f',
        role: MemberRole.admin,
      ),
    );
  });

  test('invitation round-trips', () {
    final inv = Invitation(
      code: 'ABCD2345',
      familyId: 'f',
      role: MemberRole.member,
      expiresAt: DateTime.utc(2026, 10, 25),
      createdBy: 'u1',
      createdAt: DateTime.utc(2026, 10, 18),
    );
    expect(
      FamilyMappers.invitationFromMap(FamilyMappers.invitationToMap(inv)).code,
      'ABCD2345',
    );
    final back = FamilyMappers.invitationFromMap(
      FamilyMappers.invitationToMap(inv),
    );
    expect(back.expiresAt, inv.expiresAt);
    expect(back.status, InvitationStatus.active);
  });

  test('module flags: missing map means all on; explicit false is kept', () {
    expect(FamilyMappers.modulesFromMap(null), ModuleFlags.allOn);
    final flags = FamilyMappers.modulesFromMap({
      'flags': {'chores': false, 'bazar': true},
    });
    expect(flags.isEnabled('chores'), isFalse);
    expect(flags.isEnabled('bazar'), isTrue);
  });

  test('a member who LEFT round-trips and routes as none', () {
    final at = DateTime.utc(2026, 10, 2, 8);
    final m = Member(
      uid: 'u1',
      role: MemberRole.member,
      status: MembershipStatus.disabled,
      fullName: 'Karim',
      relationship: 'other',
      removedAt: at,
      leftAt: at,
    );
    expect(
      FamilyMappers.memberFromMap(FamilyMappers.memberToMap(m, _meta())),
      m,
    );
    expect(m.hasLeft, isTrue);
    expect(m.isRemoved, isTrue);
    expect(FamilyMappers.membershipFromMember('f', m), Membership.none);
  });

  test('memberChangeMap writes leftAt only when it is set', () {
    final now = DateTime.utc(2026, 10, 2, 8);
    const base = Member(
      uid: 'u1',
      role: MemberRole.member,
      status: MembershipStatus.active,
      fullName: 'Karim',
      relationship: 'other',
    );
    expect(
      FamilyMappers.memberChangeMap(
        base,
        actorUid: 'a',
        now: now,
      ).containsKey('leftAt'),
      isFalse,
    );
    final left = base.copyWith(leftAt: now, removedAt: now);
    expect(
      FamilyMappers.memberChangeMap(
        left,
        actorUid: 'u1',
        now: now,
      ).containsKey('leftAt'),
      isTrue,
    );
  });

  test('family default settings are Asia/Dhaka and BDT', () {
    final f = FamilyMappers.familyFromDocs('f', family: {'name': 'N'});
    expect(f.timezone, 'Asia/Dhaka');
    expect(f.currency, 'BDT');
    expect(f.name, 'N');
  });
}

BaseDocumentMetadata _meta() => BaseMapper.createMetadata(
  uid: 'u1',
  clock: FakeClock(DateTime.utc(2026, 10, 18)),
);
