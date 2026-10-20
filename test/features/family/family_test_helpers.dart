import 'package:family_hub/core/utils/clock.dart';
import 'package:family_hub/features/family/domain/family.dart';
import 'package:family_hub/features/family/domain/invite_code_generator.dart';
import 'package:family_hub/features/family/domain/member.dart';
import 'package:family_hub/features/family/domain/member_role.dart';
import 'package:family_hub/features/family/domain/membership.dart';
import 'package:family_hub/features/family/domain/relationship.dart';
import 'package:family_hub/features/family/domain/usecases/member_change_runner.dart';
import 'package:family_hub/features/onboarding/domain/user_profile.dart';

import '../../support/in_memory_backend.dart';

/// Deterministic ids: id-1, id-2, ...
class SeqIds {
  int _n = 0;
  String call() => 'id-${++_n}';
}

/// Shared fixture: a backend, a fixed clock and an id generator.
class Fixture {
  Fixture()
      : backend = InMemoryBackend(),
        clock = FakeClock(DateTime.utc(2026, 10, 18, 9)),
        ids = SeqIds();

  final InMemoryBackend backend;
  final FakeClock clock;
  final SeqIds ids;

  MemberChangeRunner get runner => MemberChangeRunner(
        families: backend,
        clock: clock,
        newId: ids.call,
      );

  InviteCodeGenerator get codes => InviteCodeGenerator();

  /// Saves a profile for [uid] and returns it.
  UserProfile profile(
    String uid, {
    String name = 'Person',
    Relationship relationship = Relationship.other,
  }) {
    final p = UserProfile(
      uid: uid,
      fullName: '$name $uid',
      relationship: relationship,
    );
    backend.profiles[uid] = p;
    return p;
  }

  /// Seeds family `fam` with the given members: uid -> (role, status).
  void seedFamily(Map<String, (MemberRole, MembershipStatus)> people) {
    backend.families['fam'] = const Family(id: 'fam', name: 'Test family');
    backend.members['fam'] = {
      for (final e in people.entries)
        e.key: Member(
          uid: e.key,
          role: e.value.$1,
          status: e.value.$2,
          fullName: 'Person ${e.key}',
          relationship: 'other',
        ),
    };
    for (final uid in people.keys) {
      backend.userFamily[uid] = 'fam';
    }
    // H6: `families/fam.adminIds` mirrors the active admins.
    backend.adminIds['fam'] = [
      for (final e in people.entries)
        if (e.value.$1 == MemberRole.admin &&
            e.value.$2 == MembershipStatus.active)
          e.key,
    ];
  }
}
