import 'dart:async';

import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/features/family/domain/family.dart';
import 'package:family_hub/features/family/domain/family_event.dart';
import 'package:family_hub/features/family/domain/family_repository.dart';
import 'package:family_hub/features/family/domain/invitation.dart';
import 'package:family_hub/features/family/domain/member.dart';
import 'package:family_hub/features/family/domain/membership.dart';
import 'package:family_hub/features/family/domain/membership_repository.dart';
import 'package:family_hub/features/onboarding/domain/profile_repository.dart';
import 'package:family_hub/features/onboarding/domain/user_profile.dart';
import 'package:family_hub/features/onboarding/domain/user_profile_repository.dart';
import 'package:family_hub/modules/module_flags.dart';

/// One in-memory "Firestore" implementing every repository port of Steps 8-9,
/// with live streams, for use-case and widget tests.
class InMemoryBackend
    implements
        FamilyRepository,
        UserProfileRepository,
        ProfileRepository,
        MembershipRepository,
        ModuleFlagsRepository {
  final Map<String, UserProfile> profiles = {};
  final Map<String, Family> families = {};
  final Map<String, Map<String, Member>> members = {};
  final Map<String, Invitation> invitations = {};
  final Map<String, String> userFamily = {};
  final List<FamilyEvent> events = [];

  /// Number of write batches that were applied (one per mutating call).
  int writes = 0;

  /// Tests: the next server pointer read fails with this (offline).
  AppFailure? failNextPointerRead;

  /// Tests: the next mutating call fails with this and writes nothing.
  AppFailure? failNextWrite;

  Result<void>? _consumeFailure() {
    final f = failNextWrite;
    if (f == null) return null;
    failNextWrite = null;
    return Failure<void>(f);
  }

  final StreamController<void> _changes = StreamController<void>.broadcast();

  void _notify() => _changes.add(null);

  /// Lets tests mutate the maps directly and then publish the change.
  void backendNotify() => _notify();

  Stream<T> _live<T>(T Function() read) async* {
    var last = read();
    yield last;
    await for (final _ in _changes.stream) {
      final next = read();
      if (next != last) {
        last = next;
        yield next;
      }
    }
  }

  Stream<List<T>> _liveList<T>(List<T> Function() read) async* {
    yield read();
    await for (final _ in _changes.stream) {
      yield read();
    }
  }

  // ── Profiles ──────────────────────────────────────────────────────────────

  @override
  Future<Result<UserProfile?>> getProfile(String uid) async =>
      Success(profiles[uid]);

  @override
  Stream<UserProfile?> watchProfile(String uid) =>
      _liveList<UserProfile?>(() => [profiles[uid]]).map((l) => l.first);

  @override
  Stream<bool> watchHasProfile(String uid) =>
      _live(() => profiles.containsKey(uid));

  @override
  Future<Result<void>> saveProfile(
    UserProfile profile, {
    String? familyId,
  }) async {
    profiles[profile.uid] = profile;
    if (familyId != null) {
      final m = members[familyId]?[profile.uid];
      if (m != null) {
        members[familyId]![profile.uid] = Member(
          uid: m.uid,
          role: m.role,
          status: m.status,
          fullName: profile.fullName,
          relationship: profile.relationship.name,
          nickname: profile.nickname,
          spouseId: profile.spouseId,
          avatarKey: profile.avatarKey,
          inviteCode: m.inviteCode,
          removedAt: m.removedAt,
          leftAt: m.leftAt,
        );
      }
    }
    writes++;
    _notify();
    return const Success<void>(null);
  }

  // ── Family ────────────────────────────────────────────────────────────────

  @override
  Future<Result<void>> createFamily({
    required Family family,
    required Member owner,
    required FamilyEvent event,
  }) async {
    final failed = _consumeFailure();
    if (failed != null) return failed;
    families[family.id] = family;
    members[family.id] = {owner.uid: owner};
    userFamily[owner.uid] = family.id;
    events.add(event);
    writes++;
    _notify();
    return const Success<void>(null);
  }

  @override
  Future<Result<Invitation?>> findInvitation(String code) async =>
      Success(invitations[code]);

  @override
  Future<Result<void>> saveInvitation(
    Invitation invitation,
    FamilyEvent event,
  ) async {
    invitations[invitation.code] = invitation;
    events.add(event);
    writes++;
    _notify();
    return const Success<void>(null);
  }

  @override
  Future<Result<void>> requestToJoin({
    required Invitation invitation,
    required Member member,
    required FamilyEvent event,
  }) async {
    final failed = _consumeFailure();
    if (failed != null) return failed;
    members.putIfAbsent(invitation.familyId, () => {})[member.uid] = member;
    userFamily[member.uid] = invitation.familyId;
    invitations[invitation.code] = invitation.markUsed(member.uid);
    events.add(event);
    writes++;
    _notify();
    return const Success<void>(null);
  }

  @override
  Future<Result<Membership>> getUserFamilyPointer(String uid) async {
    final failure = failNextPointerRead;
    if (failure != null) {
      failNextPointerRead = null;
      return Failure<Membership>(failure);
    }
    final fid = userFamily[uid];
    final m = fid == null ? null : members[fid]?[uid];
    if (fid == null || m == null || m.isRemoved) {
      return const Success<Membership>(Membership.none);
    }
    return Success<Membership>(
      Membership(status: m.status, familyId: fid, role: m.role),
    );
  }

  @override
  Future<Result<void>> revokeInvitation(
    Invitation invitation,
    FamilyEvent event,
  ) async {
    final failed = _consumeFailure();
    if (failed != null) return failed;
    invitations[invitation.code] = invitation.markRevoked();
    events.add(event);
    writes++;
    _notify();
    return const Success<void>(null);
  }

  @override
  Future<Result<Member?>> getMember(String familyId, String uid) async =>
      Success(members[familyId]?[uid]);

  List<Member> _live0(String familyId) => [
        for (final m in (members[familyId] ?? const <String, Member>{}).values)
          if (!m.isRemoved) m,
      ];

  @override
  Future<Result<List<Member>>> getMembers(String familyId) async =>
      Success(_live0(familyId));

  @override
  Future<Result<void>> saveMembers(
    String familyId,
    List<Member> updated,
    FamilyEvent event,
  ) async {
    for (final m in updated) {
      members[familyId]![m.uid] = m;
    }
    events.add(event);
    writes++;
    _notify();
    return const Success<void>(null);
  }

  @override
  Future<Result<void>> updateFamily(Family family, FamilyEvent event) async {
    families[family.id] = family;
    events.add(event);
    writes++;
    _notify();
    return const Success<void>(null);
  }

  @override
  Stream<List<Member>> watchMembers(String familyId) =>
      _liveList(() => _live0(familyId));

  @override
  Stream<List<Invitation>> watchInvitations(String familyId) => _liveList(
        () => [
          for (final i in invitations.values)
            if (i.familyId == familyId) i,
        ],
      );

  @override
  Stream<Family?> watchFamily(String familyId) =>
      _liveList<Family?>(() => [families[familyId]]).map((l) => l.first);

  // ── Membership and module flags ───────────────────────────────────────────

  @override
  Stream<Membership> watchMembership(String uid) => _live(() {
        final fid = userFamily[uid];
        final m = fid == null ? null : members[fid]?[uid];
        if (fid == null || m == null || m.isRemoved) return Membership.none;
        return Membership(status: m.status, familyId: fid, role: m.role);
      });

  @override
  Stream<ModuleFlags> watchModuleFlags(String familyId) =>
      _live(() => families[familyId]?.modules ?? ModuleFlags.allOn);

  Future<void> dispose() => _changes.close();
}
