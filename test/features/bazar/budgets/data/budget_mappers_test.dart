import 'package:family_hub/core/firebase/base_mapper.dart';
import 'package:family_hub/core/firebase/fake_tx_runner.dart';
import 'package:family_hub/core/firebase/firestore_paths.dart';
import 'package:family_hub/core/audit/audit_event.dart';
import 'package:family_hub/core/audit/audit_event_type.dart';
import 'package:family_hub/core/audit/audit_ref_type.dart';
import 'package:family_hub/core/utils/clock.dart';
import 'package:family_hub/core/utils/money.dart';
import 'package:family_hub/features/bazar/budgets/data/budget_mappers.dart';
import 'package:family_hub/features/bazar/budgets/data/firestore_budget_repository.dart';
import 'package:family_hub/features/bazar/budgets/domain/budget.dart';
import 'package:flutter_test/flutter_test.dart';

import '../budget_test_helpers.dart';

void main() {
  final at = DateTime.utc(2026, 10, 18, 9);
  final meta = BaseMapper.createMetadata(uid: 'u1', clock: FakeClock(at));
  final budget = sampleBudget(
    BudgetFixture.october,
    total: const Money.paisa(864000),
    categories: const {'cat_dry_groceries': Money.paisa(470000)},
    lines: const [riceLine, oilLine],
  );

  test('stores integer paisa / milli and the month key', () {
    final map = BudgetMappers.toMap(budget, meta);
    expect(map['monthKey'], '2026-10');
    expect(map['totalEstimatePaisa'], 864000);
    expect(map['categoryEstimates'], {'cat_dry_groceries': 470000});
    expect(map['alertThresholds'], [80, 100]);
    final lines = map['lines'] as List<Object?>;
    expect(lines.first, {
      'name': 'Rice',
      'plannedQtyMilli': 50000,
      'unit': 'kg',
      'estimatedRatePaisa': 7000,
      'estimatedTotalPaisa': 350000,
      'stockMilli': 5000,
    });
    // Absent optional values are omitted, not null.
    expect(lines.last, {'name': 'Oil', 'estimatedTotalPaisa': 120000});
  });

  test('round trip keeps every field and the author', () {
    final map = BudgetMappers.toMap(budget, meta);
    final back = BudgetMappers.fromMap('2026-10', map)!;
    expect(back, budget);
    expect(back.createdBy, 'u1');
    expect(back.createdAt!.isAtSameMomentAs(at), isTrue);
  });

  test('tolerates damaged documents', () {
    final back = BudgetMappers.fromMap('2026-10', <String, dynamic>{
      'totalEstimatePaisa': -5,
      'categoryEstimates': {'a': 100, 'b': 'x', 'c': -1},
      'lines': [
        'junk',
        {'name': ''},
        {'name': 'ok', 'estimatedTotalPaisa': 700, 'unit': 'bogus'},
      ],
      'alertThresholds': [90, 80],
    })!;
    expect(back.month, BudgetFixture.october);
    expect(back.totalEstimate, Money.zero);
    expect(back.categoryEstimates, {'a': const Money.paisa(100)});
    expect(back.lines.single.name, 'ok');
    expect(back.lines.single.unit, isNull);
    expect(back.alertThresholds, kDefaultBudgetThresholds);
    expect(back.createdBy, isNull);
  });

  test('an unreadable month id gives null', () {
    expect(BudgetMappers.fromMap('nope', <String, dynamic>{}), isNull);
  });

  group('FirestoreBudgetRepository.saveBudget', () {
    late FakeTxRunner tx;
    late FirestoreBudgetRepository repository;
    AuditEvent event(String actor) => AuditEvent(
      id: 'e1',
      type: AuditEventType.bazarBudgetSaved,
      actorId: actor,
      refType: AuditRefType.budget,
      refId: '2026-10',
      at: at,
      params: const {'month': '2026-10', 'amount': '864000'},
    );

    setUp(() {
      tx = FakeTxRunner(null, FakeClock(at));
      repository = FirestoreBudgetRepository(tx: tx);
    });

    test('writes the budget and both log entries in one batch', () async {
      final result = await repository.saveBudget('f1', budget, event('u1'));
      expect(result.failureOrNull, isNull);
      final doc = tx.store[FirestorePaths.budgetDoc('f1', '2026-10')]!;
      expect(doc['totalEstimatePaisa'], 864000);
      expect(doc['createdBy'], 'u1');
      expect(doc['updatedBy'], 'u1');
      expect(tx.store[FirestorePaths.activityDoc('f1', 'e1')], isNotNull);
      expect(tx.store[FirestorePaths.auditLogDoc('f1', 'e1')], isNotNull);
    });

    test('a re-save keeps the original author', () async {
      final carried = budget.copyWith(createdAt: at, createdBy: 'alice');
      await repository.saveBudget('f1', carried, event('bob'));
      final doc = tx.store[FirestorePaths.budgetDoc('f1', '2026-10')]!;
      expect(doc['createdBy'], 'alice');
      expect(doc['updatedBy'], 'bob');
    });
  });
}
