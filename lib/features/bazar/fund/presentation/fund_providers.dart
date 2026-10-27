import 'package:family_hub/core/firebase/query_limits.dart';
import 'package:family_hub/core/utils/clock_provider.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/features/bazar/advances/presentation/advance_providers.dart';
import 'package:family_hub/features/bazar/contributions/domain/contribution_status.dart';
import 'package:family_hub/features/bazar/contributions/presentation/contribution_providers.dart';
import 'package:family_hub/features/bazar/fund/domain/month_close_preview.dart';
import 'package:family_hub/core/utils/family_date_keys.dart';
import 'package:family_hub/core/utils/id_generator.dart';
import 'package:family_hub/core/utils/money.dart';
import 'package:family_hub/features/bazar/expenses/domain/expense.dart';
import 'package:family_hub/features/bazar/expenses/presentation/expense_providers.dart';
import 'package:family_hub/features/bazar/fund/domain/balance_drift.dart';
import 'package:family_hub/features/bazar/fund/domain/fund_balance_calculator.dart';
import 'package:family_hub/features/bazar/fund/domain/fund_repository.dart';
import 'package:family_hub/features/bazar/fund/domain/fund_transaction.dart';
import 'package:family_hub/features/bazar/fund/domain/ledger_integrity_check.dart';
import 'package:family_hub/features/bazar/fund/domain/month_closing.dart';
import 'package:family_hub/features/bazar/fund/domain/usecases/close_month.dart';
import 'package:family_hub/features/bazar/fund/domain/usecases/reopen_month.dart';
import 'package:family_hub/features/bazar/settings/presentation/bazar_settings_providers.dart';
import 'package:family_hub/features/family/presentation/family_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Overridden in `bootstrap.dart` and in tests.
final fundRepositoryProvider = Provider<FundRepository>(
  (ref) => throw UnimplementedError(
    'fundRepositoryProvider must be overridden (bootstrap.dart / tests).',
  ),
);

/// The exact-id opening-row read `CloseMonth` needs.  In `bootstrap.dart` the
/// same `FirestoreFundRepository` serves both; a test may point it at a fake.
final fundOpeningLedgerProvider = Provider<ExistingOpeningLedger>(
  (ref) => throw UnimplementedError(
    'fundOpeningLedgerProvider must be overridden (bootstrap.dart / tests).',
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

/// The ledger rows of [month], from the same listener the expense list uses
/// when it is alive (a month is cheap to re-read from cache).
final monthFundTransactionsProvider = Provider.autoDispose
    .family<List<FundTransaction>, MonthKey>((ref, month) {
      final from = ref.watch(fundWindowStartProvider);
      if (from == null || month.compareTo(from) < 0) {
        return const <FundTransaction>[];
      }
      return <FundTransaction>[
        for (final row
            in ref.watch(fundTransactionsProvider).value ??
                const <FundTransaction>[])
          if (row.monthKey == month) row,
      ];
    });

/// Problems with the month's expense rows (`checkLedger`).  Managers only.
final ledgerIntegrityProvider = Provider.autoDispose
    .family<List<LedgerIssue>, MonthKey>((ref, month) {
      final expenses =
          ref.watch(monthExpensesProvider(month)).value ?? const <Expense>[];
      return checkLedger(
        expenses: expenses,
        txs: ref.watch(fundTransactionsProvider).value ??
            const <FundTransaction>[],
        month: month,
      );
    });

/// `ledger − stored` for the newest closed month; `null` when they agree.
final balanceDriftProvider = Provider<BalanceDrift?>(
  (ref) => detectBalanceDrift(
    closings: ref.watch(monthClosingMapProvider),
    window: ref.watch(fundTransactionsProvider).value ??
        const <FundTransaction>[],
  ),
);

/// The facts a manager checks before closing [month] (P2-23): the month's
/// own ledger summary, the open advances and the contribution totals.
final monthClosePreviewProvider = Provider.autoDispose
    .family<MonthClosePreview, MonthKey>((ref, month) {
      final rows = <FundTransaction>[
        for (final row
            in ref.watch(fundTransactionsProvider).value ??
                const <FundTransaction>[])
          if (row.monthKey == month) row,
      ];
      final statuses = ref.watch(contributionStatusProvider(month));
      return MonthClosePreview(
        month: month,
        summary: FundBalanceCalculator.summarize(rows),
        openAdvances:
            ref.watch(openAdvancesProvider).value?.length ?? 0,
        expected: ContributionStatusCalculator.totalExpected(statuses),
        received: ContributionStatusCalculator.totalReceived(statuses),
      );
    });

/// Closes a month (P2-21).
final closeMonthProvider = Provider<CloseMonth>(
  (ref) => CloseMonth(
    funds: ref.watch(fundRepositoryProvider),
    openingRows: ref.watch(fundOpeningLedgerProvider),
    families: ref.watch(familyRepositoryProvider),
    clock: ref.watch(clockProvider),
    newId: ref.watch(idGeneratorProvider),
    dateKeys: ref.watch(familyDateKeysProvider),
    settings: ref.watch(bazarSettingsRepositoryProvider),
  ),
);

final reopenMonthProvider = Provider<ReopenMonth>(
  (ref) => ReopenMonth(
    funds: ref.watch(fundRepositoryProvider),
    families: ref.watch(familyRepositoryProvider),
    clock: ref.watch(clockProvider),
    newId: ref.watch(idGeneratorProvider),
  ),
);

/// The closing of one month, `null` while it is open (or not in the window).
final monthClosingProvider = Provider.autoDispose
    .family<MonthClosing?, MonthKey>(
      (ref, month) => ref.watch(monthClosingMapProvider)[month],
    );


