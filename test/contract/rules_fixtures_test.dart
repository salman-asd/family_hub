import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:family_hub/core/firebase/base_mapper.dart';
import 'package:family_hub/core/firebase/firestore_paths.dart';
import 'package:family_hub/core/firebase/server_time.dart';
import 'package:family_hub/core/permissions/permissions.dart';
import 'package:family_hub/core/utils/clock.dart';
import 'package:family_hub/features/family/data/family_mappers.dart';
import 'package:family_hub/features/family/domain/family.dart';
import 'package:family_hub/core/audit/audit_event.dart';
import 'package:family_hub/features/family/domain/invitation.dart';
import 'package:family_hub/features/family/domain/member.dart';
import 'package:family_hub/features/family/domain/member_role.dart';
import 'package:family_hub/features/family/domain/membership.dart';
import 'package:family_hub/features/family/domain/relationship.dart';
import 'package:family_hub/features/onboarding/data/firestore_profile_repository.dart';
import 'package:family_hub/features/onboarding/domain/user_profile.dart';
import 'package:flutter_test/flutter_test.dart';

/// H5 contract fixtures: the REAL mapper output, written to disk for
/// `firebase/rules_test/contract.test.mjs` to push through the security rules.
///
/// Timestamps are encoded as `{"__ts": iso}` and the server-clock marker as
/// `{"__serverTime": true}`; the Node test rehydrates both.  The output is
/// deterministic (a fixed clock), so CI can run this test and then
/// `git diff --exit-code firebase/rules_test/fixtures` to catch drift.
void main() {
  test('writes the rules contract fixtures', () {
    final dir = Directory('firebase/rules_test/fixtures');
    dir.createSync(recursive: true);

    const encoder = JsonEncoder.withIndent('  ');
    for (final fixture in _fixtures()) {
      final file = File('${dir.path}/${fixture['scenario']}.json');
      file.writeAsStringSync('${encoder.convert(fixture)}\n');
    }

    expect(
      dir.listSync().whereType<File>().length,
      _fixtures().length,
      reason: 'one JSON file per scenario',
    );
  });
}

const _admin = 'fixAdmin';
const _joiner = 'fixJoiner';
const _familyId = 'fixFam';
const _code = 'ABCD2345';
const _newCode = 'NEWCODE1';
final DateTime _at = DateTime.utc(2026, 10, 18, 10);

BaseDocumentMetadata _meta(String uid) =>
    BaseMapper.createMetadata(uid: uid, clock: FakeClock(_at));

List<Map<String, dynamic>> _fixtures() => <Map<String, dynamic>>[
      _createFamily(),
      _join(),
      _approve(),
      _roleChange(),
      _transferAdmin(),
      _createInvitation(),
      _revokeInvitation(),
      _profile(),
    ];

Map<String, dynamic> _fixture(
  String scenario,
  String actor,
  List<Map<String, dynamic>> writes,
) =>
    <String, dynamic>{
      'scenario': scenario,
      'actor': actor,
      'writes': writes,
    };

Map<String, dynamic> _write(
  String op,
  String path,
  Map<String, dynamic> data,
) =>
    <String, dynamic>{'op': op, 'path': path, 'data': _toJson(data)};

Map<String, dynamic> _createFamily() {
  const family = Family(id: _familyId, name: 'Fix Family');
  final meta = _meta(_admin);
  const owner = Member(
    uid: _admin,
    role: MemberRole.admin,
    status: MembershipStatus.active,
    fullName: 'Fix Admin',
    relationship: 'other',
  );
  final created = AuditEvent(
    id: 'ev1',
    type: 'family.created',
    actorId: _admin,
    summary: 'Family created',
    refType: 'family',
    refId: _familyId,
    at: _at,
    params: const {'familyName': 'Fix Family'},
  );
  return _fixture('create_family', _admin, <Map<String, dynamic>>[
    _write('set', FirestorePaths.familyDoc(_familyId),
        FamilyMappers.familyDocMap(family, meta)),
    _write('set', FirestorePaths.memberDoc(_familyId, _admin),
        FamilyMappers.memberToMap(owner, meta)),
    _write('set', FirestorePaths.settingsDoc(_familyId, 'general'),
        FamilyMappers.generalSettingsMap(family, meta)),
    _write('set', FirestorePaths.settingsDoc(_familyId, 'modules'),
        FamilyMappers.modulesMap(family.modules, meta)),
    _write('set', FirestorePaths.settingsDoc(_familyId, 'permissions'),
        FamilyMappers.permissionsMap(PermissionSettings.defaults, meta)),
    _write('set', FirestorePaths.settingsDoc(_familyId, 'rotationPolicy'),
        FamilyMappers.rotationPolicyMap(meta)),
    _write('set', FirestorePaths.settingsDoc(_familyId, 'notificationDefaults'),
        FamilyMappers.notificationDefaultsMap(meta)),
    _write('set', FirestorePaths.activityDoc(_familyId, 'ev1'),
        FamilyMappers.eventMap(created)),
    _write('set', FirestorePaths.auditLogDoc(_familyId, 'ev1'),
        FamilyMappers.eventMap(created)),
    _write('merge', FirestorePaths.userDoc(_admin),
        <String, dynamic>{'familyId': _familyId}),
  ]);
}

Map<String, dynamic> _join() {
  final meta = _meta(_joiner);
  const member = Member(
    uid: _joiner,
    role: MemberRole.member,
    status: MembershipStatus.pending,
    fullName: 'Fix Joiner',
    relationship: 'other',
    inviteCode: _code,
  );
  final requested = AuditEvent(
    id: 'ev2',
    type: 'member.requested',
    actorId: _joiner,
    summary: 'Requested to join',
    refType: 'member',
    refId: _joiner,
    at: _at,
  );
  final used = FamilyMappers.invitationUsedMap(_joiner, _at);
  return _fixture('join', _joiner, <Map<String, dynamic>>[
    _write('set', FirestorePaths.memberDoc(_familyId, _joiner),
        FamilyMappers.memberToMap(member, meta)),
    _write('set', FirestorePaths.activityDoc(_familyId, 'ev2'),
        FamilyMappers.eventMap(requested)),
    _write('set', FirestorePaths.auditLogDoc(_familyId, 'ev2'),
        FamilyMappers.eventMap(requested)),
    _write('update', FirestorePaths.inviteCodeDoc(_code), used),
    _write('update', FirestorePaths.invitationDoc(_familyId, _code), used),
    _write('merge', FirestorePaths.userDoc(_joiner),
        <String, dynamic>{'familyId': _familyId}),
  ]);
}

Map<String, dynamic> _approve() {
  const member = Member(
    uid: _joiner,
    role: MemberRole.member,
    status: MembershipStatus.active,
    fullName: 'Fix Joiner',
    relationship: 'other',
  );
  final event = AuditEvent(
    id: 'ev3',
    type: 'member.approved',
    actorId: _admin,
    summary: 'Approved',
    refType: 'member',
    refId: _joiner,
    at: _at,
    params: const {'memberName': 'Fix Joiner'},
  );
  return _fixture('approve', _admin, <Map<String, dynamic>>[
    _write('update', FirestorePaths.memberDoc(_familyId, _joiner),
        FamilyMappers.memberChangeMap(member, actorUid: _admin, now: _at)),
    _write('set', FirestorePaths.activityDoc(_familyId, 'ev3'),
        FamilyMappers.eventMap(event)),
    _write('set', FirestorePaths.auditLogDoc(_familyId, 'ev3'),
        FamilyMappers.eventMap(event)),
  ]);
}

Map<String, dynamic> _roleChange() {
  const member = Member(
    uid: _joiner,
    role: MemberRole.moderator,
    status: MembershipStatus.active,
    fullName: 'Fix Joiner',
    relationship: 'other',
  );
  final event = AuditEvent(
    id: 'ev4',
    type: 'member.role_changed',
    actorId: _admin,
    summary: 'Role changed',
    refType: 'member',
    refId: _joiner,
    at: _at,
    params: const {'memberName': 'Fix Joiner', 'newRole': 'moderator'},
  );
  return _fixture('role_change', _admin, <Map<String, dynamic>>[
    _write('update', FirestorePaths.memberDoc(_familyId, _joiner),
        FamilyMappers.memberChangeMap(member, actorUid: _admin, now: _at)),
    _write('set', FirestorePaths.activityDoc(_familyId, 'ev4'),
        FamilyMappers.eventMap(event)),
    _write('set', FirestorePaths.auditLogDoc(_familyId, 'ev4'),
        FamilyMappers.eventMap(event)),
  ]);
}

/// H6: handing the admin role over rewrites both members AND `adminIds` in one
/// batch, exactly like `TransferAdmin`.
Map<String, dynamic> _transferAdmin() {
  const newAdmin = Member(
    uid: _joiner,
    role: MemberRole.admin,
    status: MembershipStatus.active,
    fullName: 'Fix Joiner',
    relationship: 'other',
  );
  const oldAdmin = Member(
    uid: _admin,
    role: MemberRole.member,
    status: MembershipStatus.active,
    fullName: 'Fix Admin',
    relationship: 'other',
  );
  final event = AuditEvent(
    id: 'ev7',
    type: 'member.admin_transferred',
    actorId: _admin,
    summary: 'Admin role moved',
    refType: 'member',
    refId: _joiner,
    at: _at,
    params: const {'memberName': 'Fix Joiner'},
  );
  return _fixture('transfer_admin', _admin, <Map<String, dynamic>>[
    _write('update', FirestorePaths.memberDoc(_familyId, _joiner),
        FamilyMappers.memberChangeMap(newAdmin, actorUid: _admin, now: _at)),
    _write('update', FirestorePaths.memberDoc(_familyId, _admin),
        FamilyMappers.memberChangeMap(oldAdmin, actorUid: _admin, now: _at)),
    _write(
        'update',
        FirestorePaths.familyDoc(_familyId),
        FamilyMappers.familyAdminIdsMap(<String>[_joiner],
            actorUid: _admin, now: _at)),
    _write('set', FirestorePaths.activityDoc(_familyId, 'ev7'),
        FamilyMappers.eventMap(event)),
    _write('set', FirestorePaths.auditLogDoc(_familyId, 'ev7'),
        FamilyMappers.eventMap(event)),
  ]);
}

Map<String, dynamic> _createInvitation() {
  final invitation = Invitation(
    code: _newCode,
    familyId: _familyId,
    role: MemberRole.member,
    expiresAt: _at.add(const Duration(days: 7)),
    createdBy: _admin,
    createdAt: _at,
  );
  final event = AuditEvent(
    id: 'ev5',
    type: 'invitation.created',
    actorId: _admin,
    summary: 'Invitation created',
    refType: 'invitation',
    refId: _newCode,
    at: _at,
  );
  final data = FamilyMappers.invitationToMap(invitation);
  return _fixture('create_invitation', _admin, <Map<String, dynamic>>[
    _write('set', FirestorePaths.inviteCodeDoc(_newCode), data),
    _write('set', FirestorePaths.invitationDoc(_familyId, _newCode), data),
    _write('set', FirestorePaths.activityDoc(_familyId, 'ev5'),
        FamilyMappers.eventMap(event)),
    _write('set', FirestorePaths.auditLogDoc(_familyId, 'ev5'),
        FamilyMappers.eventMap(event)),
  ]);
}

Map<String, dynamic> _revokeInvitation() {
  final revoked = FamilyMappers.invitationRevokedMap(_admin, _at);
  final event = AuditEvent(
    id: 'ev6',
    type: 'invitation.revoked',
    actorId: _admin,
    summary: 'Invitation revoked',
    refType: 'invitation',
    refId: _code,
    at: _at,
  );
  return _fixture('revoke_invitation', _admin, <Map<String, dynamic>>[
    _write('update', FirestorePaths.inviteCodeDoc(_code), revoked),
    _write('update', FirestorePaths.invitationDoc(_familyId, _code), revoked),
    _write('set', FirestorePaths.activityDoc(_familyId, 'ev6'),
        FamilyMappers.eventMap(event)),
    _write('set', FirestorePaths.auditLogDoc(_familyId, 'ev6'),
        FamilyMappers.eventMap(event)),
  ]);
}

Map<String, dynamic> _profile() {
  const profile = UserProfile(
    uid: _joiner,
    fullName: 'Fix Joiner',
    relationship: RelationshipId.other,
  );
  final stamp = BaseMapper.dateTimeToTimestamp(_at);
  return _fixture('profile', _joiner, <Map<String, dynamic>>[
    _write('merge', FirestorePaths.userDoc(_joiner), <String, dynamic>{
      ...FirestoreProfileRepository.profileToMap(profile),
      BaseMapper.keyUpdatedAt: stamp,
      BaseMapper.keyUpdatedBy: _joiner,
      BaseMapper.keyCreatedAt: stamp,
      BaseMapper.keyCreatedBy: _joiner,
      BaseMapper.keySchemaVersion: 1,
    }),
  ]);
}

/// JSON-friendly: Timestamp -> `{"__ts": iso}`, ServerTime -> `{"__serverTime": true}`.
Object? _toJson(Object? value) {
  if (value is Timestamp) {
    return <String, dynamic>{'__ts': value.toDate().toUtc().toIso8601String()};
  }
  if (value is ServerTime) {
    return <String, dynamic>{'__serverTime': true};
  }
  if (value is Map) {
    return <String, dynamic>{
      for (final entry in value.entries)
        entry.key.toString(): _toJson(entry.value),
    };
  }
  if (value is List) {
    return value.map(_toJson).toList();
  }
  return value;
}
