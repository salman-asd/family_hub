import 'package:family_hub/core/firebase/query_limits.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/core/utils/money.dart';
import 'package:family_hub/features/bazar/fund/domain/fund_balance_calculator.dart';
import 'package:family_hub/features/bazar/fund/domain/fund_repository.dart';
import 'package:family_hub/features/bazar/fund/domain/fund_transaction.dart';
import 'package:family_hub/features/bazar/fund/domain/month_closing.dart';
import 'package:family_hub/features/bazar/settings/presentation/bazar_settings_providers.dart';
import 'package:family_hub/features/family/presentation/family_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Overridden in `bootstrap.dart` and in tests.
final fundRepositoryProvider = Provider<FundRepository>(
  (ref) => throw UnimplementedError(
    'fundRepositoryProvider must be overridden (bootstrap.dart / tests).',
  ),
);

/// The newest month closings (at most 24), live.
final monthClosingsProvider = StreamProvider<List<MonthClosing>>((ref) {
  final familyId = ref.watch(currentFamilyIdProvider);
  if (familyId == null) return Stream.value(const <MonthClosing>[]);
  return ref.watch(fundRepositoryProvider).watchClosings(familyId);
});

/// The closings keyed by month, the shape `MonthLocks` works on.
final monthClosingMapProvider = Provider<Map<MonthKey, MonthClosing>>((ref) {
  final rows = ref.watch(monthClosingsProvider).value ?? const <MonthClosing>[];
  return <MonthKey, MonthClosing>{for (final row in rows) row.monthKey: row};
});

/// First month whose ledger rows count towards the balance (ADR 0007), or
/// `null` while no fund has been set up.
final fundWindowStartProvider = Provider<MonthKey?>(
  (ref) => MonthLocks.fundWindowStart(
    ref.watch(monthClosingMapProvider),
    ref.watch(bazarSettingsProvider.select((s) => s.fundStartMonth)),
  ),
);

/// The ledger rows of the fund window, live.  Empty when no fund exists.
final fundTransactionsProvider = StreamProvider<List<FundTransaction>>((ref) {
  final familyId = ref.watch(currentFamilyIdProvider);
  final from = ref.watch(fundWindowStartProvider);
  if (familyId == null || from == null) {
    return Stream.value(const <FundTransaction>[]);
  }
  return ref
      .watch(fundRepositoryProvider)
      .watchTransactionsFrom(familyId, from);
});

final fundSummaryProvider = Provider<FundSummary>(
  (ref) => FundBalanceCalculator.summarize(
    ref.watch(fundTransactionsProvider).value ?? const <FundTransaction>[],
  ),
);

/// The fund balance: computed from the ledger window, never stored.
final fundBalanceProvider = Provider<Money>(
  (ref) => ref.watch(fundSummaryProvider.select((s) => s.balance)),
);

/// `true` when the listener hit its document cap, so the balance may be
/// incomplete.  The Fund screen then tells managers to close earlier months.
final fundWindowOverflowProvider = Provider<bool>(
  (ref) =>
      (ref.watch(fundTransactionsProvider).value?.length ?? 0) >=
      kMaxListenerDocs,
);
