import 'package:family_hub/features/chores/occurrences/domain/chore_occurrence.dart';
import 'package:family_hub/features/chores/occurrences/domain/occurrence_status.dart';

/// Whether a chore can still change hands: nothing ticked, not finished, not
/// skipped (`occurrence_started` otherwise, road map P3-26).
bool isUnstarted(ChoreOccurrence occurrence) =>
    occurrence.status == OccurrenceStatus.scheduled &&
    occurrence.subtaskDone.isEmpty &&
    occurrence.completedAt == null;

/// When a request for [occurrence] lapses: the due time minus the buffer.
DateTime swapExpiry(ChoreOccurrence occurrence, int bufferMinutes) =>
    occurrence.dueAt.subtract(Duration(minutes: bufferMinutes));

/// The deterministic id of a policy-B cover request: `cv_{absence}_{hash}`
/// (`cv2_` for the second round). Short on purpose: it is the audit `refId`
/// (at most 64 characters) and the inbox `refId`.
///
/// The hash is FNV-1a over the occurrence id, so the same absence and chore
/// always give the same id (a retry rewrites the request) and two chores of one
/// absence never share one in practice.
String coverRequestId(
  String availabilityId,
  String occurrenceId, {
  bool secondRound = false,
}) {
  var hash = 0x811c9dc5;
  for (final unit in occurrenceId.codeUnits) {
    hash = ((hash ^ unit) * 0x01000193) & 0xffffffff;
  }
  final tag = hash.toRadixString(16).padLeft(8, '0');
  return '${secondRound ? 'cv2_' : 'cv_'}${availabilityId}_$tag';
}
