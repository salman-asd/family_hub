import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/core/utils/money.dart';
import 'package:family_hub/features/bazar/fund/domain/fund_balance_calculator.dart';
import 'package:family_hub/features/bazar/fund/domain/fund_transaction.dart';
import 'package:family_hub/features/bazar/fund/domain/month_closing.dart';
import 'package:family_hub/features/bazar/fund/domain/usecases/close_month.dart';
import 'package:family_hub/features/bazar/fund/domain/usecases/reopen_month.dart';
import 'package:family_hub/features/bazar/settings/domain/bazar_settings.dart';

import '../bazar_test_helpers.dart';
import '../settings/bazar_settings_test_helpers.dart';

/// Fixture for the P2-21 close/reopen tests: the standard Bazar family, the
/// in-memory ledger, a fake settings port and both use cases.
class MonthFixture {
  MonthFixture({MonthKey? fundStartMonth = const MonthKey(2026, 9)})
    : settings = FakeBazarSettingsRepository(
        BazarSettings.defaults.copyWith(fundStartMonth: fundStartMonth),
      );

  static const String familyId = BazarFixture.familyId;

  /// "Today" in the fixture family: 2026-10-18.
  static final MonthKey october = MonthKey(2026, 10);

  final BazarFixture fx = BazarFixture();
  final FakeBazarSettingsRepository settings;

  DateKey get today => fx.dateKeys.today();

  List<FundTransaction> get ledger =>
      fx.backend.fundTransactionsOf(familyId);

  Money get balance => FundBalanceCalculator.balance(ledger);

  MonthClosing? closingOf(MonthKey month) =>
      fx.backend.closings[familyId]?[month];

  /// The window `MonthLocks` would use after the closings written so far.
  MonthKey? windowStart() => MonthLocks.fundWindowStart(
    fx.backend.closings[familyId] ?? const <MonthKey, MonthClosing>{},
    settings.stored.fundStartMonth,
  );

  /// The balance the Fund screen shows: rows from the window onwards.
  Money windowBalance() {
    final start = windowStart();
    if (start == null) return Money.zero;
    return FundBalanceCalculator.balance(
      ledger.where((row) => row.monthKey.compareTo(start) >= 0),
    );
  }

  /// A contribution row dated [day], so a month has money in it.
  FundTransaction putContribution({
    required String id,
    required int paisa,
    required DateKey day,
  }) {
    final row = FundTransaction.forContribution(
      contributionId: id,
      amount: Money.paisa(paisa),
      dateKey: day,
      createdBy: 'alice',
      createdAt: fx.clock.nowUtc(),
    );
    fx.putFundTransaction(row);
    return row;
  }

  CloseMonth get close => CloseMonth(
    funds: fx.backend,
    settings: settings,
    families: fx.backend,
    clock: fx.clock,
    newId: fx.ids.call,
    dateKeys: fx.dateKeys,
  );

  ReopenMonth get reopen => ReopenMonth(
    funds: fx.backend,
    families: fx.backend,
    clock: fx.clock,
    newId: fx.ids.call,
  );
}
