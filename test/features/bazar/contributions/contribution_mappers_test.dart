import 'package:family_hub/core/firebase/base_mapper.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/core/utils/money.dart';
import 'package:family_hub/features/bazar/contributions/data/contribution_mappers.dart';
import 'package:family_hub/features/bazar/contributions/domain/contribution.dart';
import 'package:flutter_test/flutter_test.dart';

final DateTime _at = DateTime.utc(2026, 10, 18, 9);

BaseDocumentMetadata get _meta => BaseDocumentMetadata(
  createdAt: _at,
  createdBy: 'cara',
  updatedAt: _at,
  updatedBy: 'cara',
);

Contribution _pending() => Contribution(
  id: 'c1',
  memberId: 'cara',
  monthKey: MonthKey(2026, 10),
  dateKey: DateKey(2026, 10, 5),
  amount: const Money.paisa(100000),
  status: ContributionApproval.pending,
  requestedBy: 'cara',
  createdAt: _at,
);

void main() {
  test('a pending request leaves every decision field OUT of the map', () {
    final map = ContributionMappers.toMap(_pending(), _meta);
    for (final key in <String>[
      'fundTxId',
      'decidedBy',
      'decidedAt',
      'rejectReason',
      'pendingChange',
      'voidedAt',
      'voidedBy',
      'method',
      'note',
    ]) {
      expect(map.containsKey(key), isFalse, reason: key);
    }
    expect(map['amountPaisa'], 100000);
    expect(map['status'], 'pending');
  });

  test('a full contribution round-trips', () {
    final full = _pending().copyWith(
      status: ContributionApproval.approved,
      method: ContributionMethod.bkash,
      note: 'share',
      fundTxId: 'con_c1',
      decidedBy: 'alice',
      decidedAt: _at,
      pendingChange: ContributionChange(
        amount: const Money.paisa(120000),
        date: DateKey(2026, 10, 6),
        method: ContributionMethod.cash,
        requestedAt: _at,
      ),
    );
    final back = ContributionMappers.fromMap(
      'c1',
      ContributionMappers.toMap(full, _meta),
    );
    expect(back, full);
  });

  test('a legacy document without status is read as approved', () {
    final map = ContributionMappers.toMap(_pending(), _meta)..remove('status');
    expect(
      ContributionMappers.fromMap('c1', map)!.status,
      ContributionApproval.approved,
    );
  });

  test('a document without a usable amount or date is skipped', () {
    final map = ContributionMappers.toMap(_pending(), _meta)
      ..['amountPaisa'] = 0;
    expect(ContributionMappers.fromMap('c1', map), isNull);
  });

  test('plans round-trip and never read negative', () {
    final plan = ContributionPlan(
      month: MonthKey(2026, 10),
      memberId: 'cara',
      expected: const Money.paisa(166667),
    );
    final map = ContributionMappers.planToMap(plan, _meta);
    expect(map['expectedPaisa'], 166667);
    expect(ContributionMappers.planFromMap(map), plan);
    map['expectedPaisa'] = -5;
    expect(ContributionMappers.planFromMap(map)!.expected, Money.zero);
  });
}
