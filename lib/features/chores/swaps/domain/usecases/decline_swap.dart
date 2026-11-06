import 'package:family_hub/core/audit/audit_event_type.dart';
import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/core/utils/clock.dart';
import 'package:family_hub/features/chores/availability/domain/availability_index.dart';
import 'package:family_hub/features/chores/availability/domain/availability_repository.dart';
import 'package:family_hub/features/chores/occurrences/domain/occurrence_repository.dart';
import 'package:family_hub/features/chores/occurrences/domain/occurrence_write_plan.dart';
import 'package:family_hub/features/chores/settings/domain/chore_settings_repository.dart';
import 'package:family_hub/features/chores/swaps/domain/cover_fallback.dart';
import 'package:family_hub/features/chores/swaps/domain/swap_plan_helpers.dart';
import 'package:family_hub/features/chores/swaps/domain/swap_repository.dart';
import 'package:family_hub/features/chores/swaps/domain/swap_request.dart';
import 'package:family_hub/features/chores/swaps/domain/swap_write_plan.dart';
import 'package:family_hub/features/family/domain/family_repository.dart';
import 'package:family_hub/features/notifications/domain/inbox_port.dart';

/// The recipient declines (P3-26). The reason is optional (D-P3-17).
///
/// The chore does not change. The requester gets a `swap_result` row. When it
/// was a policy-B COVER request, the next candidate gets ONE request, and when
/// nobody is left the absent member and the managers get the policy-A
/// `needs_cover` row ([CoverFallback]). INTEGRITY write.
class DeclineSwap {
  const DeclineSwap({
    required this.families,
    required this.swaps,
    required this.availability,
    required this.occurrences,
    required this.choreSettings,
    required this.clock,
    this.inbox = const NoopInboxPort(),
  });

  final FamilyRepository families;
  final SwapRepository swaps;
  final AvailabilityRepository availability;
  final OccurrenceRepository occurrences;
  final ChoreSettingsRepository choreSettings;
  final Clock clock;
  final InboxPort inbox;

  Future<Result<SwapRequest>> call({
    required String familyId,
    required String actorUid,
    required String requestId,
    String? reason,
  }) async {
    final text = reason?.trim();
    if (text != null && text.length > SwapLimits.maxReason) {
      return const Failure<SwapRequest>(Validation('reason', 'too_long'));
    }
    final actor = await loadActiveActor(families, familyId, actorUid);
    final actorFailure = actor.failureOrNull;
    if (actorFailure != null) return Failure<SwapRequest>(actorFailure);

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
    final occurrence = (await occurrences.get(
      familyId,
      request.occurrenceId,
    )).valueOrNull;
    final name = occurrence?.nameBn ?? request.occurrenceId;
    final date = request.occurrenceDateKey.toString();

    var fallback = const CoverFallbackResult();
    final absenceId = request.availabilityId;
    if (request.kind == SwapKind.cover && absenceId != null) {
      final absence = (await availability.get(familyId, absenceId)).valueOrNull;
      final members =
          (await families.getMembers(familyId)).valueOrNull ?? const [];
      final records =
          (await availability.listActive(
            familyId,
            request.occurrenceDateKey,
          )).valueOrNull ??
          const [];
      final settings = (await choreSettings.get(familyId)).valueOrNull;
      fallback = CoverFallback.next(
        failed: request,
        occurrence: occurrence,
        absence: absence,
        members: members,
        index: AvailabilityIndex.fromRecords(records),
        bufferMinutes: settings?.swapExpiryBufferMinutes ?? 120,
        now: at,
        inbox: inbox,
      );
    }

    final row = inbox.swapResult(
      requestId: request.id,
      toMemberId: request.requestedBy,
      choreName: name,
      dateKey: date,
      outcome: 'declined',
      byMemberId: actorUid,
    );
    final plan = OccurrenceWritePlan(
      actorId: actorUid,
      at: at,
      inbox: <NewInboxItem>[
        ?row?.withId('ib_dec_${request.id}'),
        ...fallback.inbox,
      ],
      audits: <NewAudit>[
        swapAudit(
          type: AuditEventType.choresSwapDeclined,
          id: 'au_dec_${request.id}',
          requestId: request.id,
          name: name,
          date: date,
          from: request.fromMemberId,
          to: actorUid,
        ),
        ...fallback.audits,
      ],
    );
    final staged = await swaps.stage(
      familyId,
      SwapWritePlan(
        occurrence: plan,
        creates: fallback.swaps,
        changes: <SwapChange>[
          SwapChange(
            requestId: request.id,
            status: SwapStatus.declined,
            responseReason: text == null || text.isEmpty ? null : text,
          ),
        ],
      ),
      integrity: true,
    );
    final writeFailure = staged.failureOrNull;
    if (writeFailure != null) return Failure<SwapRequest>(writeFailure);
    return Success<SwapRequest>(
      request.withStatus(
        SwapStatus.declined,
        by: actorUid,
        at: at,
        responseReason: text,
      ),
    );
  }
}
