import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/features/chores/achievements/domain/public_stats.dart';

abstract interface class PublicStatsRepository {
  Stream<PublicStats?> watch(String familyId, String memberId);

  Future<Result<PublicStats?>> get(String familyId, String memberId);
}
