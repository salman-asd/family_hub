import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/features/chores/achievements/domain/engagement_settings.dart';
import 'package:family_hub/features/chores/achievements/domain/member_stats.dart';
import 'package:family_hub/features/chores/achievements/domain/member_stats_repository.dart';
import 'package:family_hub/features/family/domain/family_repository.dart';
import 'package:family_hub/features/family/domain/permission_access.dart';

final class MarkCelebrated {
  const MarkCelebrated({required this.families, required this.stats});

  final FamilyRepository families;
  final MemberStatsRepository stats;

  Future<Result<bool>> call({
    required String familyId,
    required String memberId,
    required DateKey dateKey,
    required DateKey today,
    required EngagementSettings settings,
  }) async {
    final active = await requireActiveMember(
      families,
      familyId: familyId,
      actorUid: memberId,
    );
    final activeFailure = active.failureOrNull;
    if (activeFailure != null) return Failure<bool>(activeFailure);
    if (dateKey.isAfter(today)) {
      return const Failure<bool>(Validation('dateKey', 'future_date'));
    }

    final loaded = await stats.get(
      familyId,
      memberId,
      defaultStartedOn: settings.startedOn,
    );
    final loadFailure = loaded.failureOrNull;
    if (loadFailure != null) return Failure<bool>(loadFailure);
    final previous =
        loaded.valueOrNull ?? MemberStats.empty(startedOn: settings.startedOn);
    if (loaded.valueOrNull == null) {
      final initialized = await stats.save(
        familyId,
        memberId,
        previous,
        publicStats: null,
      );
      final initializeFailure = initialized.failureOrNull;
      if (initializeFailure != null) return Failure<bool>(initializeFailure);
    }
    return stats.claimCelebration(
      familyId,
      memberId,
      dateKey: dateKey,
      defaultStartedOn: settings.startedOn,
    );
  }
}
