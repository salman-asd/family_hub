import 'package:family_hub/core/utils/money.dart';
import 'package:family_hub/features/bazar/advances/domain/member_advance.dart';

/// One member's open advances, with what is still owed to them.
final class AdvanceGroup {
  const AdvanceGroup({required this.memberId, required this.rows});

  final String memberId;
  final List<MemberAdvance> rows;

  Money get totalOwed =>
      rows.fold(Money.zero, (sum, row) => sum + row.remaining);
}

/// Groups [advances] by member, keeping the order each member first appears
/// (and the order inside a group), so the Advances screen never re-orders on a
/// rebuild.  Voided advances are dropped; settled ones stay only when
/// [includeSettled] is `true` (the "settled" filter).
List<AdvanceGroup> groupAdvances(
  Iterable<MemberAdvance> advances, {
  bool includeSettled = false,
}) {
  final order = <String>[];
  final byMember = <String, List<MemberAdvance>>{};
  for (final advance in advances) {
    if (advance.status == AdvanceStatus.voided) continue;
    if (!includeSettled && advance.status == AdvanceStatus.settled) continue;
    final rows = byMember.putIfAbsent(advance.memberId, () {
      order.add(advance.memberId);
      return <MemberAdvance>[];
    });
    rows.add(advance);
  }
  return <AdvanceGroup>[
    for (final memberId in order)
      AdvanceGroup(memberId: memberId, rows: byMember[memberId]!),
  ];
}
