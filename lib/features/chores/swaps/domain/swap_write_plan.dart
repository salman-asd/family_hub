import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/features/chores/occurrences/domain/occurrence_write_plan.dart';
import 'package:family_hub/features/chores/swaps/domain/swap_request.dart';

/// A request to create.
final class NewSwap {
  const NewSwap({
    required this.id,
    required this.occurrenceId,
    required this.occurrenceDateKey,
    required this.kind,
    required this.fromMemberId,
    required this.toMemberId,
    required this.reason,
    required this.expiresAt,
    this.availabilityId,
  });

  final String id;
  final String occurrenceId;
  final DateKey occurrenceDateKey;
  final SwapKind kind;
  final String fromMemberId;
  final String toMemberId;
  final String reason;
  final DateTime expiresAt;
  final String? availabilityId;

  @override
  String toString() => 'NewSwap($id $fromMemberId->$toMemberId)';
}

/// A status change of an existing request (never of its other fields).
final class SwapChange {
  const SwapChange({
    required this.requestId,
    required this.status,
    this.responseReason,
  });

  final String requestId;
  final SwapStatus status;
  final String? responseReason;

  @override
  String toString() => 'SwapChange($requestId -> ${status.id})';
}

/// Everything ONE swap action writes, in ONE batch (road map 3.4).
///
/// The request documents and the occurrence part (patch, `swapped|covered`
/// event, inbox rows, audit entries, a materialized draft) travel together, so
/// an acceptance can never change the chore without closing the request.
final class SwapWritePlan {
  const SwapWritePlan({
    required this.occurrence,
    this.creates = const <NewSwap>[],
    this.changes = const <SwapChange>[],
  });

  final OccurrenceWritePlan occurrence;
  final List<NewSwap> creates;
  final List<SwapChange> changes;

  String get actorId => occurrence.actorId;
  DateTime get at => occurrence.at;

  @override
  String toString() =>
      'SwapWritePlan(${creates.length} new, ${changes.length} changes)';
}
