import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/features/chores/availability/domain/member_availability.dart';
import 'package:family_hub/features/chores/occurrences/domain/occurrence_write_plan.dart';
import 'package:family_hub/features/chores/swaps/domain/swap_write_plan.dart';

final class NewAvailability {
  const NewAvailability({
    required this.id,
    required this.memberId,
    required this.startDate,
    required this.endDate,
    required this.typeId,
    required this.reason,
    required this.status,
  });

  final String id;
  final String memberId;
  final DateKey startDate;
  final DateKey endDate;
  final String typeId;
  final String reason;
  final AvailabilityStatus status;
}

/// A status change (approve, reject, cancel).
final class AvailabilityChange {
  const AvailabilityChange({
    required this.availabilityId,
    required this.status,
  });

  final String availabilityId;
  final AvailabilityStatus status;
}

/// Everything ONE availability action writes, in ONE batch.
///
/// [occurrence] carries only inbox rows and audit entries here; [swaps] carries
/// the cover requests of policy B (so the requests, their inbox rows and the
/// audit trail land together).
final class AvailabilityWritePlan {
  const AvailabilityWritePlan({
    required this.occurrence,
    this.creates = const <NewAvailability>[],
    this.changes = const <AvailabilityChange>[],
    this.swaps = const <NewSwap>[],
  });

  final OccurrenceWritePlan occurrence;
  final List<NewAvailability> creates;
  final List<AvailabilityChange> changes;
  final List<NewSwap> swaps;

  String get actorId => occurrence.actorId;
  DateTime get at => occurrence.at;
}
