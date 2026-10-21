import 'package:family_hub/features/family/data/relationship_mappers.dart';
import 'package:family_hub/core/firebase/base_mapper.dart';
import 'package:family_hub/core/permissions/permissions.dart';
import 'package:family_hub/core/utils/clock.dart';
import 'package:family_hub/features/family/data/family_mappers.dart';
import 'package:family_hub/features/family/domain/family.dart';
import 'package:family_hub/core/audit/audit_event.dart';
import 'package:family_hub/features/family/domain/invitation.dart';
import 'package:family_hub/features/family/domain/member.dart';
import 'package:family_hub/features/family/domain/member_role.dart';
import 'package:family_hub/features/family/domain/membership.dart';
import 'package:family_hub/features/family/domain/module_flags.dart';
import 'package:family_hub/features/family/domain/relationship_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/rules_source.dart';

/// H5: the closed key sets live in the rules as `*Keys()` functions; every key a
/// real mapper can produce must be in the matching list.  A mapper change that
/// is not reflected in the rules (or vice versa) fails here.
void main() {
  final meta = BaseMapper.createMetadata(
    uid: 'u1',
    clock: FakeClock(DateTime.utc(2026, 10, 18)),
  );

  test('memberToMap keys == memberKeys()', () {
    const m = Member(
      uid: 'u1',
      role: MemberRole.member,
      status: MembershipStatus.pending,
      fullName: 'Karim',
      relationship: 'other',
      inviteCode: 'ABCD2345',
    );
    expect(FamilyMappers.memberToMap(m, meta).keys.toSet(),
        rulesList('memberKeys'));
  });

  test('familyDocMap keys == familyKeys()', () {
    const family = Family(id: 'f1', name: 'Family');
    expect(
      FamilyMappers.familyDocMap(family, meta).keys.toSet(),
      rulesList('familyKeys'),
    );
  });

  test('invitationToMap keys == invitationKeys()', () {
    final invitation = Invitation(
      code: 'ABCD2345',
      familyId: 'f1',
      role: MemberRole.member,
      expiresAt: DateTime.utc(2026, 10, 25),
      createdBy: 'u1',
      createdAt: DateTime.utc(2026, 10, 18),
    );
    expect(
      FamilyMappers.invitationToMap(invitation).keys.toSet(),
      rulesList('invitationKeys'),
    );
  });

  test('settings maps together cover settingsKeys()', () {
    const family = Family(id: 'f1', name: 'Family');
    final produced = <String>{
      ...FamilyMappers.generalSettingsMap(family, meta).keys,
      ...FamilyMappers.modulesMap(ModuleFlags.allOn, meta).keys,
      ...FamilyMappers.permissionsMap(PermissionSettings.defaults, meta).keys,
      ...RelationshipMappers.relationshipsMap(RelationshipCatalog.defaults, meta).keys,
      ...FamilyMappers.rotationPolicyMap(meta).keys,
      ...FamilyMappers.notificationDefaultsMap(meta).keys,
    };
    expect(produced, rulesList('settingsKeys'));
  });

  test('eventMap keys == eventKeys()', () {
    final event = AuditEvent(
      id: 'e1',
      type: 'family.created',
      actorId: 'u1',
      summary: 'created',
      refType: 'family',
      refId: 'f1',
      at: DateTime.utc(2026, 10, 18),
      params: const {'familyName': 'Family'},
    );
    expect(FamilyMappers.eventMap(event).keys.toSet(), rulesList('eventKeys'));
  });
}
