import 'package:family_hub/core/audit/audit_event_type.dart';
import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/core/permissions/permissions.dart';
import 'package:family_hub/core/utils/clock.dart';
import 'package:family_hub/features/chores/occurrences/domain/occurrence_repository.dart';
import 'package:family_hub/features/chores/occurrences/domain/occurrence_write_plan.dart';
import 'package:family_hub/features/chores/swaps/domain/swap_plan_helpers.dart';
import 'package:family_hub/features/chores/swaps/domain/swap_repository.dart';
import 'package:family_hub/features/chores/swaps/domain/swap_request.dart';
import 'package:family_hub/features/chores/swaps/domain/swap_write_plan.dart';
import 'package:family_hub/features/family/domain/family_repository.dart';
import 'package:family_hub/features/family/domain/permission_access.dart';
import 'package:family_hub/features/notifications/domain/inbox_port.dart';

/// The requester, or a manager (`reassignChore`), withdraws a pending request
/// (P3-26). The recipient gets a `swap_result` row. INTEGRITY write.
class CancelSwap {
  const CancelSwap({
    required this.families,
    required this.swaps,
    required this.occurrences,
    required this.clock,
    this.inbox = const NoopInboxPort(),
  });

  final FamilyRepository families;
  final SwapRepository swaps;
  final OccurrenceRepository occurrences;
  final Clock clock;
  final InboxPort inbox;

  Future<Result<SwapRequest>> call({
    required String familyId,
    required String actorUid,
    required String requestId,
  }) async {
    final loaded = await loadActiveActor(families, familyId, actorUid);
    final actorFailure = loaded.failureOrNull;
    if (actorFailure != null) return Failure<SwapRequest>(actorFailure);
    final actor = loaded.valueOrNull!;

    final found = await swaps.get(familyId, requestId);
    final readFailure = found.failureOrNull;
    if (readFailure != null) return Failure<SwapRequest>(readFailure);
    final request = found.valueOrNull;
    if (request == null) {
      return const Failure<SwapRequest>(NotFound(entity: 'swapRequest'));
    }
    final isRequester =
        request.requestedBy == actorUid || request.fromMemberId == actorUid;
    if (!isRequester) {
      final denied = checkPermission(
        actor.member,
        Permission.reassignChore,
        settings: actor.settings,
      ).failureOrNull;
      if (denied != null) return Failure<SwapRequest>(denied);
    }
    if (!request.isPending) {
      return const Failure<SwapRequest>(Conflict(code: 'swap_not_pending'));
    }

    final at = clock.nowUtc();
    final occurrence =
        (await occurrences.get(familyId, request.occurrenceId)).valueOrNull;
    final name = occurrence?.nameBn ?? request.occurrenceId;
    final date = request.occurrenceDateKey.toString();
    final row = inbox.swapResult(
      requestId: request.id,
      toMemberId: request.toMemberId,
      choreName: name,
      dateKey: date,
      outcome: 'cancelled',
      byMemberId: actorUid,
    );
    final staged = await swaps.stage(
      familyId,
      SwapWritePlan(
        occurrence: OccurrenceWritePlan(
          actorId: actorUid,
          at: at,
          inbox: <NewInboxItem>[?row?.withId('ib_can_${request.id}')],
          audits: <NewAudit>[
            swapAudit(
              type: AuditEventType.choresSwapCancelled,
              id: 'au_can_${request.id}',
              requestId: request.id,
              name: name,
              date: date,
              from: request.fromMemberId,
              to: request.toMemberId,
            ),
          ],
        ),
        changes: <SwapChange>[
          SwapChange(requestId: request.id, status: SwapStatus.cancelled),
        ],
      ),
      integrity: true,
    );
    final writeFailure = staged.failureOrNull;
    if (writeFailure != null) return Failure<SwapRequest>(writeFailure);
    return Success<SwapRequest>(
      request.withStatus(SwapStatus.cancelled, by: actorUid, at: at),
    );
  }
}
