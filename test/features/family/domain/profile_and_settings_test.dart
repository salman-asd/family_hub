import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/features/family/domain/family.dart';
import 'package:family_hub/features/family/domain/member_role.dart';
import 'package:family_hub/features/family/domain/membership.dart';
import 'package:family_hub/features/family/domain/relationship.dart';
import 'package:family_hub/features/family/domain/usecases/update_family_settings.dart';
import 'package:family_hub/features/onboarding/domain/usecases/save_profile.dart';
import 'package:family_hub/features/onboarding/domain/user_profile.dart';
import 'package:flutter_test/flutter_test.dart';

import '../family_test_helpers.dart';

void main() {
  late Fixture f;

  setUp(() {
    f = Fixture()
      ..seedFamily({
        'admin': (MemberRole.admin, MembershipStatus.active),
        'kid': (MemberRole.member, MembershipStatus.active),
      });
  });

  group('SaveProfile', () {
    late SaveProfile save;
    setUp(() => save = SaveProfile(f.backend));

    UserProfile p(
      String uid, {
      String name = 'Karim',
      String? nick,
      String? spouse,
    }) => UserProfile(
      uid: uid,
      fullName: name,
      relationship: RelationshipId.father,
      nickname: nick,
      spouseId: spouse,
    );

    test('trims the name and drops an empty nickname', () async {
      await save(
        actorUid: 'u1',
        profile: p('u1', name: '  Karim  ', nick: '  '),
      );
      final saved = f.backend.profiles['u1']!;
      expect(saved.fullName, 'Karim');
      expect(saved.nickname, isNull);
    });

    test('an empty name is a validation failure', () async {
      final r = await save(
        actorUid: 'u1',
        profile: p('u1', name: ' '),
      );
      expect(r.failureOrNull, const Validation('fullName', 'required'));
      expect(f.backend.profiles, isEmpty);
    });

    test('you cannot save someone else\'s profile', () async {
      final r = await save(actorUid: 'u1', profile: p('u2'));
      expect(r.failureOrNull, const PermissionDenied());
    });

    test('you cannot be your own spouse; an empty spouse is fine', () async {
      final bad = await save(
        actorUid: 'u1',
        profile: p('u1', spouse: 'u1'),
      );
      expect(bad.failureOrNull, const Validation('spouseId', 'invalid'));
      final ok = await save(actorUid: 'u1', profile: p('u1'));
      expect(ok.isSuccess, isTrue);
    });

    test('editing inside a family updates the member document too', () async {
      await save(
        actorUid: 'kid',
        familyId: 'fam',
        profile: p('kid', name: 'New Name'),
      );
      expect(f.backend.members['fam']!['kid']!.fullName, 'New Name');
      expect(f.backend.members['fam']!['kid']!.role, MemberRole.member);
    });
  });

  group('UpdateFamilySettings', () {
    late UpdateFamilySettings update;
    setUp(() {
      update = UpdateFamilySettings(
        families: f.backend,
        clock: f.clock,
        newId: f.ids.call,
      );
    });

    test('admin saves name, timezone, currency and module flags', () async {
      final family = f.backend.families['fam']!;
      final changed = family.copyWith(
        name: 'Renamed',
        currency: 'USD',
        modules: family.modules.withFlag('chores', enabled: false),
      );
      final r = await update(actorUid: 'admin', family: changed);
      expect(r.isSuccess, isTrue);
      expect(f.backend.families['fam']!.modules.isEnabled('chores'), isFalse);
      expect(f.backend.families['fam']!.name, 'Renamed');
    });

    test('a member may not', () async {
      final r = await update(
        actorUid: 'kid',
        family: f.backend.families['fam']!,
      );
      expect(r.failureOrNull, const PermissionDenied());
    });

    test('an empty name is rejected', () async {
      final r = await update(
        actorUid: 'admin',
        family: const Family(id: 'fam', name: ' '),
      );
      expect(r.failureOrNull, const Validation('name', 'required'));
    });
  });
}
