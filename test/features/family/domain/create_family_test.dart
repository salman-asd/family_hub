import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/features/family/domain/member_role.dart';
import 'package:family_hub/features/family/domain/membership.dart';
import 'package:family_hub/features/family/domain/relationship.dart';
import 'package:family_hub/features/family/domain/usecases/create_family.dart';
import 'package:flutter_test/flutter_test.dart';

import '../family_test_helpers.dart';

void main() {
  late Fixture f;
  late CreateFamily useCase;

  setUp(() {
    f = Fixture();
    useCase = CreateFamily(
      families: f.backend,
      profiles: f.backend,
      clock: f.clock,
      newId: f.ids.call,
    );
  });

  test('creates the family with the caller as active admin in ONE write', () async {
    f.profile('u1', relationship: Relationship.father);
    final result = await useCase(actorUid: 'u1', name: '  Rahman family ');

    final family = result.valueOrNull!;
    expect(family.name, 'Rahman family');
    expect(family.timezone, 'Asia/Dhaka');
    expect(family.currency, 'BDT');
    expect(family.modules.isEnabled('chores'), isTrue);

    final owner = f.backend.members[family.id]!['u1']!;
    expect(owner.role, MemberRole.admin);
    expect(owner.status, MembershipStatus.active);
    expect(owner.relationship, 'father');
    expect(f.backend.userFamily['u1'], family.id);
    expect(f.backend.writes, 1, reason: 'family + member + event = one batch');
  });

  test('writes one family.created activity event', () async {
    f.profile('u1');
    await useCase(actorUid: 'u1', name: 'Home');
    expect(f.backend.events.map((e) => e.type), ['family.created']);
    expect(f.backend.events.single.actorId, 'u1');
  });

  test('an empty name is a validation failure and writes nothing', () async {
    f.profile('u1');
    final result = await useCase(actorUid: 'u1', name: '   ');
    expect(result.failureOrNull, const Validation('name', 'required'));
    expect(f.backend.writes, 0);
  });

  test('without a profile it fails with profile.required', () async {
    final result = await useCase(actorUid: 'u1', name: 'Home');
    expect(result.failureOrNull, const Validation('profile', 'required'));
    expect(f.backend.families, isEmpty);
  });
}
