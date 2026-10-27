import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/core/utils/money.dart';
import 'package:family_hub/features/bazar/fund/domain/balance_drift.dart';
import 'package:family_hub/features/bazar/fund/domain/fund_transaction.dart';
import 'package:family_hub/features/bazar/fund/domain/month_closing.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final october = MonthKey(2026, 10);
  final november = MonthKey(2026, 11);
  final at = DateTime.utc(2026, 10, 31, 18);

  MonthClosing closed(MonthKey month, int balance) => MonthClosing(
    monthKey: month,
    status: MonthStatus.closed,
    closedAt: at,
    closedBy: 'alice',
    closingBalance: Money.paisa(balance),
  );

  FundTransaction opening(MonthKey month, int paisa) =>
      FundTransaction.opening(
        monthKey: month,
        amount: Money.paisa(paisa),
        createdBy: 'alice',
        createdAt: at,
      );

  test('no closing at all means no warning', () {
    expect(
      detectBalanceDrift(
        closings: const <MonthKey, MonthClosing>{},
        window: <FundTransaction>[opening(november, 5000)],
      ),
      isNull,
    );
  });

  test('an opening row equal to the stored balance is no warning', () {
    expect(
      detectBalanceDrift(
        closings: <MonthKey, MonthClosing>{october: closed(october, 70000)},
        window: <FundTransaction>[opening(november, 70000)],
      ),
      isNull,
    );
  });

  test('a ledger above the stored balance reports the difference', () {
    final drift = detectBalanceDrift(
      closings: <MonthKey, MonthClosing>{october: closed(october, 70000)},
      window: <FundTransaction>[
        opening(november, 70000),
        FundTransaction.forContribution(
          contributionId: 'late',
          amount: const Money.paisa(5000),
          dateKey: DateKey(2026, 11, 2),
          createdBy: 'cara',
          createdAt: at,
        ),
      ],
    );
    expect(drift, isNotNull);
    expect(drift!.month, october);
    expect(drift.stored, const Money.paisa(70000));
    expect(drift.ledger, const Money.paisa(75000));
    expect(drift.difference, const Money.paisa(5000));
  });

  test('the newest closed month is the one compared', () {
    final drift = detectBalanceDrift(
      closings: <MonthKey, MonthClosing>{
        october: closed(october, 70000),
        november: closed(november, 70000),
      },
      window: const <FundTransaction>[],
    );
    expect(drift!.month, november);
    expect(drift.difference, const Money.paisa(-70000));
  });

  test('a reopened month is not compared', () {
    expect(
      detectBalanceDrift(
        closings: <MonthKey, MonthClosing>{
          october: closed(october, 70000),
          november: MonthClosing(
            monthKey: november,
            status: MonthStatus.open,
            closingBalance: const Money.paisa(70000),
          ),
        },
        window: const <FundTransaction>[],
      )!.month,
      october,
    );
  });
}
