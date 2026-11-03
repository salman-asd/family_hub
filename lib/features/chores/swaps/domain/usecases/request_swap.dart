import 'package:family_hub/core/audit/audit_event_type.dart';
import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/core/permissions/permissions.dart';
import 'package:family_hub/core/utils/clock.dart';
import 'package:family_hub/core/utils/id_generator.dart';
import 'package:family_hub/features/chores/availability/domain/availability_index.dart';
import 'package:family_hub/features/chores/availability/domain/availability_repository.dart';
import 'package:family_hub/features/chores/comments/domain/comment_loader.dart';
import 'package:family_hub/features/chores/occurrences/domain/occurrence_write_plan.dart';
import 'package:family_hub/features/chores/occurrences/domain/usecases/occurrence_action_writer.dart';
import 'package:family_hub/features/chores/occurrences/domain/usecases/occurrence_action.dart';
import 'package:family_hub/features/chores/swaps/domain/swap_plan_helpers.dart';
import 'package:family_hub/features/chores/swaps/domain/swap_repository.dart';
import 'package:family_hub/features/chores/swaps/domain/swap_request.dart';
import 'package:family_hub/features/chores/swaps/domain/swap_rules.dart';
import 'package:family_hub/features/chores/swaps/domain/swap_write_plan.dart';
import 'package:family_hub/features/notifications/domain/inbox_port.dart';

/// Asks another member to take one of MY chores (P3-26).
///
/// Requires `settings.swapsEnabled`, a chore nobody has started, a recipient who
/// is active, not me and not away that day, and no other pending request for the
/// same chore. `expiresAt` = due time minus the family's buffer. The chore does
/// NOT change until the recipient accepts. A projected chore is materialized in
/// the same batch (D-P3-6). EVERYDAY write: it queues offline.
///
/// The caller generates [requestId] once per intent, so a retry rewrites the
/// same request.
class RequestSwap {
  const RequestSwap({
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
    required String occurrenceId,
    required String requestId,
    required String toMemberId,
    required String reason,
  }) async {
    final validated = requireReason(reason);
    final invalid = validated.failureOrNull;
    if (invalid != null) return Failure<SwapRequest>(invalid);
    final note = validated.valueOrNull!;

    final loaded = await loader.load(
      familyId: familyId,
      actorUid: actorUid,
      occurrenceId: occurrenceId,
    );
    final loadFailure = loaded.failureOrNull;
    if (loadFailure != null) return Failure<SwapRequest>(loadFailure);
    final context = loaded.valueOrNull!;
    final occurrence = context.occurrence;
    final denied = context
        .require(Permission.requestSwap, ownerId: occurrence.assigneeId)
        .failureOrNull;
    if (denied != null) return Failure<SwapRequest>(denied);

    final settings = (await loader.choreSettings.get(familyId)).valueOrNull;
    if (settings == null || !settings.swapsEnabled) {
      return const Failure<SwapRequest>(Conflict(code: 'swaps_disabled'));
    }
    if (!isUnstarted(occurrence)) {
      return const Failure<SwapRequest>(Conflict(code: 'occurrence_started'));
    }
    if (toMemberId == actorUid) {
      return const Failure<SwapRequest>(Validation('toMemberId', 'member_required'));
    }
    final target = (await loader.families.getMember(familyId, toMemberId)).valueOrNull;
    if (target == null || !target.isActive) {
      return const Failure<SwapRequest>(Validation('toMemberId', 'member_required'));
    }
    final records = await availability.listActive(familyId, occurrence.dateKey);
    final recordsFailure = records.failureOrNull;
    if (recordsFailure != null) return Failure<SwapRequest>(recordsFailure);
    final index = AvailabilityIndex.fromRecords(records.valueOrNull!);
    if (index.isUnavailable(toMemberId, occurrence.dateKey)) {
      return const Failure<SwapRequest>(Conflict(code: 'member_unavailable'));
    }
    final pending = await swaps.listPendingForOccurrence(familyId, occurrenceId);
    final pendingFailure = pending.failureOrNull;
    if (pendingFailure != null) return Failure<SwapRequest>(pendingFailure);
    if (pending.valueOrNull!.any((r) => r.id != requestId)) {
      return const Failure<SwapRequest>(Conflict(code: 'swap_not_pending'));
    }

    final at = clock.nowUtc();
    final expiresAt = swapExpiry(occurrence, settings.swapExpiryBufferMinutes);
    if (!expiresAt.isAfter(at)) {
      return const Failure<SwapRequest>(Conflict(code: 'swap_expired'));
    }
    final date = occurrence.dateKey.toString();
    final row = inbox.swapRequested(
      requestId: requestId,
      toMemberId: toMemberId,
      choreName: occurrence.nameBn,
      dateKey: date,
      fromMemberId: actorUid,
      cover: false,
    );
    final base = OccurrenceActionWriter.planFor(
      context: context,
      at: at,
      patch: null,
      newId: newId,
    );
    final plan = extendPlan(
      base,
      inbox: <NewInboxItem>[?row?.withId('ib_req_$requestId')],
      audits: <NewAudit>[
        swapAudit(
          type: AuditEventType.choresSwapRequested,
          id: 'au_req_$requestId',
          requestId: requestId,
          name: occurrence.nameBn,
          date: date,
          from: actorUid,
          to: toMemberId,
        ),
      ],
    );
    final staged = await swaps.stage(
      familyId,
      SwapWritePlan(
        occurrence: plan,
        creates: <NewSwap>[
          NewSwap(
            id: requestId,
            occurrenceId: occurrenceId,
            occurrenceDateKey: occurrence.dateKey,
            kind: SwapKind.swap,
            fromMemberId: actorUid,
            toMemberId: toMemberId,
            reason: note,
            expiresAt: expiresAt,
          ),
        ],
      ),
      integrity: false,
    );
    final writeFailure = staged.failureOrNull;
    if (writeFailure != null) return Failure<SwapRequest>(writeFailure);
    return Success<SwapRequest>(
      SwapRequest(
        id: requestId,
        occurrenceId: occurrenceId,
        occurrenceDateKey: occurrence.dateKey,
        kind: SwapKind.swap,
        fromMemberId: actorUid,
        toMemberId: toMemberId,
        reason: note,
        status: SwapStatus.pending,
        expiresAt: expiresAt,
        requestedBy: actorUid,
      ),
    );
  }
}
