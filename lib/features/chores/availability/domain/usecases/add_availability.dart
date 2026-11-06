import 'package:family_hub/core/audit/audit_event_type.dart';
import 'package:family_hub/core/audit/audit_ref_type.dart';
import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/core/permissions/permissions.dart';
import 'package:family_hub/core/utils/clock.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/core/utils/id_generator.dart';
import 'package:family_hub/features/chores/availability/domain/availability_repository.dart';
import 'package:family_hub/features/chores/availability/domain/availability_write_plan.dart';
import 'package:family_hub/features/chores/availability/domain/member_availability.dart';
import 'package:family_hub/features/chores/occurrences/domain/occurrence_write_plan.dart';
import 'package:family_hub/features/chores/settings/domain/chore_settings_repository.dart';
import 'package:family_hub/features/chores/swaps/domain/swap_plan_helpers.dart';
import 'package:family_hub/features/family/domain/family_repository.dart';
import 'package:family_hub/features/family/domain/permission_access.dart';

/// Records an absence (P3-26).
///
/// A member records their OWN absence (`recordOwnAvailability`); a manager may
/// record anybody's (`manageAvailability`). Checked: the range is valid and at
/// most 366 days (`range_too_large`), no live record of the same member overlaps
/// (`availability_overlap`), the type is one of the family's absence reasons,
/// the reason has 3-200 characters and the member is active.
///
/// The record is `active`, or `pending` when the family asks for approval and the
/// author is not a manager. Afterwards the caller runs `ApplyAbsencePolicy` for
/// an active record. EVERYDAY write (queues offline). [availabilityId] is made
/// once per intent.
class AddAvailability {
  const AddAvailability({
    required this.families,
    required this.choreSettings,
    required this.availability,
    required this.clock,
    this.newId = randomId,
  });

  final FamilyRepository families;
  final ChoreSettingsRepository choreSettings;
  final AvailabilityRepository availability;
  final Clock clock;
  final IdGenerator newId;

  Future<Result<MemberAvailability>> call({
    required String familyId,
    required String actorUid,
    required String availabilityId,
    required String memberId,
    required DateKey startDate,
    required DateKey endDate,
    required String typeId,
    required String reason,
  }) async {
    final loaded = await loadActiveActor(families, familyId, actorUid);
    final actorFailure = loaded.failureOrNull;
    if (actorFailure != null) return Failure<MemberAvailability>(actorFailure);
    final actor = loaded.valueOrNull!;
    final own = actorUid == memberId;
    final denied = checkPermission(
      actor.member,
      own ? Permission.recordOwnAvailability : Permission.manageAvailability,
      settings: actor.settings,
      ownerId: memberId,
    ).failureOrNull;
    if (denied != null) return Failure<MemberAvailability>(denied);

    final validated = AvailabilityLimits.reason(reason);
    final invalid = validated.failureOrNull;
    if (invalid != null) return Failure<MemberAvailability>(invalid);
    final note = validated.valueOrNull!;
    if (endDate.isBefore(startDate)) {
      return const Failure<MemberAvailability>(
        Validation('range', 'invalid_range'),
      );
    }
    if (availabilityDays(startDate, endDate) > AvailabilityLimits.maxDays) {
      return const Failure<MemberAvailability>(
        Conflict(code: 'range_too_large'),
      );
    }

    final target = (await families.getMember(familyId, memberId)).valueOrNull;
    if (target == null || !target.isActive) {
      return const Failure<MemberAvailability>(NotFound(entity: 'member'));
    }
    final settings = (await choreSettings.get(familyId)).valueOrNull;
    if (settings == null ||
        !settings.absenceReasons.any((r) => r.id == typeId)) {
      return const Failure<MemberAvailability>(
        Validation('typeId', 'required'),
      );
    }
    final live = await availability.listLiveFor(familyId, memberId);
    final liveFailure = live.failureOrNull;
    if (liveFailure != null) return Failure<MemberAvailability>(liveFailure);
    if (live.valueOrNull!.any(
      (r) => r.id != availabilityId && r.overlaps(startDate, endDate),
    )) {
      return const Failure<MemberAvailability>(
        Conflict(code: 'availability_overlap'),
      );
    }

    final status =
        settings.absenceNeedsApproval && !actor.member.permissionActor.isManager
        ? AvailabilityStatus.pending
        : AvailabilityStatus.active;
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
              type: AuditEventType.choresAvailabilityAdded,
              refType: AuditRefType.availability,
              refId: availabilityId,
              params: <String, String>{
                'member': memberId,
                'from': startDate.toString(),
                'to': endDate.toString(),
                'status': status.id,
              },
            ),
          ],
        ),
        creates: <NewAvailability>[
          NewAvailability(
            id: availabilityId,
            memberId: memberId,
            startDate: startDate,
            endDate: endDate,
            typeId: typeId,
            reason: note,
            status: status,
          ),
        ],
      ),
      integrity: false,
    );
    final writeFailure = staged.failureOrNull;
    if (writeFailure != null) return Failure<MemberAvailability>(writeFailure);
    return Success<MemberAvailability>(
      MemberAvailability(
        id: availabilityId,
        memberId: memberId,
        startDate: startDate,
        endDate: endDate,
        typeId: typeId,
        reason: note,
        status: status,
        createdBy: actorUid,
      ),
    );
  }
}
