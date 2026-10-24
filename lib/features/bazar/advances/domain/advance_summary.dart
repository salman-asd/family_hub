import 'package:family_hub/core/utils/money.dart';
import 'package:family_hub/features/bazar/advances/domain/member_advance.dart';

/// Open member-paid purchases at a glance: how many, and what is still owed.
final class AdvanceSummary {
  AdvanceSummary({required this.openCount, required Map<String, Money> owed})
    : owedByMember = Map<String, Money>.unmodifiable(owed);

  factory AdvanceSummary.of(Iterable<MemberAdvance> advances) {
    var count = 0;
    final owed = <String, Money>{};
    for (final advance in advances) {
      if (advance.status == AdvanceStatus.voided ||
          advance.status == AdvanceStatus.settled) {
        continue;
      }
      count++;
      owed[advance.memberId] =
          (owed[advance.memberId] ?? Money.zero) + advance.remaining;
    }
    return AdvanceSummary(openCount: count, owed: owed);
  }

  static final AdvanceSummary empty = AdvanceSummary(
    openCount: 0,
    owed: const <String, Money>{},
  );

  final int openCount;

  /// Remaining amount owed to each member.
  final Map<String, Money> owedByMember;

  Money get totalOwed =>
      owedByMember.values.fold(Money.zero, (sum, value) => sum + value);
}
