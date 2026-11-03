import 'package:family_hub/core/utils/clock_provider.dart';
import 'package:family_hub/features/chores/availability/domain/availability_repository.dart';
import 'package:family_hub/features/chores/availability/domain/member_availability.dart';
import 'package:family_hub/features/chores/availability/domain/no_availability_repository.dart';
import 'package:family_hub/features/chores/availability/domain/usecases/add_availability.dart';
import 'package:family_hub/features/chores/availability/domain/usecases/apply_absence_policy.dart';
import 'package:family_hub/features/chores/availability/domain/usecases/cancel_availability.dart';
import 'package:family_hub/features/chores/availability/domain/usecases/decide_availability.dart';
import 'package:family_hub/features/chores/occurrences/presentation/inbox_port_provider.dart';
import 'package:family_hub/features/chores/occurrences/presentation/occurrence_providers.dart';
import 'package:family_hub/features/chores/settings/presentation/chore_settings_providers.dart';
import 'package:family_hub/features/chores/swaps/presentation/swap_providers.dart';
import 'package:family_hub/features/family/presentation/family_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Overridden in `bootstrap.dart` and in tests; the default knows no absences.
final availabilityRepositoryProvider = Provider<AvailabilityRepository>(
  (ref) => const NoAvailabilityRepository(),
);

/// The live (pending or active) absences that end no earlier than a week ago:
/// ONE listener, bounded by `kMaxAvailabilityDocs`.
final availabilityProvider = StreamProvider<List<MemberAvailability>>((ref) {
  final familyId = ref.watch(currentFamilyIdProvider);
  if (familyId == null) return Stream.value(const <MemberAvailability>[]);
  final since = ref.watch(familyDateKeysProvider).today().addDays(-7);
  return ref.watch(availabilityRepositoryProvider).watchLive(familyId, since);
});

final addAvailabilityProvider = Provider<AddAvailability>(
  (ref) => AddAvailability(
    families: ref.watch(familyRepositoryProvider),
    choreSettings: ref.watch(choreSettingsRepositoryProvider),
    availability: ref.watch(availabilityRepositoryProvider),
    clock: ref.watch(clockProvider),
  ),
);

final cancelAvailabilityProvider = Provider<CancelAvailability>(
  (ref) => CancelAvailability(
    families: ref.watch(familyRepositoryProvider),
    availability: ref.watch(availabilityRepositoryProvider),
    clock: ref.watch(clockProvider),
  ),
);

final decideAvailabilityProvider = Provider<DecideAvailability>(
  (ref) => DecideAvailability(
    families: ref.watch(familyRepositoryProvider),
    availability: ref.watch(availabilityRepositoryProvider),
    clock: ref.watch(clockProvider),
    inbox: ref.watch(inboxPortProvider),
  ),
);

final applyAbsencePolicyProvider = Provider<ApplyAbsencePolicy>(
  (ref) => ApplyAbsencePolicy(
    families: ref.watch(familyRepositoryProvider),
    choreSettings: ref.watch(choreSettingsRepositoryProvider),
    availability: ref.watch(availabilityRepositoryProvider),
    occurrences: ref.watch(occurrenceRepositoryProvider),
    swaps: ref.watch(swapRepositoryProvider),
    clock: ref.watch(clockProvider),
    inbox: ref.watch(inboxPortProvider),
  ),
);
