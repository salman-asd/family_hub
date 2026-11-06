import 'package:family_hub/core/utils/date_key.dart';

/// `swap`: a member asks somebody to take a chore. `cover`: the absence
/// policy asked somebody to cover for an absent member (road map 3.2).
enum SwapKind {
  swap('swap'),
  cover('cover');

  const SwapKind(this.id);
  final String id;

  static SwapKind fromId(Object? id) =>
      values.firstWhere((k) => k.id == id, orElse: () => SwapKind.swap);
}

enum SwapStatus {
  pending('pending'),
  accepted('accepted'),
  declined('declined'),
  expired('expired'),
  cancelled('cancelled');

  const SwapStatus(this.id);
  final String id;

  static SwapStatus fromId(Object? id) =>
      values.firstWhere((s) => s.id == id, orElse: () => SwapStatus.pending);
}

/// Limits of a request (mirrored by the P3-26 rules).
abstract final class SwapLimits {
  static const int minReason = 3;
  static const int maxReason = 300;
}

/// One request to move a chore to somebody else.
///
/// The ORIGINAL assignee ([fromMemberId]) and the [reason] stay on the request
/// and on the `swapped|covered` event forever (spec: nothing is forgotten when
/// a chore changes hands). The occurrence itself changes ONLY when the
/// recipient accepts, in the same batch (rules pair it with `getAfter`).
final class SwapRequest {
  const SwapRequest({
    required this.id,
    required this.occurrenceId,
    required this.occurrenceDateKey,
    required this.kind,
    required this.fromMemberId,
    required this.toMemberId,
    required this.reason,
    required this.status,
    required this.expiresAt,
    required this.requestedBy,
    this.respondedAt,
    this.respondedBy,
    this.responseReason,
    this.availabilityId,
  });

  final String id;
  final String occurrenceId;
  final DateKey occurrenceDateKey;
  final SwapKind kind;
  final String fromMemberId;
  final String toMemberId;
  final String reason;
  final SwapStatus status;
  final DateTime expiresAt;
  final String requestedBy;
  final DateTime? respondedAt;
  final String? respondedBy;
  final String? responseReason;

  /// The absence that caused a `cover` request (policy B), if any.
  final String? availabilityId;

  bool get isPending => status == SwapStatus.pending;

  /// True once the request may no longer be accepted (`expiresAt` reached).
  bool isExpiredAt(DateTime now) => !now.isBefore(expiresAt);

  SwapRequest withStatus(
    SwapStatus next, {
    required String by,
    required DateTime at,
    String? responseReason,
  }) => SwapRequest(
    id: id,
    occurrenceId: occurrenceId,
    occurrenceDateKey: occurrenceDateKey,
    kind: kind,
    fromMemberId: fromMemberId,
    toMemberId: toMemberId,
    reason: reason,
    status: next,
    expiresAt: expiresAt,
    requestedBy: requestedBy,
    respondedAt: at,
    respondedBy: by,
    responseReason: responseReason,
    availabilityId: availabilityId,
  );

  @override
  String toString() =>
      'SwapRequest($id ${status.id} $fromMemberId->$toMemberId)';
}
