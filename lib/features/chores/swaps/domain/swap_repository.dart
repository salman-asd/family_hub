import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/features/chores/swaps/domain/swap_request.dart';
import 'package:family_hub/features/chores/swaps/domain/swap_write_plan.dart';

/// Port for `swapRequests` (P3-26).
///
/// Reads are bounded by `kMaxSwapDocs`. A write is ONE batch through [stage]
/// (request + occurrence + event + inbox + audit); [integrity] makes it probe
/// the server first (accept, decline, cancel, expire, cover requests), because
/// two offline devices must not both "accept" (road map 3.4).
abstract interface class SwapRepository {
  /// Pending requests of the family (to me / from me / all for a manager is an
  /// in-memory filter, D-P3-8), newest first.
  Stream<List<SwapRequest>> watchPending(String familyId);

  Future<Result<SwapRequest?>> get(String familyId, String requestId);

  /// Pending requests of one chore (duplicate check).
  Future<Result<List<SwapRequest>>> listPendingForOccurrence(
    String familyId,
    String occurrenceId,
  );

  /// Every pending request of the family (policy B duplicate check).
  Future<Result<List<SwapRequest>>> listPending(String familyId);

  /// Pending requests whose `expiresAt` is at or before [now].
  Future<Result<List<SwapRequest>>> listExpired(String familyId, DateTime now);

  Future<Result<void>> stage(
    String familyId,
    SwapWritePlan plan, {
    required bool integrity,
  });
}
