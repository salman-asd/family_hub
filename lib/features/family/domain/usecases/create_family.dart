import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/core/utils/clock.dart';
import 'package:family_hub/core/utils/id_generator.dart';
import 'package:family_hub/features/family/domain/ensure_free_to_join.dart';
import 'package:family_hub/features/family/domain/family.dart';
import 'package:family_hub/core/audit/audit_event.dart';
import 'package:family_hub/features/family/domain/family_repository.dart';
import 'package:family_hub/features/family/domain/family_seeder.dart';
import 'package:family_hub/features/family/domain/member.dart';
import 'package:family_hub/features/family/domain/member_role.dart';
import 'package:family_hub/features/family/domain/membership.dart';
import 'package:family_hub/features/onboarding/domain/user_profile_repository.dart';

/// Creates a family with the caller as its first, active admin — in ONE batch
/// (family, member, settings documents, user `familyId`, activity + audit).
class CreateFamily {
  const CreateFamily({
    required FamilyRepository families,
    required UserProfileRepository profiles,
    required Clock clock,
    required IdGenerator newId,
    List<FamilySeeder> seeders = const <FamilySeeder>[],
  })  : _families = families,
        _profiles = profiles,
        _clock = clock,
        _newId = newId,
        _seeders = seeders;

  final FamilyRepository _families;
  final UserProfileRepository _profiles;
  final Clock _clock;
  final IdGenerator _newId;

  /// Starter-data providers run inside the same batch (H12).
  final List<FamilySeeder> _seeders;

  /// [familyId] / [eventId] make a retry idempotent (rule 15): the screen
  /// generates them ONCE per user intent and passes the same values again on a
  /// second tap, so a write that was only queued cannot create a second family.
  Future<Result<Family>> call({
    required String actorUid,
    required String name,
    String? familyId,
    String? eventId,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return const Failure<Family>(Validation('name', 'required'));
    }

    // One family per user (rule 17).  A repeat of this same request (same
    // familyId) is answered idempotently instead of as a conflict.
    final free = await ensureFreeToJoinAnyFamily(
      _families,
      actorUid,
      allowFamilyId: familyId,
    );
    final freeFailure = free.failureOrNull;
    if (freeFailure != null) return Failure<Family>(freeFailure);
    final existing = free.valueOrNull!;
    if (existing.status == MembershipStatus.active &&
        familyId != null &&
        existing.familyId == familyId) {
      return Success<Family>(Family(id: familyId, name: trimmed));
    }

    final profileResult = await _profiles.getProfile(actorUid);
    final failure = profileResult.failureOrNull;
    if (failure != null) return Failure<Family>(failure);
    final profile = profileResult.valueOrNull;
    if (profile == null) {
      return const Failure<Family>(Validation('profile', 'required'));
    }

    final family = Family(id: familyId ?? _newId(), name: trimmed);
    final owner = Member(
      uid: actorUid,
      role: MemberRole.admin,
      status: MembershipStatus.active,
      fullName: profile.fullName,
      nickname: profile.nickname,
      relationship: profile.relationship.value,
      spouseId: profile.spouseId,
      avatarKey: profile.avatarKey,
    );
    final event = AuditEvent(
      id: eventId ?? _newId(),
      type: 'family.created',
      actorId: actorUid,
      params: <String, String>{'familyName': trimmed},
      refType: 'family',
      refId: family.id,
      at: _clock.nowUtc(),
    );

    final context = SeedContext(
      familyId: family.id,
      actorUid: actorUid,
      now: event.at,
    );
    final saved = await _families.createFamily(
      family: family,
      owner: owner,
      event: event,
      seedWrites: <SeedWrite>[
        for (final s in _seeders) ...s.seed(context),
      ],
    );
    final saveFailure = saved.failureOrNull;
    return saveFailure != null
        ? Failure<Family>(saveFailure)
        : Success<Family>(family);
  }
}
