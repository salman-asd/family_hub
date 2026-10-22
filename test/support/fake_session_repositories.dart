import 'dart:async';

import 'package:family_hub/features/family/domain/membership.dart';
import 'package:family_hub/features/family/domain/membership_repository.dart';
import 'package:family_hub/features/onboarding/domain/profile_repository.dart';
import 'package:family_hub/features/family/domain/module_flags.dart';

/// In-memory profile + membership + module-flag data for routing tests.
///
/// Deliberately independent of `lib/app/placeholders/` (which Step 9 deletes):
/// tests must keep working when the placeholders are gone.
class FakeSessionRepositories
    implements ProfileRepository, MembershipRepository, ModuleFlagsRepository {
  FakeSessionRepositories({
    Set<String> profiles = const {},
    Map<String, Membership> memberships = const {},
  }) : _profiles = {...profiles},
       _memberships = {...memberships};

  final Set<String> _profiles;
  final Map<String, Membership> _memberships;
  ModuleFlags _flags = ModuleFlags.allOn;
  final StreamController<void> _changes = StreamController<void>.broadcast();

  @override
  Stream<bool> watchHasProfile(String uid) async* {
    var last = _profiles.contains(uid);
    yield last;
    await for (final _ in _changes.stream) {
      final next = _profiles.contains(uid);
      if (next != last) {
        last = next;
        yield next;
      }
    }
  }

  @override
  Stream<Membership> watchMembership(String uid) async* {
    var last = _memberships[uid] ?? Membership.none;
    yield last;
    await for (final _ in _changes.stream) {
      final next = _memberships[uid] ?? Membership.none;
      if (next != last) {
        last = next;
        yield next;
      }
    }
  }

  @override
  Stream<ModuleFlags> watchModuleFlags(String familyId) async* {
    var last = _flags;
    yield last;
    await for (final _ in _changes.stream) {
      if (_flags != last) {
        last = _flags;
        yield last;
      }
    }
  }

  void addProfile(String uid) {
    _profiles.add(uid);
    _changes.add(null);
  }

  void setMembership(String uid, MembershipStatus status) {
    _memberships[uid] = status == MembershipStatus.none
        ? Membership.none
        : Membership(status: status, familyId: 'fam-1');
    _changes.add(null);
  }

  void setModuleEnabled(String id, {required bool enabled}) {
    _flags = _flags.withFlag(id, enabled: enabled);
    _changes.add(null);
  }

  Future<void> dispose() => _changes.close();
}
