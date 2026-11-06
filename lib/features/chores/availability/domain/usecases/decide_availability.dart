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
import 'package:family_hub/features/notifications/domain/inbox_port.dart';

/// A manager approves or rejects a PENDING absence (P3-26,
/// `manageAvailability`). The member gets an `absence_decision` row. After an
/// approval the caller runs `ApplyAbsencePolicy`. INTEGRITY write.
class DecideAvailability {
  const DecideAvailability({
    required this.families,
    required this.availability,
    required this.clock,
    this.inbox = const NoopInboxPort(),
    this.newId = randomId,
  });

  final FamilyRepository families;
  final AvailabilityRepository availability;
  final Clock clock;
  final InboxPort inbox;
  final IdGenerator newId;

  Future<Result<MemberAvailability>> call({
    required String familyId,
    required String actorUid,
    required String availabilityId,
    required bool approve,
  }) async {
    final loaded = await loadActiveActor(families, familyId, actorUid);
    final actorFailure = loaded.failureOrNull;
    if (actorFailure != null) return Failure<MemberAvailability>(actorFailure);
    final actor = loaded.valueOrNull!;
    final denied = checkPermission(
      actor.member,
      Permission.manageAvailability,
      settings: actor.settings,
    ).failureOrNull;
    if (denied != null) return Failure<MemberAvailability>(denied);

    final found = await availability.get(familyId, availabilityId);
    final readFailure = found.failureOrNull;
    if (readFailure != null) return Failure<MemberAvailability>(readFailure);
    final record = found.valueOrNull;
    if (record == null) {
      return const Failure<MemberAvailability>(
        NotFound(entity: 'availability'),
      );
    }
    if (record.status != AvailabilityStatus.pending) {
      return const Failure<MemberAvailability>(
        Conflict(code: 'concurrent_edit'),
      );
    }

    final next = approve
        ? AvailabilityStatus.active
        : AvailabilityStatus.rejected;
    final at = clock.nowUtc();
    final row = inbox.absenceDecision(
      availabilityId: availabilityId,
      toMemberId: record.memberId,
      status: next.id,
      byMemberId: actorUid,
    );
    final staged = await availability.stage(
      familyId,
      AvailabilityWritePlan(
        occurrence: OccurrenceWritePlan(
          actorId: actorUid,
          at: at,
          inbox: <NewInboxItem>[?row?.withId('ib_abs_$availabilityId')],
          audits: <NewAudit>[
            NewAudit(
              id: newId(),
              type: AuditEventType.choresAvailabilityDecided,
              refType: AuditRefType.availability,
              refId: availabilityId,
              params: <String, String>{
                'member': record.memberId,
                'from': record.startDate.toString(),
                'to': record.endDate.toString(),
                'status': next.id,
              },
            ),
          ],
        ),
        changes: <AvailabilityChange>[
          AvailabilityChange(availabilityId: availabilityId, status: next),
        ],
      ),
      integrity: true,
    );
    final writeFailure = staged.failureOrNull;
    if (writeFailure != null) return Failure<MemberAvailability>(writeFailure);
    return Success<MemberAvailability>(
      record.withStatus(next, by: actorUid, at: at),
    );
  }
}
