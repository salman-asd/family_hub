import 'package:family_hub/core/audit/audit_event_type.dart';
import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/core/utils/clock.dart';
import 'package:family_hub/core/utils/id_generator.dart';
import 'package:family_hub/features/chores/availability/domain/availability_index.dart';
import 'package:family_hub/features/chores/availability/domain/availability_repository.dart';
import 'package:family_hub/features/chores/comments/domain/comment_loader.dart';
import 'package:family_hub/features/chores/occurrences/domain/occurrence_parts.dart';
import 'package:family_hub/features/chores/occurrences/domain/occurrence_write_plan.dart';
import 'package:family_hub/features/chores/occurrences/domain/usecases/occurrence_action_writer.dart';
import 'package:family_hub/features/chores/swaps/domain/swap_plan_helpers.dart';
import 'package:family_hub/features/chores/swaps/domain/swap_repository.dart';
import 'package:family_hub/features/chores/swaps/domain/swap_request.dart';
import 'package:family_hub/features/chores/swaps/domain/swap_rules.dart';
import 'package:family_hub/features/chores/swaps/domain/swap_write_plan.dart';
import 'package:family_hub/features/notifications/domain/inbox_port.dart';

/// The recipient accepts a swap or cover request (P3-26).
///
/// ONE batch (INTEGRITY: the server is required, so two offline phones cannot
/// both win): the request becomes `accepted`, the occurrence moves to the
/// recipient (`assigneeId`, `assignmentSource` swap|cover, `coverForId` for a
/// cover, `needsCover` false), the `swapped|covered` event carries the request
/// id, the ORIGINAL assignee and the reason, and the requester gets a
/// `swap_result` inbox row. `plannedAssigneeId` never changes, so the rotation
/// of every later day is untouched.
///
/// Checked in order: the request exists and the actor is its recipient
/// (`not_a_recipient`), it is pending (`swap_not_pending`), not expired
/// (`swap_expired`), the chore still belongs to the requester
/// (`concurrent_edit`), nobody has started it (`occurrence_started`) and the
/// recipient is not away that day (`member_unavailable`). The rules repeat the
/// pairing with `getAfter`; a second accept of the same request is denied
/// because the stored request is no longer pending.
class AcceptSwap {
  const AcceptSwap({
    required this.loader,
    required this.swaps,
    required this.availability,
    required this.clock,
    this.inbox = const NoopInboxPort(),
    this.newId = randomId,
  });

  final CommentLoader loader;
  final SwapRepository swaps;
  final AvailabilityRepository availability;
  final Clock clock;
  final InboxPort inbox;
  final IdGenerator newId;

  Future<Result<SwapRequest>> call({
    required String familyId,
    required String actorUid,
    required String requestId,
  }) async {
    final found = await swaps.get(familyId, requestId);
    final readFailure = found.failureOrNull;
    if (readFailure != null) return Failure<SwapRequest>(readFailure);
    final request = found.valueOrNull;
    if (request == null) {
      return const Failure<SwapRequest>(NotFound(entity: 'swapRequest'));
    }
    if (request.toMemberId != actorUid) {
      return const Failure<SwapRequest>(Conflict(code: 'not_a_recipient'));
    }
    if (!request.isPending) {
      return const Failure<SwapRequest>(Conflict(code: 'swap_not_pending'));
    }
    final at = clock.nowUtc();
    if (request.isExpiredAt(at)) {
      return const Failure<SwapRequest>(Conflict(code: 'swap_expired'));
    }

    final loaded = await loader.load(
      familyId: familyId,
      actorUid: actorUid,
      occurrenceId: request.occurrenceId,
    );
    final loadFailure = loaded.failureOrNull;
    if (loadFailure != null) return Failure<SwapRequest>(loadFailure);
    final context = loaded.valueOrNull!;
    if (!context.member.isActive) {
      return const Failure<SwapRequest>(PermissionDenied());
    }
    final occurrence = context.occurrence;
    if (occurrence.assigneeId != request.fromMemberId) {
      return const Failure<SwapRequest>(Conflict(code: 'concurrent_edit'));
    }
    if (!isUnstarted(occurrence)) {
      return const Failure<SwapRequest>(Conflict(code: 'occurrence_started'));
    }
    final records = await availability.listActive(familyId, occurrence.dateKey);
    final recordsFailure = records.failureOrNull;
    if (recordsFailure != null) return Failure<SwapRequest>(recordsFailure);
    final index = AvailabilityIndex.fromRecords(records.valueOrNull!);
    if (index.isUnavailable(actorUid, occurrence.dateKey)) {
      return const Failure<SwapRequest>(Conflict(code: 'member_unavailable'));
    }

    final cover = request.kind == SwapKind.cover;
    final date = occurrence.dateKey.toString();
    final base = OccurrenceActionWriter.planFor(
      context: context,
      at: at,
      patch: OccurrencePatch(
        occurrenceId: occurrence.id,
        fields: <String, Object?>{
          'assigneeId': actorUid,
          'coverForId': cover ? request.fromMemberId : null,
          'assignmentSource':
              (cover ? AssignmentSource.cover : AssignmentSource.swap).id,
          'needsCover': false,
        },
      ),
      event: NewEvent(
        occurrenceId: occurrence.id,
        type: cover ? OccurrenceEventType.covered : OccurrenceEventType.swapped,
        reason: request.reason,
        fromAssigneeId: request.fromMemberId,
        toAssigneeId: actorUid,
        requestId: request.id,
      ),
      newId: newId,
    );
    final row = inbox.swapResult(
      requestId: request.id,
      toMemberId: request.requestedBy,
      choreName: occurrence.nameBn,
      dateKey: date,
      outcome: 'accepted',
      byMemberId: actorUid,
    );
    final plan = extendPlan(
      base,
      inbox: <NewInboxItem>[?row?.withId('ib_acc_${request.id}')],
      audits: <NewAudit>[
        swapAudit(
          type: AuditEventType.choresSwapAccepted,
          id: 'au_acc_${request.id}',
          requestId: request.id,
          name: occurrence.nameBn,
          date: date,
          from: request.fromMemberId,
          to: actorUid,
        ),
      ],
    );
    final staged = await swaps.stage(
      familyId,
      SwapWritePlan(
        occurrence: plan,
        changes: <SwapChange>[
          SwapChange(requestId: request.id, status: SwapStatus.accepted),
        ],
      ),
      integrity: true,
    );
    final writeFailure = staged.failureOrNull;
    if (writeFailure != null) return Failure<SwapRequest>(writeFailure);
    return Success<SwapRequest>(
      request.withStatus(SwapStatus.accepted, by: actorUid, at: at),
    );
  }
}
