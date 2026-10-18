import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/core/utils/clock.dart';
import 'package:family_hub/core/utils/id_generator.dart';
import 'package:family_hub/features/family/domain/family.dart';
import 'package:family_hub/features/family/domain/family_event.dart';
import 'package:family_hub/features/family/domain/family_repository.dart';
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
  })  : _families = families,
        _profiles = profiles,
        _clock = clock,
        _newId = newId;

  final FamilyRepository _families;
  final UserProfileRepository _profiles;
  final Clock _clock;
  final IdGenerator _newId;

  Future<Result<Family>> call({
    required String actorUid,
    required String name,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return const Failure<Family>(Validation('name', 'required'));
    }

    final profileResult = await _profiles.getProfile(actorUid);
    final failure = profileResult.failureOrNull;
    if (failure != null) return Failure<Family>(failure);
    final profile = profileResult.valueOrNull;
    if (profile == null) {
      return const Failure<Family>(Validation('profile', 'required'));
    }

    final family = Family(id: _newId(), name: trimmed);
    final owner = Member(
      uid: actorUid,
      role: MemberRole.admin,
      status: MembershipStatus.active,
      fullName: profile.fullName,
      nickname: profile.nickname,
      relationship: profile.relationship.name,
      spouseId: profile.spouseId,
      avatarKey: profile.avatarKey,
    );
    final event = FamilyEvent(
      id: _newId(),
      type: 'family.created',
      actorId: actorUid,
      summary: 'Family "$trimmed" created',
      refType: 'family',
      refId: family.id,
      at: _clock.nowUtc(),
    );

    final saved = await _families.createFamily(
      family: family,
      owner: owner,
      event: event,
    );
    final saveFailure = saved.failureOrNull;
    return saveFailure != null
        ? Failure<Family>(saveFailure)
        : Success<Family>(family);
  }
}
