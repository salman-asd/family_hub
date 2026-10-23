import 'package:family_hub/core/utils/money.dart';
import 'package:family_hub/features/bazar/advances/domain/advance_repository.dart';
import 'package:family_hub/features/bazar/advances/domain/member_advance.dart';
import 'package:family_hub/features/family/presentation/family_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Overridden in `bootstrap.dart` and in tests.
final advanceRepositoryProvider = Provider<AdvanceRepository>(
  (ref) => throw UnimplementedError(
    'advanceRepositoryProvider must be overridden (bootstrap.dart / tests).',
  ),
);

/// Advances still owed (`pending` or `partial`), newest first.
final openAdvancesProvider = StreamProvider<List<MemberAdvance>>((ref) {
  final familyId = ref.watch(currentFamilyIdProvider);
  if (familyId == null) return Stream.value(const <MemberAdvance>[]);
  return ref.watch(advanceRepositoryProvider).watchOpenAdvances(familyId);
});

/// What the fund screen shows about advances: how many are open, for how much,
/// and how much each member is still owed.
final class AdvanceSummary {
  AdvanceSummary({
    required this.openCount,
    required Map<String, Money> remainingByMember,
  }) : remainingByMember = Map<String, Money>.unmodifiable(remainingByMember);

  /// Totals over the open advances; the voided and settled ones are ignored.
  factory AdvanceSummary.of(Iterable<MemberAdvance> advances) {
    var openCount = 0;
    final byMember = <String, Money>{};
    for (final advance in advances) {
      if (advance.status != AdvanceStatus.pending &&
          advance.status != AdvanceStatus.partial) {
        continue;
      }
      openCount++;
      byMember[advance.memberId] =
          (byMember[advance.memberId] ?? Money.zero) + advance.remaining;
    }
    return AdvanceSummary(openCount: openCount, remainingByMember: byMember);
  }

  final int openCount;

  /// Member id → still owed to them.
  final Map<String, Money> remainingByMember;

  /// Everything still owed, to everybody.
  Money get remaining => Money.sum(remainingByMember.values);

  @override
  bool operator ==(Object other) {
    if (other is! AdvanceSummary || other.openCount != openCount) return false;
    if (other.remainingByMember.length != remainingByMember.length) {
      return false;
    }
    for (final entry in remainingByMember.entries) {
      if (other.remainingByMember[entry.key] != entry.value) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
    openCount,
    Object.hashAll(
      remainingByMember.entries.map((e) => Object.hash(e.key, e.value)),
    ),
  );

  @override
  String toString() => 'AdvanceSummary($openCount open, $remaining)';
}

/// [openAdvancesProvider] folded into the numbers the fund screen needs.
final advanceSummaryProvider = Provider<AdvanceSummary>(
  (ref) => AdvanceSummary.of(
    ref.watch(openAdvancesProvider).value ?? const <MemberAdvance>[],
  ),
);
