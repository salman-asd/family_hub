import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/features/activity/domain/activity_entry.dart';

/// Read-only access to the append-only family activity collection.
abstract interface class ActivityRepository {
  /// Watches the newest [limit] rows. Used by the dashboard card.
  Stream<List<ActivityEntry>> watchRecent(
    String familyId, {
    required int limit,
  });

  /// Watches page one; later pages must be one-shot reads.
  Stream<ActivityPage> watchFirstPage(
    String familyId, {
    String? actorId,
    required int limit,
  });

  /// Reads one bounded page older than [afterDocumentId].
  Future<Result<ActivityPage>> readOlderPage(
    String familyId, {
    String? actorId,
    required String afterDocumentId,
    required int limit,
  });
}
