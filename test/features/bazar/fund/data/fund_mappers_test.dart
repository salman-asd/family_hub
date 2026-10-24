import 'package:family_hub/core/firebase/base_mapper.dart';
import 'package:family_hub/core/utils/clock.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/core/utils/money.dart';
import 'package:family_hub/features/bazar/fund/data/fund_mappers.dart';
import 'package:family_hub/features/bazar/fund/data/month_closing_mappers.dart';
import 'package:family_hub/features/bazar/fund/domain/fund_transaction.dart';
import 'package:family_hub/features/bazar/fund/domain/month_closing.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final at = DateTime.utc(2026, 10, 18, 9);
  final meta = BaseMapper.createMetadata(uid: 'u1', clock: FakeClock(at));
  final day = DateKey(2026, 10, 18);

  test('a signed ledger row survives a map round trip', () {
    final row = FundTransaction.forExpense(
      expenseId: 'e1',
      total: const Money.paisa(6000),
      dateKey: day,
      createdBy: 'u1',
      createdAt: at,
      note: 'bazar',
    );
    final map = FundMappers.fundTxToMap(row, meta);
    expect(map['amountPaisa'], -6000);
    expect(map['type'], 'expense');
    expect(map['refType'], 'expense');
    expect(FundMappers.fundTxFromMap(row.id, map), row);
  });

  test('a positive contribution keeps its sign', () {
    final row = FundTransaction.forContribution(
      contributionId: 'c1',
      amount: const Money.paisa(10000),
      dateKey: day,
      createdBy: 'u1',
      createdAt: at,
    );
    expect(FundMappers.fundTxToMap(row, meta)['amountPaisa'], 10000);
  });

  test('a tolerant read repairs a zero amount and unknown enum', () {
    final raw = FundMappers.fundTxToMap(
      FundTransaction.forExpense(
        expenseId: 'e1',
        total: const Money.paisa(6000),
        dateKey: day,
        createdBy: 'u1',
        createdAt: at,
      ),
      meta,
    );
    raw['amountPaisa'] = 0;
    raw['type'] = 'nonsense';
    raw['refType'] = 'nonsense';
    final restored = FundMappers.fundTxFromMap('x1', raw);
    expect(restored.amount.paisa, 1);
    expect(restored.type, FundTxType.adjustment);
    expect(restored.refType, FundRefType.manual);
  });

  test('a month closing survives a map round trip', () {
    final closing = MonthClosing(
      monthKey: MonthKey(2026, 10),
      status: MonthStatus.closed,
      closedAt: at,
      closedBy: 'u1',
      closingBalance: const Money.paisa(6000),
      reopenedAt: at.add(const Duration(hours: 1)),
      reopenedBy: 'u2',
      reopenNote: 'wrong month',
      reopenCount: 1,
    );
    final map = MonthClosingMappers.closingToMap(closing, meta);
    expect(map['monthKey'], '2026-10');
    expect(map['closingBalancePaisa'], 6000);
    expect(MonthClosingMappers.closingFromMap('2026-10', map), closing);
  });

  test('a malformed closing falls back to open/zero', () {
    final restored = MonthClosingMappers.closingFromMap(
      '2026-10',
      <String, dynamic>{'status': 'weird', 'reopenCount': 'many'},
    );
    expect(restored.status, MonthStatus.open);
    expect(restored.reopenCount, 0);
  });
}
