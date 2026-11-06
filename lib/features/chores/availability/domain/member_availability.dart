import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/features/chores/availability/domain/availability_index.dart';

enum AvailabilityStatus {
  pending('pending'),
  active('active'),
  rejected('rejected'),
  cancelled('cancelled');

  const AvailabilityStatus(this.id);
  final String id;

  static AvailabilityStatus fromId(Object? id) => values.firstWhere(
    (s) => s.id == id,
    orElse: () => AvailabilityStatus.cancelled,
  );
}

/// Limits of an absence record (mirrored by the P3-26 rules).
abstract final class AvailabilityLimits {
  static const int maxDays = 366;
  static const int minReason = 3;
  static const int maxReason = 200;

  /// A trimmed reason of 3-200 characters, or a `Validation`.
  static Result<String> reason(String? raw) {
    final text = raw?.trim() ?? '';
    if (text.length < minReason) {
      return const Failure<String>(Validation('reason', 'reason_required'));
    }
    if (text.length > maxReason) {
      return const Failure<String>(Validation('reason', 'too_long'));
    }
    return Success<String>(text);
  }
}

/// One absence of one member (`memberAvailability/{id}`).
///
/// Only an `active` record hides the member from the rota; a `pending` one is
/// waiting for a manager (`absenceNeedsApproval`). The range is inclusive.
final class MemberAvailability {
  const MemberAvailability({
    required this.id,
    required this.memberId,
    required this.startDate,
    required this.endDate,
    required this.typeId,
    required this.reason,
    required this.status,
    required this.createdBy,
    this.decidedBy,
    this.decidedAt,
  });

  final String id;
  final String memberId;
  final DateKey startDate;
  final DateKey endDate;

  /// An id of the family's `absenceReasons` (tolerant of removed ones).
  final String typeId;
  final String reason;
  final AvailabilityStatus status;
  final String createdBy;
  final String? decidedBy;
  final DateTime? decidedAt;

  bool get isActive => status == AvailabilityStatus.active;

  /// Whether this record still blocks a new one (pending or active).
  bool get isLive =>
      status == AvailabilityStatus.pending ||
      status == AvailabilityStatus.active;

  bool overlaps(DateKey start, DateKey end) =>
      !start.isAfter(endDate) && !end.isBefore(startDate);

  AvailabilitySpan toSpan() => AvailabilitySpan(
    memberId: memberId,
    startDate: startDate,
    endDate: endDate,
  );

  MemberAvailability withStatus(
    AvailabilityStatus next, {
    String? by,
    DateTime? at,
  }) => MemberAvailability(
    id: id,
    memberId: memberId,
    startDate: startDate,
    endDate: endDate,
    typeId: typeId,
    reason: reason,
    status: next,
    createdBy: createdBy,
    decidedBy: by ?? decidedBy,
    decidedAt: at ?? decidedAt,
  );

  @override
  String toString() =>
      'MemberAvailability($id $memberId $startDate..$endDate ${status.id})';
}

/// The days of an absence record, inclusive.
int availabilityDays(DateKey start, DateKey end) => start.daysUntil(end) + 1;
