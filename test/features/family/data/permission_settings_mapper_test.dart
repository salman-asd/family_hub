import 'package:family_hub/core/firebase/base_mapper.dart';
import 'package:family_hub/core/permissions/permissions.dart';
import 'package:family_hub/core/utils/clock.dart';
import 'package:family_hub/features/family/data/family_mappers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final meta = BaseMapper.createMetadata(
    uid: 'u1',
    clock: FakeClock(DateTime.utc(2026, 10, 18)),
  );

  test('permissions round-trip through a map', () {
    const settings = PermissionSettings(
      moderatorManagesFinance: false,
      membersViewFamilyReports: false,
      membersViewAllContributions: true,
      membersCanInvite: true,
      choreVerificationEnabled: true,
      membersCanCompleteForOthers: true,
    );
    final map = FamilyMappers.permissionsMap(settings, meta);
    expect(FamilyMappers.permissionsFromMap(map), settings);
    expect(map['schemaVersion'], 1);
    expect(map['createdBy'], 'u1');
  });

  test('a missing document or field means the default', () {
    expect(FamilyMappers.permissionsFromMap(null), PermissionSettings.defaults);
    expect(
      FamilyMappers.permissionsFromMap({'membersCanInvite': true}),
      PermissionSettings.defaults.copyWith(membersCanInvite: true),
    );
  });

  test('an ill-typed field never widens a permission', () {
    expect(
      FamilyMappers.permissionsFromMap({
        'membersCanInvite': 'yes',
        'membersViewAllContributions': 1,
      }),
      PermissionSettings.defaults,
    );
  });

  test('the change map touches only the switches and the audit stamp', () {
    final map = FamilyMappers.permissionsChangeMap(
      PermissionSettings.defaults,
      actorUid: 'u1',
      now: DateTime.utc(2026, 10, 18),
    );
    expect(map.keys.toSet(), {
      'moderatorManagesFinance',
      'membersViewFamilyReports',
      'membersViewAllContributions',
      'membersCanInvite',
      'choreVerificationEnabled',
      'membersCanCompleteForOthers',
      'updatedAt',
      'updatedBy',
    });
  });

  test('membersCanCompleteForOthers defaults to off (D-P3-14)', () {
    expect(PermissionSettings.defaults.membersCanCompleteForOthers, isFalse);
    expect(
      FamilyMappers.permissionsFromMap({'membersCanCompleteForOthers': true}),
      PermissionSettings.defaults.copyWith(membersCanCompleteForOthers: true),
    );
  });
}
