import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/core/utils/date_ranges.dart';
import 'package:family_hub/core/utils/money.dart';
import 'package:family_hub/features/bazar/expenses/domain/expense.dart';
import 'package:family_hub/features/bazar/expenses/domain/funding.dart';
import 'package:family_hub/features/bazar/reports/domain/report_loader.dart';
import 'package:family_hub/features/bazar/reports/domain/report_query.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/in_memory_bazar_backend.dart';

/// P2-24: the paged range loader respects the cap and reports truncation.
void main() {
  const String familyId = 'f1';
  final at = DateTime.utc(2026, 10, 18, 9);

  late InMemoryBazarBackend backend;

  setUp(() => backend = InMemoryBazarBackend());

  Expense expense(int index, {FundingSource funding = FundingSource.fund}) {
    final day = DateKey(2026, 10, (index % 28) + 1);
    return Expense(
      id: 'e${index.toString().padLeft(5, '0')}',
      dateKey: day,
      monthKey: day.monthKey,
      occurredAt: at,
      itemName: 'item $index',
      categoryId: index.isEven ? 'cat_a' : 'cat_b',
      total: Money.paisa(100 + index),
      funding: funding,
      paidByMemberId: funding == FundingSource.member ? 'cara' : null,
      purchaserId: index % 3 == 0 ? 'bob' : null,
      createdBy: 'alice',
      createdAt: at,
    );
  }

  void seed(int count) {
    final map = backend.expenses[familyId] ??= <String, Expense>{};
    for (var i = 0; i < count; i++) {
      final row = expense(i);
      map[row.id] = row;
    }
  }

  final query = ReportQuery(
    preset: RangePreset.thisMonth,
    range: monthRange(MonthKey(2026, 10)),
  );

  test('one short page is the whole range and is not truncated', () async {
    seed(3);
    final result = await loadRange(backend, familyId, query);
    final load = result.valueOrNull!;
    expect(load.count, 3);
    expect(load.truncated, isFalse);
  });

  test('several pages are followed until a short page', () async {
    seed(45);
    final result = await loadRange(
      backend,
      familyId,
      query,
      pageSize: 20,
      maxDocs: 1000,
    );
    final load = result.valueOrNull!;
    expect(load.count, 45);
    expect(load.truncated, isFalse);
    expect(load.expenses.map((e) => e.id).toSet(), hasLength(45));
  });

  test('the cap marks the load truncated', () async {
    seed(50);
    final result = await loadRange(
      backend,
      familyId,
      query,
      pageSize: 20,
      maxDocs: 25,
    );
    final load = result.valueOrNull!;
    expect(load.count, 25);
    expect(load.truncated, isTrue);
  });

  test('a cap that is an exact multiple of the page size is not truncated', () async {
    seed(20);
    final result = await loadRange(
      backend,
      familyId,
      query,
      pageSize: 20,
      maxDocs: 40,
    );
    final load = result.valueOrNull!;
    expect(load.count, 20);
    expect(load.truncated, isFalse);
  });

  test('a read failure is returned, never a partial report', () async {
    seed(60);
    // The first page succeeds, the second fails: nothing partial is returned.
    backend.failNextRangeRead = const Network();
    final result = await loadRange(
      backend,
      familyId,
      query,
      pageSize: 10,
      maxDocs: 1000,
    );
    expect(result.failureOrNull, isA<Network>());
    expect(result.valueOrNull, isNull);
  });

  test('the member filter is pushed to the query, not the report', () async {
    seed(10);
    final filtered = ReportQuery(
      preset: RangePreset.thisMonth,
      range: monthRange(MonthKey(2026, 10)),
      memberId: 'bob',
    );
    final load = (await loadRange(backend, familyId, filtered)).valueOrNull!;
    expect(load.expenses, isNotEmpty);
    expect(load.expenses.every((e) => e.purchaserId == 'bob'), isTrue);
  });

  test('soft-deleted rows stay in the load and the engine drops them', () async {
    seed(2);
    final gone = backend.expenses[familyId]!['e00000']!.copyWith(
      deletedAt: at,
      deletedBy: 'alice',
    );
    backend.expenses[familyId]!['e00000'] = gone;

    final load = (await loadRange(backend, familyId, query)).valueOrNull!;
    expect(load.count, 2, reason: 'the loader returns what the range holds');
  });
}
