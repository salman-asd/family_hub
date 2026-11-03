import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/features/chores/availability/domain/availability_repository.dart';
import 'package:family_hub/features/chores/availability/domain/availability_write_plan.dart';
import 'package:family_hub/features/chores/availability/domain/member_availability.dart';

/// The default [AvailabilityRepository]: nobody is away and nothing can be
/// written. `bootstrap.dart` overrides it with Firestore; a screen test that
/// does not care about absences simply gets "no absences" (the behaviour before
/// P3-26) instead of an unwired-provider error.
final class NoAvailabilityRepository implements AvailabilityRepository {
  const NoAvailabilityRepository();

  @override
  Stream<List<MemberAvailability>> watchLive(String familyId, DateKey since) =>
      Stream<List<MemberAvailability>>.value(const <MemberAvailability>[]);

  @override
  Future<Result<MemberAvailability?>> get(String familyId, String id) async =>
      const Success<MemberAvailability?>(null);

  @override
  Future<Result<List<MemberAvailability>>> listLiveFor(
    String familyId,
    String memberId,
  ) async => const Success<List<MemberAvailability>>(<MemberAvailability>[]);

  @override
  Future<Result<List<MemberAvailability>>> listActive(
    String familyId,
    DateKey since,
  ) async => const Success<List<MemberAvailability>>(<MemberAvailability>[]);

  @override
  Future<Result<void>> stage(
    String familyId,
    AvailabilityWritePlan plan, {
    required bool integrity,
  }) async => const Failure<void>(Unknown('availability repository not wired'));
}
