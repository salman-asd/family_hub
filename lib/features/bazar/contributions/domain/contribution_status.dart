import 'package:family_hub/core/utils/money.dart';
import 'package:family_hub/features/bazar/contributions/domain/contribution.dart';

/// One member's month: expected, received, what is left, what is extra and
/// what still waits for a manager's decision.
final class MemberContributionStatus {
  const MemberContributionStatus({
    required this.memberId,
    required this.expected,
    required this.received,
    required this.remaining,
    required this.credit,
    required this.pendingTotal,
  });

  final String memberId;
  final Money expected;

  /// Approved, non-voided contributions only.
  final Money received;

  /// `expected - received`, never negative.
  final Money remaining;

  /// `received - expected` when positive, else zero.
  final Money credit;

  /// Pending requests (not voided).  Never part of [received].
  final Money pendingTotal;

  @override
  bool operator ==(Object other) =>
      other is MemberContributionStatus &&
      other.memberId == memberId &&
      other.expected == expected &&
      other.received == received &&
      other.remaining == remaining &&
      other.credit == credit &&
      other.pendingTotal == pendingTotal;

  @override
  int get hashCode =>
      Object.hash(memberId, expected, received, remaining, credit, pendingTotal);

  @override
  String toString() =>
      'MemberContributionStatus($memberId, expected ${expected.paisa}, '
      'received ${received.paisa}, pending ${pendingTotal.paisa})';
}

/// Pure per-month contribution arithmetic (integer paisa only).
abstract final class ContributionStatusCalculator {
  /// One row per active member in roster order, then (sorted by id) anyone
  /// else who has a plan or approved money, so [totalReceived] always matches
  /// the ledger.  A member without a plan expects zero and every payment is
  /// credit.  Rejected and voided rows count for nothing.
  static List<MemberContributionStatus> compute({
    required List<ContributionPlan> plans,
    required List<Contribution> contributions,
    required List<String> activeMemberIds,
  }) {
    final expected = <String, Money>{
      for (final plan in plans) plan.memberId: plan.expected,
    };
    final received = <String, Money>{};
    final pending = <String, Money>{};
    for (final c in contributions) {
      if (c.countsAsReceived) {
        received[c.memberId] = (received[c.memberId] ?? Money.zero) + c.amount;
      } else if (c.isPending) {
        pending[c.memberId] = (pending[c.memberId] ?? Money.zero) + c.amount;
      }
    }

    final ids = <String>[...activeMemberIds];
    final extra = <String>{
      ...expected.keys,
      ...received.keys,
      ...pending.keys,
    }.where((id) => !ids.contains(id)).toList()..sort();
    ids.addAll(extra);

    return <MemberContributionStatus>[
      for (final id in ids)
        _row(
          id,
          expected[id] ?? Money.zero,
          received[id] ?? Money.zero,
          pending[id] ?? Money.zero,
        ),
    ];
  }

  static MemberContributionStatus _row(
    String id,
    Money expected,
    Money received,
    Money pending,
  ) => MemberContributionStatus(
    memberId: id,
    expected: expected,
    received: received,
    remaining: received >= expected ? Money.zero : expected - received,
    credit: received > expected ? received - expected : Money.zero,
    pendingTotal: pending,
  );

  static Money totalExpected(List<MemberContributionStatus> rows) =>
      rows.fold<Money>(Money.zero, (sum, r) => sum + r.expected);

  static Money totalReceived(List<MemberContributionStatus> rows) =>
      rows.fold<Money>(Money.zero, (sum, r) => sum + r.received);
}
