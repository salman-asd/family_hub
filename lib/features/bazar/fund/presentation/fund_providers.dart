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

/// The newest 24 closing documents; empty outside a family and while loading.
final monthClosingsProvider = StreamProvider<List<MonthClosing>>((ref) {
  final familyId = ref.watch(currentFamilyIdProvider);
  if (familyId == null) return Stream.value(const <MonthClosing>[]);
  return ref.watch(fundRepositoryProvider).watchClosings(familyId);
});

/// [monthClosingsProvider] keyed by month, for the pure lock/window rules.
final monthClosingsByMonthProvider = Provider<Map<MonthKey, MonthClosing>>(
  (ref) => <MonthKey, MonthClosing>{
    for (final closing
        in ref.watch(monthClosingsProvider).value ?? const <MonthClosing>[])
      closing.monthKey: closing,
  },
);

/// First month whose ledger rows count towards the current balance.
///
/// The month after the latest closed month, else `settings/bazar.fundStartMonth`
/// (ADR 0007).  `null` means the fund is not set up yet, so there is no ledger
/// to show instead of an unbounded read.
final fundWindowStartProvider = Provider<MonthKey?>(
  (ref) => MonthLocks.fundWindowStart(
    ref.watch(monthClosingsByMonthProvider),
    ref.watch(bazarSettingsProvider).fundStartMonth,
  ),
);

/// The ledger from the fund window onwards, newest first.
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

/// Received/spent/reimbursed components plus the exact ledger balance.
final fundSummaryProvider = Provider<FundSummary>(
  (ref) => FundBalanceCalculator.summarize(
    ref.watch(fundTransactionsProvider).value ?? const <FundTransaction>[],
  ),
);

/// The one number the fund card shows; never stored separately (ADR 0007).
final fundBalanceProvider = Provider<Money>(
  (ref) => ref.watch(fundSummaryProvider).balance,
);

/// True when the listener is full, so older months are no longer in memory.
///
/// Managers then close (or archive) earlier months; the UI says why the
/// balance may look incomplete instead of showing a quietly wrong number.
final fundWindowOverflowProvider = Provider<bool>(
  (ref) =>
      (ref.watch(fundTransactionsProvider).value?.length ?? 0) >=
      kMaxListenerDocs,
);
