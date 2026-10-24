import 'package:family_hub/core/audit/audit_event_type.dart';
import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/permissions/permissions.dart';
import 'package:family_hub/features/family/domain/member_role.dart';
import 'package:family_hub/features/family/domain/membership.dart';
import 'package:family_hub/features/family/domain/usecases/create_invitation.dart';
import 'package:family_hub/features/family/domain/usecases/update_permission_settings.dart';
import 'package:flutter_test/flutter_test.dart';

import '../family_test_helpers.dart';

/// H7: the use cases read the family's `settings/permissions`.
void main() {
  late Fixture f;
  late UpdatePermissionSettings update;
  late CreateInvitation invite;

  setUp(() {
    f = Fixture()
      ..seedFamily({
        'admin': (MemberRole.admin, MembershipStatus.active),
        'mod': (MemberRole.moderator, MembershipStatus.active),
        'kid': (MemberRole.member, MembershipStatus.active),
        'wait': (MemberRole.member, MembershipStatus.pending),
      });
    update = UpdatePermissionSettings(
      families: f.backend,
      clock: f.clock,
      newId: f.ids.call,
    );
    invite = CreateInvitation(
      families: f.backend,
      codes: f.codes,
      clock: f.clock,
      newId: f.ids.call,
    );
  });

  test('an admin saves the switches and one audit event is written', () async {
    const next = PermissionSettings(membersCanInvite: true);
    final r = await update(actorUid: 'admin', familyId: 'fam', settings: next);
    expect(r.isSuccess, isTrue);
    expect(f.backend.permissionSettings['fam'], next);
    expect(f.backend.events.single.type, AuditEventType.familyUpdated);
    expect(f.backend.events.single.params, {'section': 'permissions'});
  });

  test('a moderator and a member are denied and nothing is written', () async {
    for (final actor in ['mod', 'kid', 'wait']) {
      final r = await update(
        actorUid: actor,
        familyId: 'fam',
        settings: const PermissionSettings(membersCanInvite: true),
      );
      expect(r.failureOrNull, const PermissionDenied(), reason: actor);
    }
    expect(f.backend.writes, 0);
  });

  test('a member may not invite until the family says so', () async {
    final denied = await invite(actorUid: 'kid', familyId: 'fam');
    expect(denied.failureOrNull, const PermissionDenied());

    await update(
      actorUid: 'admin',
      familyId: 'fam',
      settings: const PermissionSettings(membersCanInvite: true),
    );
    final allowed = await invite(actorUid: 'kid', familyId: 'fam');
    expect(allowed.isSuccess, isTrue);
    expect(allowed.valueOrNull?.createdBy, 'kid');
  });

  test('a PENDING member still may not invite when members may', () async {
    await update(
      actorUid: 'admin',
      familyId: 'fam',
      settings: const PermissionSettings(membersCanInvite: true),
    );
    final r = await invite(actorUid: 'wait', familyId: 'fam');
    expect(r.failureOrNull, const PermissionDenied());
  });

  test('switching the family switch off again closes the door', () async {
    await update(
      actorUid: 'admin',
      familyId: 'fam',
      settings: const PermissionSettings(membersCanInvite: true),
    );
    await update(
      actorUid: 'admin',
      familyId: 'fam',
      settings: PermissionSettings.defaults,
    );
    final r = await invite(actorUid: 'kid', familyId: 'fam');
    expect(r.failureOrNull, const PermissionDenied());
  });

  test('moderators still invite by default', () async {
    final r = await invite(actorUid: 'mod', familyId: 'fam');
    expect(r.isSuccess, isTrue);
  });
}
