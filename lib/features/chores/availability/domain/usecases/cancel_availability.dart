import 'package:family_hub/core/audit/audit_event_type.dart';
import 'package:family_hub/core/audit/audit_ref_type.dart';
import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/core/permissions/permissions.dart';
import 'package:family_hub/core/utils/clock.dart';
import 'package:family_hub/core/utils/id_generator.dart';
import 'package:family_hub/features/chores/availability/domain/availability_repository.dart';
import 'package:family_hub/features/chores/availability/domain/availability_write_plan.dart';
import 'package:family_hub/features/chores/availability/domain/member_availability.dart';
import 'package:family_hub/features/chores/occurrences/domain/occurrence_write_plan.dart';
import 'package:family_hub/features/chores/swaps/domain/swap_plan_helpers.dart';
import 'package:family_hub/features/family/domain/family_repository.dart';
import 'package:family_hub/features/family/domain/permission_access.dart';

/// Cancels a pending or active absence (P3-26): its owner
/// (`recordOwnAvailability`) or a manager (`manageAvailability`).
///
/// Cover requests that policy B already created are NOT withdrawn (a cover that
/// was accepted is a real assignment); they expire or can be cancelled one by
/// one. EVERYDAY write.
class CancelAvailability {
  const CancelAvailability({
    required this.families,
    required this.availability,
    required this.clock,
    this.newId = randomId,
  });

  final FamilyRepository families;
  final AvailabilityRepository availability;
  final Clock clock;
  final IdGenerator newId;

  Future<Result<MemberAvailability>> call({
    required String familyId,
    required String actorUid,
    required String availabilityId,
  }) async {
    final loaded = await loadActiveActor(families, familyId, actorUid);
    final actorFailure = loaded.failureOrNull;
    if (actorFailure != null) return Failure<MemberAvailability>(actorFailure);
    final actor = loaded.valueOrNull!;

    final found = await availability.get(familyId, availabilityId);
    final readFailure = found.failureOrNull;
    if (readFailure != null) return Failure<MemberAvailability>(readFailure);
    final record = found.valueOrNull;
    if (record == null) {
      return const Failure<MemberAvailability>(
        NotFound(entity: 'availability'),
      );
    }
    final own = actorUid == record.memberId;
    final denied = checkPermission(
      actor.member,
      own ? Permission.recordOwnAvailability : Permission.manageAvailability,
      settings: actor.settings,
      ownerId: record.memberId,
    ).failureOrNull;
    if (denied != null) return Failure<MemberAvailability>(denied);
    if (!record.isLive) {
      return const Failure<MemberAvailability>(
        Conflict(code: 'concurrent_edit'),
      );
    }

    final at = clock.nowUtc();
    final staged = await availability.stage(
      familyId,
      AvailabilityWritePlan(
        occurrence: OccurrenceWritePlan(
          actorId: actorUid,
          at: at,
          audits: <NewAudit>[
            NewAudit(
              id: newId(),
              type: AuditEventType.choresAvailabilityCancelled,
              refType: AuditRefType.availability,
              refId: availabilityId,
              params: <String, String>{
                'member': record.memberId,
                'from': record.startDate.toString(),
                'to': record.endDate.toString(),
              },
            ),
          ],
        ),
        changes: <AvailabilityChange>[
          AvailabilityChange(
            availabilityId: availabilityId,
            status: AvailabilityStatus.cancelled,
          ),
        ],
      ),
      integrity: false,
    );
    final writeFailure = staged.failureOrNull;
    if (writeFailure != null) return Failure<MemberAvailability>(writeFailure);
    return Success<MemberAvailability>(
      record.withStatus(AvailabilityStatus.cancelled, by: actorUid, at: at),
    );
  }
}
