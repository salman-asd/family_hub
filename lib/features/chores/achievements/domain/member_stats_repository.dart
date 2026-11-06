import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/features/chores/achievements/domain/member_stats.dart';
import 'package:family_hub/features/chores/achievements/domain/public_stats.dart';

abstract interface class MemberStatsRepository {
  Stream<MemberStats?> watch(
    String familyId,
    String memberId, {
    required DateKey defaultStartedOn,
  });

  Future<Result<MemberStats?>> get(
    String familyId,
    String memberId, {
    required DateKey defaultStartedOn,
  });

  /// Atomically writes private stats and mirrors or removes the public card.
  Future<Result<void>> save(
    String familyId,
    String memberId,
    MemberStats stats, {
    required PublicStats? publicStats,
  });

  /// Atomically claims the one celebration allowed for [dateKey].
  ///
  /// Returns false when another session has already claimed this date.
  Future<Result<bool>> claimCelebration(
    String familyId,
    String memberId, {
    required DateKey dateKey,
    required DateKey defaultStartedOn,
  });
}
