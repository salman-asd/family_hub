import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/features/chores/swaps/domain/swap_repository.dart';
import 'package:family_hub/features/chores/swaps/domain/swap_request.dart';
import 'package:family_hub/features/chores/swaps/domain/swap_write_plan.dart';

/// The default [SwapRepository]: no requests, nothing can be written.
/// `bootstrap.dart` overrides it with Firestore; a screen test that does not
/// care about swaps gets "no requests" instead of an unwired-provider error.
final class NoSwapRepository implements SwapRepository {
  const NoSwapRepository();

  @override
  Stream<List<SwapRequest>> watchPending(String familyId) =>
      Stream<List<SwapRequest>>.value(const <SwapRequest>[]);

  @override
  Future<Result<SwapRequest?>> get(String familyId, String requestId) async =>
      const Success<SwapRequest?>(null);

  @override
  Future<Result<List<SwapRequest>>> listPendingForOccurrence(
    String familyId,
    String occurrenceId,
  ) async => const Success<List<SwapRequest>>(<SwapRequest>[]);

  @override
  Future<Result<List<SwapRequest>>> listPending(String familyId) async =>
      const Success<List<SwapRequest>>(<SwapRequest>[]);

  @override
  Future<Result<List<SwapRequest>>> listExpired(
    String familyId,
    DateTime now,
  ) async => const Success<List<SwapRequest>>(<SwapRequest>[]);

  @override
  Future<Result<void>> stage(
    String familyId,
    SwapWritePlan plan, {
    required bool integrity,
  }) async => const Failure<void>(Unknown('swap repository not wired'));
}
