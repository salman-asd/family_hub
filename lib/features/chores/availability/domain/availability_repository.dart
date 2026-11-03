import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/features/chores/availability/domain/availability_write_plan.dart';
import 'package:family_hub/features/chores/availability/domain/member_availability.dart';

/// Port for `memberAvailability` (P3-26). Reads are bounded by
/// `kMaxAvailabilityDocs`.
abstract interface class AvailabilityRepository {
  /// Records that are pending or active and end on or after [since]
  /// (`endDateKey >= since`), the input of `availabilityIndexProvider`.
  Stream<List<MemberAvailability>> watchLive(String familyId, DateKey since);

  Future<Result<MemberAvailability?>> get(String familyId, String id);

  /// The live (pending or active) records of one member.
  Future<Result<List<MemberAvailability>>> listLiveFor(
    String familyId,
    String memberId,
  );

  /// Active records ending on or after [since] (the index for a use case).
  Future<Result<List<MemberAvailability>>> listActive(
    String familyId,
    DateKey since,
  );

  Future<Result<void>> stage(
    String familyId,
    AvailabilityWritePlan plan, {
    required bool integrity,
  });
}
