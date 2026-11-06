import 'package:family_hub/core/audit/audit_event_type.dart';
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

/// Marks every pending request past its `expiresAt` as `expired` (P3-26), on app
/// open, by any active member.
///
/// Each expiry informs the requester and writes an audit entry; an expired
/// COVER request goes through [CoverFallback] like a decline does. One batch
/// (at most `kMaxSwapDocs` requests). Idempotent: a second run finds nothing
/// pending past its time and writes nothing. Returns how many were expired.
class ExpireSwaps {
  const ExpireSwaps({
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

  Future<Result<int>> call({
    required String familyId,
    required String actorUid,
  }) async {
    final actor = await loadActiveActor(families, familyId, actorUid);
    final actorFailure = actor.failureOrNull;
    if (actorFailure != null) return Failure<int>(actorFailure);

    final at = clock.nowUtc();
    final listed = await swaps.listExpired(familyId, at);
    final listFailure = listed.failureOrNull;
    if (listFailure != null) return Failure<int>(listFailure);
    final due = listed.valueOrNull!;
    if (due.isEmpty) return const Success<int>(0);

    final members =
        (await families.getMembers(familyId)).valueOrNull ?? const [];
    final settings = (await choreSettings.get(familyId)).valueOrNull;
    final creates = <NewSwap>[];
    final changes = <SwapChange>[];
    final rows = <NewInboxItem>[];
    final audits = <NewAudit>[];
    for (final request in due) {
      final occurrence = (await occurrences.get(
        familyId,
        request.occurrenceId,
      )).valueOrNull;
      final name = occurrence?.nameBn ?? request.occurrenceId;
      final date = request.occurrenceDateKey.toString();
      changes.add(
        SwapChange(requestId: request.id, status: SwapStatus.expired),
      );
      final row = inbox.swapResult(
        requestId: request.id,
        toMemberId: request.requestedBy,
        choreName: name,
        dateKey: date,
        outcome: 'expired',
        byMemberId: actorUid,
      );
      if (row != null) rows.add(row.withId('ib_exp_${request.id}'));
      audits.add(
        swapAudit(
          type: AuditEventType.choresSwapExpired,
          id: 'au_exp_${request.id}',
          requestId: request.id,
          name: name,
          date: date,
          from: request.fromMemberId,
          to: request.toMemberId,
        ),
      );
      final absenceId = request.availabilityId;
      if (request.kind == SwapKind.cover && absenceId != null) {
        final absence = (await availability.get(
          familyId,
          absenceId,
        )).valueOrNull;
        final records =
            (await availability.listActive(
              familyId,
              request.occurrenceDateKey,
            )).valueOrNull ??
            const [];
        final next = CoverFallback.next(
          failed: request,
          occurrence: occurrence,
          absence: absence,
          members: members,
          index: AvailabilityIndex.fromRecords(records),
          bufferMinutes: settings?.swapExpiryBufferMinutes ?? 120,
          now: at,
          inbox: inbox,
        );
        creates.addAll(next.swaps);
        rows.addAll(next.inbox);
        audits.addAll(next.audits);
      }
    }
    final staged = await swaps.stage(
      familyId,
      SwapWritePlan(
        occurrence: OccurrenceWritePlan(
          actorId: actorUid,
          at: at,
          inbox: rows,
          audits: audits,
        ),
        creates: creates,
        changes: changes,
      ),
      integrity: true,
    );
    final writeFailure = staged.failureOrNull;
    if (writeFailure != null) return Failure<int>(writeFailure);
    return Success<int>(changes.length);
  }
}
