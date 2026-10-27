import 'package:family_hub/core/permissions/permissions.dart';
import 'package:family_hub/core/utils/clock_provider.dart';
import 'package:family_hub/features/bazar/advances/domain/advance_repository.dart';
import 'package:family_hub/features/bazar/advances/domain/advance_summary.dart';
import 'package:family_hub/features/bazar/advances/domain/member_advance.dart';
import 'package:family_hub/features/bazar/advances/domain/settlement.dart';
import 'package:family_hub/features/bazar/advances/domain/usecases/settle_advance.dart';
import 'package:family_hub/features/bazar/expenses/presentation/expense_providers.dart';
import 'package:family_hub/features/bazar/fund/presentation/fund_providers.dart';
import 'package:family_hub/features/family/presentation/family_providers.dart';
import 'package:family_hub/features/family/presentation/permission_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Overridden in `bootstrap.dart` and in tests.
final advanceRepositoryProvider = Provider<AdvanceRepository>(
  (ref) => throw UnimplementedError(
    'advanceRepositoryProvider must be overridden (bootstrap.dart / tests).',
  ),
);

/// Advances still pending or partly settled, live.
///
/// Someone who cannot settle advances may read only their own (a rules check is
/// not a filter), so the query is narrowed to their uid.
final openAdvancesProvider = StreamProvider<List<MemberAdvance>>((ref) {
  final familyId = ref.watch(currentFamilyIdProvider);
  final uid = ref.watch(currentUidProvider);
  if (familyId == null || uid == null) {
    return Stream.value(const <MemberAdvance>[]);
  }
  final seesAll = ref.can(Permission.recordContribution);
  return ref
      .watch(advanceRepositoryProvider)
      .watchOpenAdvances(familyId, memberId: seesAll ? null : uid);
});

/// Everyone's open advances grouped for the Advances screen.
final advanceSummaryProvider = Provider<AdvanceSummary>(
  (ref) => AdvanceSummary.of(
    ref.watch(openAdvancesProvider).value ?? const <MemberAdvance>[],
  ),
);

/// The settlements of one advance (newest first).
final advanceSettlementsProvider = StreamProvider.autoDispose
    .family<List<Settlement>, String>((ref, advanceId) {
      final familyId = ref.watch(currentFamilyIdProvider);
      if (familyId == null) return Stream.value(const <Settlement>[]);
      return ref
          .watch(advanceRepositoryProvider)
          .watchSettlements(familyId, advanceId: advanceId);
    });

/// The advanced expense, read once (for its item name).  Keyed by a record so
/// two advances on one screen never share a cache entry.
final advanceExpenseNameProvider = FutureProvider.autoDispose
    .family<String?, ({String familyId, String expenseId})>((ref, key) async {
      final result = await ref
          .watch(expenseRepositoryProvider)
          .getExpense(key.familyId, key.expenseId);
      return result.valueOrNull?.itemName;
    });

final settleAdvanceProvider = Provider<SettleAdvance>(
  (ref) => SettleAdvance(
    advances: ref.watch(advanceRepositoryProvider),
    funds: ref.watch(fundRepositoryProvider),
    families: ref.watch(familyRepositoryProvider),
    clock: ref.watch(clockProvider),
    newId: ref.watch(idGeneratorProvider),
    dateKeys: ref.watch(familyDateKeysProvider),
  ),
);
