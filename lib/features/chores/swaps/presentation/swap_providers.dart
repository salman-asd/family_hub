import 'package:family_hub/core/utils/clock_provider.dart';
import 'package:family_hub/features/chores/availability/presentation/availability_providers.dart';
import 'package:family_hub/features/chores/comments/presentation/comment_providers.dart';
import 'package:family_hub/features/chores/occurrences/presentation/inbox_port_provider.dart';
import 'package:family_hub/features/chores/occurrences/presentation/occurrence_providers.dart';
import 'package:family_hub/features/chores/settings/presentation/chore_settings_providers.dart';
import 'package:family_hub/features/chores/swaps/domain/swap_repository.dart';
import 'package:family_hub/features/chores/swaps/domain/swap_request.dart';
import 'package:family_hub/features/chores/swaps/domain/usecases/accept_swap.dart';
import 'package:family_hub/features/chores/swaps/domain/usecases/cancel_swap.dart';
import 'package:family_hub/features/chores/swaps/domain/usecases/decline_swap.dart';
import 'package:family_hub/features/chores/swaps/domain/usecases/expire_swaps.dart';
import 'package:family_hub/features/chores/swaps/domain/usecases/request_swap.dart';
import 'package:family_hub/features/family/presentation/family_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Overridden in `bootstrap.dart` and in tests.
final swapRepositoryProvider = Provider<SwapRepository>(
  (ref) => throw UnimplementedError(
    'swapRepositoryProvider must be overridden (bootstrap.dart / tests).',
  ),
);

/// Every pending request of the family: ONE listener. "To me / from me / all
/// for a manager" is an in-memory filter (D-P3-8).
final pendingSwapsProvider = StreamProvider.autoDispose<List<SwapRequest>>((
  ref,
) {
  final familyId = ref.watch(currentFamilyIdProvider);
  if (familyId == null) return Stream.value(const <SwapRequest>[]);
  return ref.watch(swapRepositoryProvider).watchPending(familyId);
});

/// Requests waiting for ME to answer.
final swapsForMeProvider = Provider.autoDispose<List<SwapRequest>>((ref) {
  final uid = ref.watch(currentUidProvider);
  final all = ref.watch(pendingSwapsProvider).value ?? const <SwapRequest>[];
  return <SwapRequest>[
    for (final request in all)
      if (request.toMemberId == uid) request,
  ];
});

final requestSwapProvider = Provider<RequestSwap>(
  (ref) => RequestSwap(
    loader: ref.watch(commentLoaderProvider),
    swaps: ref.watch(swapRepositoryProvider),
    availability: ref.watch(availabilityRepositoryProvider),
    clock: ref.watch(clockProvider),
    inbox: ref.watch(inboxPortProvider),
  ),
);

final acceptSwapProvider = Provider<AcceptSwap>(
  (ref) => AcceptSwap(
    loader: ref.watch(commentLoaderProvider),
    swaps: ref.watch(swapRepositoryProvider),
    availability: ref.watch(availabilityRepositoryProvider),
    clock: ref.watch(clockProvider),
    inbox: ref.watch(inboxPortProvider),
  ),
);

final declineSwapProvider = Provider<DeclineSwap>(
  (ref) => DeclineSwap(
    families: ref.watch(familyRepositoryProvider),
    swaps: ref.watch(swapRepositoryProvider),
    availability: ref.watch(availabilityRepositoryProvider),
    occurrences: ref.watch(occurrenceRepositoryProvider),
    choreSettings: ref.watch(choreSettingsRepositoryProvider),
    clock: ref.watch(clockProvider),
    inbox: ref.watch(inboxPortProvider),
  ),
);

final cancelSwapProvider = Provider<CancelSwap>(
  (ref) => CancelSwap(
    families: ref.watch(familyRepositoryProvider),
    swaps: ref.watch(swapRepositoryProvider),
    occurrences: ref.watch(occurrenceRepositoryProvider),
    clock: ref.watch(clockProvider),
    inbox: ref.watch(inboxPortProvider),
  ),
);

final expireSwapsProvider = Provider<ExpireSwaps>(
  (ref) => ExpireSwaps(
    families: ref.watch(familyRepositoryProvider),
    swaps: ref.watch(swapRepositoryProvider),
    availability: ref.watch(availabilityRepositoryProvider),
    occurrences: ref.watch(occurrenceRepositoryProvider),
    choreSettings: ref.watch(choreSettingsRepositoryProvider),
    clock: ref.watch(clockProvider),
    inbox: ref.watch(inboxPortProvider),
  ),
);
