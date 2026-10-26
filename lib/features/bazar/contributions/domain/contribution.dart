import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/core/utils/money.dart';

/// How a contribution was handed over.
enum ContributionMethod { cash, bkash, nagad, bank, other }

/// Where a contribution stands in the approval flow (D-P2-18).
enum ContributionApproval { pending, approved, rejected }

/// A member's request to change an APPROVED contribution.
///
/// It is stored on the contribution (`pendingChange`) and touches nothing else
/// until a manager approves it.
final class ContributionChange {
  const ContributionChange({
    required this.amount,
    required this.date,
    required this.requestedAt,
    this.method,
    this.note,
  });

  final Money amount;
  final DateKey date;
  final ContributionMethod? method;
  final String? note;
  final DateTime requestedAt;

  @override
  bool operator ==(Object other) =>
      other is ContributionChange &&
      other.amount == amount &&
      other.date == date &&
      other.method == method &&
      other.note == note &&
      other.requestedAt == requestedAt;

  @override
  int get hashCode => Object.hash(amount, date, method, note, requestedAt);
}

/// What one member is expected to pay in one month (`contributionPlans`).
///
/// The id is `<yyyy-MM>_<memberId>` (CLAUDE.md rule 4).
final class ContributionPlan {
  const ContributionPlan({
    required this.month,
    required this.memberId,
    required this.expected,
  });

  final MonthKey month;
  final String memberId;
  final Money expected;

  String get id => '${month}_$memberId';

  @override
  bool operator ==(Object other) =>
      other is ContributionPlan &&
      other.month == month &&
      other.memberId == memberId &&
      other.expected == expected;

  @override
  int get hashCode => Object.hash(month, memberId, expected);

  @override
  String toString() => 'ContributionPlan($id, $expected)';
}

/// One contribution (`contributions/{id}`).
///
/// Only an `approved`, non-voided contribution counts as received money and
/// has a ledger row (`con_<id>`).  A `pending` request never touches the
/// ledger.  Voiding keeps the document and adds a compensating ledger row.
final class Contribution {
  const Contribution({
    required this.id,
    required this.memberId,
    required this.monthKey,
    required this.dateKey,
    required this.amount,
    required this.status,
    required this.requestedBy,
    required this.createdAt,
    this.method,
    this.note,
    this.fundTxId,
    this.decidedBy,
    this.decidedAt,
    this.rejectReason,
    this.pendingChange,
    this.voidedAt,
    this.voidedBy,
  });

  final String id;
  final String memberId;
  final MonthKey monthKey;
  final DateKey dateKey;
  final Money amount;
  final ContributionMethod? method;
  final String? note;
  final ContributionApproval status;

  /// The person who entered it (the member, or the manager who recorded it).
  final String requestedBy;
  final DateTime createdAt;

  /// `con_<id>`; set only once approved.
  final String? fundTxId;
  final String? decidedBy;
  final DateTime? decidedAt;
  final String? rejectReason;
  final ContributionChange? pendingChange;
  final DateTime? voidedAt;
  final String? voidedBy;

  bool get isVoided => voidedAt != null;
  bool get isPending => status == ContributionApproval.pending && !isVoided;
  bool get isApproved => status == ContributionApproval.approved && !isVoided;

  /// True when this row adds to a member's `received`.
  bool get countsAsReceived => isApproved;

  Contribution copyWith({
    Money? amount,
    DateKey? dateKey,
    ContributionMethod? method,
    String? note,
    ContributionApproval? status,
    String? fundTxId,
    String? decidedBy,
    DateTime? decidedAt,
    String? rejectReason,
    ContributionChange? pendingChange,
    bool clearPendingChange = false,
    DateTime? voidedAt,
    String? voidedBy,
    bool clearMethod = false,
    bool clearNote = false,
  }) => Contribution(
    id: id,
    memberId: memberId,
    monthKey: dateKey?.monthKey ?? monthKey,
    dateKey: dateKey ?? this.dateKey,
    amount: amount ?? this.amount,
    method: clearMethod ? null : (method ?? this.method),
    note: clearNote ? null : (note ?? this.note),
    status: status ?? this.status,
    requestedBy: requestedBy,
    createdAt: createdAt,
    fundTxId: fundTxId ?? this.fundTxId,
    decidedBy: decidedBy ?? this.decidedBy,
    decidedAt: decidedAt ?? this.decidedAt,
    rejectReason: rejectReason ?? this.rejectReason,
    pendingChange: clearPendingChange
        ? null
        : (pendingChange ?? this.pendingChange),
    voidedAt: voidedAt ?? this.voidedAt,
    voidedBy: voidedBy ?? this.voidedBy,
  );

  @override
  bool operator ==(Object other) =>
      other is Contribution &&
      other.id == id &&
      other.memberId == memberId &&
      other.monthKey == monthKey &&
      other.dateKey == dateKey &&
      other.amount == amount &&
      other.method == method &&
      other.note == note &&
      other.status == status &&
      other.requestedBy == requestedBy &&
      other.createdAt == createdAt &&
      other.fundTxId == fundTxId &&
      other.decidedBy == decidedBy &&
      other.decidedAt == decidedAt &&
      other.rejectReason == rejectReason &&
      other.pendingChange == pendingChange &&
      other.voidedAt == voidedAt &&
      other.voidedBy == voidedBy;

  @override
  int get hashCode => Object.hash(
    id,
    memberId,
    monthKey,
    dateKey,
    amount,
    method,
    note,
    status,
    requestedBy,
    createdAt,
    fundTxId,
    decidedBy,
    decidedAt,
    rejectReason,
    pendingChange,
    voidedAt,
    voidedBy,
  );

  @override
  String toString() =>
      'Contribution($id, $memberId, ${amount.paisa} paisa, ${status.name})';
}
