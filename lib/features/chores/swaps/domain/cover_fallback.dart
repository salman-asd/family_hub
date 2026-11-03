import 'package:family_hub/core/audit/audit_event_type.dart';
import 'package:family_hub/features/chores/availability/domain/availability_index.dart';
import 'package:family_hub/features/chores/availability/domain/member_availability.dart';
import 'package:family_hub/features/chores/duty_groups/domain/cover_picker.dart';
import 'package:family_hub/features/chores/occurrences/domain/chore_occurrence.dart';
import 'package:family_hub/features/chores/occurrences/domain/occurrence_write_plan.dart';
import 'package:family_hub/features/chores/swaps/domain/swap_plan_helpers.dart';
import 'package:family_hub/features/chores/swaps/domain/swap_request.dart';
import 'package:family_hub/features/chores/swaps/domain/swap_rules.dart';
import 'package:family_hub/features/chores/swaps/domain/swap_write_plan.dart';
import 'package:family_hub/features/family/domain/member.dart';
import 'package:family_hub/features/notifications/domain/inbox_port.dart';

/// What to do after a policy-B cover request failed (declined or expired):
/// try the NEXT candidate once, else fall back to policy A (P3-26).
///
/// Ids are deterministic (`cv2_{availabilityId}_{hash}`), so a retry
/// rewrites the same request and a request that is itself a second round never
/// starts a third one.
final class CoverFallbackResult {
  const CoverFallbackResult({
    this.swaps = const <NewSwap>[],
    this.inbox = const <NewInboxItem>[],
    this.audits = const <NewAudit>[],
  });

  final List<NewSwap> swaps;
  final List<NewInboxItem> inbox;
  final List<NewAudit> audits;
}

abstract final class CoverFallback {
  static const String firstRound = 'cv_';
  static const String secondRound = 'cv2_';

  static CoverFallbackResult next({
    required SwapRequest failed,
    required ChoreOccurrence? occurrence,
    required MemberAvailability? absence,
    required List<Member> members,
    required AvailabilityIndex index,
    required int bufferMinutes,
    required DateTime now,
    required InboxPort inbox,
  }) {
    if (failed.kind != SwapKind.cover || failed.availabilityId == null) {
      return const CoverFallbackResult();
    }
    final name = occurrence?.nameBn ?? failed.occurrenceId;
    final date = failed.occurrenceDateKey.toString();
    final firstTry = failed.id.startsWith(firstRound);

    String? candidate;
    if (firstTry && occurrence != null) {
      candidate = CoverPicker.pick(
        candidates: <String>[
          for (final member in members)
            if (member.isActive &&
                member.uid != failed.fromMemberId &&
                member.uid != failed.toMemberId)
              member.uid,
        ],
        day: failed.occurrenceDateKey,
        unavailable: index,
      );
    }
    final expiresAt = occurrence == null
        ? now
        : occurrence.dueAt.subtract(Duration(minutes: bufferMinutes));
    if (candidate != null && expiresAt.isAfter(now)) {
      final id = coverRequestId(
        failed.availabilityId!,
        failed.occurrenceId,
        secondRound: true,
      );
      final row = inbox.swapRequested(
        requestId: id,
        toMemberId: candidate,
        choreName: name,
        dateKey: date,
        fromMemberId: failed.fromMemberId,
        cover: true,
      );
      return CoverFallbackResult(
        swaps: <NewSwap>[
          NewSwap(
            id: id,
            occurrenceId: failed.occurrenceId,
            occurrenceDateKey: failed.occurrenceDateKey,
            kind: SwapKind.cover,
            fromMemberId: failed.fromMemberId,
            toMemberId: candidate,
            reason: failed.reason,
            expiresAt: expiresAt,
            availabilityId: failed.availabilityId,
          ),
        ],
        inbox: <NewInboxItem>[?row?.withId('ib_$id')],
        audits: <NewAudit>[
          swapAudit(
            type: AuditEventType.choresSwapRequested,
            id: 'au_$id',
            requestId: id,
            name: name,
            date: date,
            from: failed.fromMemberId,
            to: candidate,
          ),
        ],
      );
    }

    // Policy A: the absent member and the managers learn it needs a cover.
    final recipients = <String>{
      failed.fromMemberId,
      for (final manager in managersOf(members)) manager.uid,
    };
    final range = absence?.startDate ?? failed.occurrenceDateKey;
    return CoverFallbackResult(
      inbox: <NewInboxItem>[
        for (final to in recipients)
          ?inbox
              .needsCover(
                availabilityId: failed.availabilityId!,
                toMemberId: to,
                absentMemberId: failed.fromMemberId,
                count: 1,
                from: range.toString(),
                to: (absence?.endDate ?? failed.occurrenceDateKey).toString(),
              )
              ?.withId('ib_nc_${failed.id}_$to'),
      ],
    );
  }
}

