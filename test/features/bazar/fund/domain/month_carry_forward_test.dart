import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/core/utils/money.dart';
import 'package:family_hub/features/bazar/fund/domain/fund_transaction.dart';
import 'package:family_hub/features/bazar/fund/domain/month_carry_forward.dart';
import 'package:family_hub/features/bazar/fund/domain/month_closing.dart';
import 'package:family_hub/features/bazar/fund/domain/usecases/close_month.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final october = MonthKey(2026, 10);
  final at = DateTime.utc(2026, 10, 31, 18);

  MonthClosing closing(MonthKey month, {required bool closed}) => MonthClosing(
    monthKey: month,
    status: closed ? MonthStatus.closed : MonthStatus.open,
  );

  MonthCarryForward carry({required int closing, int? existing}) =>
      MonthCarryForwardRules.compute(
        month: october,
        closingBalance: Money.paisa(closing),
        existingOpening: existing == null ? null : Money.paisa(existing),
        actorUid: 'alice',
        at: at,
        eventId: 'ev1',
      );

  group('MonthCarryForwardRules', () {
    test('an empty next month receives one opening row of the balance', () {
      final result = carry(closing: 125050);

      expect(result.nextMonth, MonthKey(2026, 11));
      expect(result.opening!.id, 'open_2026-11');
      expect(result.opening!.type, FundTxType.opening);
      expect(result.opening!.amount.paisa, 125050);
      expect(result.opening!.dateKey, DateKey(2026, 11, 1));
      expect(result.adjustment, isNull);
      expect(result.delta, isNull);
      expect(result.isEmpty, isFalse);
    });

    test('a zero balance writes nothing when no opening row exists', () {
      final result = carry(closing: 0);

      expect(result.isEmpty, isTrue);
      expect(result.opening, isNull);
      expect(result.adjustment, isNull);
    });

    test('a negative balance (overdrawn fund) is carried as a negative row', () {
      final result = carry(closing: -4200);

      expect(result.opening!.amount.paisa, -4200);
      expect(result.opening!.id, 'open_2026-11');
    });

    test('an existing opening row is corrected by the delta, never edited', () {
      // The month was closed at 100000, reopened, 5000 more was spent.
      final result = carry(closing: 95000, existing: 100000);

      expect(result.opening, isNull);
      expect(result.delta!.paisa, -5000);
      expect(result.adjustment!.id, 'adj_ev1_carry');
      expect(result.adjustment!.type, FundTxType.adjustment);
      expect(result.adjustment!.amount.paisa, -5000);
      expect(result.adjustment!.refType, FundRefType.month);
      expect(result.adjustment!.refId, '2026-11');
      expect(result.adjustment!.monthKey, MonthKey(2026, 11));
      expect(result.adjustment!.dateKey, DateKey(2026, 11, 1));
    });

    test('an unchanged re-close writes nothing at all', () {
      final result = carry(closing: 100000, existing: 100000);

      expect(result.isEmpty, isTrue);
      expect(result.delta!.isZero, isTrue);
    });

    test('the latest closed month ignores reopened months', () {
      expect(
        MonthCarryForwardRules.latestClosed(<MonthClosing>[
          closing(MonthKey(2026, 8), closed: true),
          closing(MonthKey(2026, 9), closed: false),
          closing(MonthKey(2026, 7), closed: true),
        ]),
        MonthKey(2026, 8),
      );
      expect(MonthCarryForwardRules.latestClosed(const <MonthClosing>[]), isNull);
    });
  });

  group('closeWindowStart', () {
    test('falls back to the start month when nothing is closed', () {
      expect(
        closeWindowStart(
          month: october,
          closings: const <MonthClosing>[],
          fundStartMonth: MonthKey(2026, 9),
        ),
        MonthKey(2026, 9),
      );
    });

    test('starts after the latest closed month', () {
      expect(
        closeWindowStart(
          month: october,
          closings: <MonthClosing>[
            closing(MonthKey(2026, 9), closed: true),
          ],
          fundStartMonth: MonthKey(2026, 1),
        ),
        october,
      );
    });

    test('never returns a month after the one being closed', () {
      // A stale start (a future month) must not make the window empty.
      expect(
        closeWindowStart(
          month: october,
          closings: const <MonthClosing>[],
          fundStartMonth: MonthKey(2027, 3),
        ),
        october,
      );
    });

    test('a family that never set up the fund closes from this month', () {
      expect(
        closeWindowStart(
          month: october,
          closings: const <MonthClosing>[],
          fundStartMonth: null,
        ),
        october,
      );
    });
  });
}
