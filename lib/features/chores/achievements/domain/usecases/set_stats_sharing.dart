import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/features/chores/achievements/domain/engagement_settings.dart';
import 'package:family_hub/features/chores/achievements/domain/member_stats.dart';
import 'package:family_hub/features/chores/achievements/domain/member_stats_repository.dart';
import 'package:family_hub/features/chores/achievements/domain/public_stats.dart';
import 'package:family_hub/features/family/domain/family_repository.dart';
import 'package:family_hub/features/family/domain/permission_access.dart';

final class SetStatsSharing {
  const SetStatsSharing({required this.families, required this.stats});

  final FamilyRepository families;
  final MemberStatsRepository stats;

  Future<Result<void>> call({
    required String familyId,
    required String memberId,
    required bool sharing,
    required EngagementSettings settings,
  }) async {
    final active = await requireActiveMember(
      families,
      familyId: familyId,
      actorUid: memberId,
    );
    final activeFailure = active.failureOrNull;
    if (activeFailure != null) return Failure<void>(activeFailure);
    if (settings.statsVisibility != StatsVisibility.levels) {
      return const Failure<void>(Validation('sharing', 'sharing_not_allowed'));
    }
    final loaded = await stats.get(
      familyId,
      memberId,
      defaultStartedOn: settings.startedOn,
    );
    final loadFailure = loaded.failureOrNull;
    if (loadFailure != null) return Failure<void>(loadFailure);
    final previous =
        loaded.valueOrNull ?? MemberStats.empty(startedOn: settings.startedOn);
    if (previous.sharing == sharing) return const Success<void>(null);
    if (loaded.valueOrNull == null) {
      final initialized = await stats.save(
        familyId,
        memberId,
        previous,
        publicStats: null,
      );
      final initializeFailure = initialized.failureOrNull;
      if (initializeFailure != null) return Failure<void>(initializeFailure);
    }
    final updated = previous.copyWith(sharing: sharing);
    return stats.save(
      familyId,
      memberId,
      updated,
      publicStats: sharing
          ? PublicStats(
              level: updated.level,
              badgeIds: List<String>.unmodifiable(updated.badges.keys),
            )
          : null,
    );
  }
}
