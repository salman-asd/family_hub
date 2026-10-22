import 'package:family_hub/core/audit/audit_event.dart';
import 'package:family_hub/core/audit/audit_event_type.dart';
import 'package:family_hub/core/audit/audit_ref_type.dart';
import 'package:family_hub/core/firebase/base_mapper.dart';
import 'package:family_hub/core/firebase/fake_tx_runner.dart';
import 'package:family_hub/core/firebase/firestore_paths.dart';
import 'package:family_hub/core/utils/clock.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/core/utils/money.dart';
import 'package:family_hub/core/utils/quantity.dart';
import 'package:family_hub/features/bazar/advances/domain/member_advance.dart';
import 'package:family_hub/features/bazar/expenses/data/expense_mappers.dart';
import 'package:family_hub/features/bazar/expenses/data/firestore_expense_repository.dart';
import 'package:family_hub/features/bazar/expenses/domain/expense.dart';
import 'package:family_hub/features/bazar/expenses/domain/expense_repository.dart';
import 'package:family_hub/features/bazar/expenses/domain/funding.dart';
import 'package:family_hub/features/bazar/expenses/domain/trip.dart';
import 'package:family_hub/features/bazar/expenses/domain/write_plans.dart';
import 'package:family_hub/features/bazar/fund/domain/fund_transaction.dart';
import 'package:family_hub/features/bazar/items_categories/domain/item.dart';
import 'package:family_hub/features/bazar/items_categories/domain/item_usage_bump.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final at = DateTime.utc(2026, 10, 18, 9);
  final day = DateKey(2026, 10, 18);
  late FakeClock clock;
  late FakeTxRunner tx;
  late FirestoreExpenseRepository repository;

  setUp(() {
    clock = FakeClock(at);
    tx = FakeTxRunner(null, clock);
    repository = FirestoreExpenseRepository(tx: tx, clock: clock);
  });

  AuditEvent event(String id, String type, String refType, String refId) =>
      AuditEvent(
        id: id,
        type: type,
        actorId: 'u1',
        refType: refType,
        refId: refId,
        at: clock.nowUtc(),
      );

  Expense expense(
    String id, {
    FundingSource funding = FundingSource.fund,
    String? payer,
    bool reimbursable = false,
    Money total = const Money.paisa(12000),
    DateTime? deletedAt,
    String? deletedBy,
  }) => Expense(
    id: id,
    dateKey: day,
    monthKey: day.monthKey,
    occurredAt: at,
    itemId: 'i1',
    itemName: 'Rice',
    categoryId: 'c1',
    qty: const Quantity.milli(1000),
    unit: Unit.kg,
    unitPrice: const Money.paisa(6000),
    total: total,
    funding: funding,
    paidByMemberId: payer,
    reimbursable: reimbursable,
    purchaserId: 'u1',
    shop: 'Bazar',
    deletedAt: deletedAt,
    deletedBy: deletedBy,
    createdBy: 'u1',
    createdAt: at,
  );

  Map<String, dynamic> seedExpense(Expense row) =>
      tx.store[FirestorePaths.expenseDoc(
        'f1',
        row.id,
      )] = ExpenseMappers.expenseToMap(
        row,
        BaseMapper.createMetadata(uid: 'u1', clock: clock),
      );

  test('commitAdd stages the expense, fund row and both logs', () async {
    final row = expense('e1');
    final fundRow = FundTransaction.forExpense(
      expenseId: row.id,
      total: row.total,
      dateKey: day,
      createdBy: 'u1',
      createdAt: at,
    );
    final result = await repository.commitAdd(
      'f1',
      ExpenseWritePlan(expense: row, fundTx: fundRow),
      event(
        'ev1',
        AuditEventType.bazarExpenseCreated,
        AuditRefType.expense,
        row.id,
      ),
    );

    expect(result.failureOrNull, isNull);
    final document = tx.store[FirestorePaths.expenseDoc('f1', 'e1')]!;
    expect(document['totalPaisa'], 12000);
    expect(document['fundingSource'], 'fund');
    expect(document['dateKey'], '2026-10-18');
    final ledger = tx.store[FirestorePaths.fundTransactionDoc('f1', 'exp_e1')]!;
    expect(ledger['amountPaisa'], -12000);
    expect(ledger['type'], 'expense');
    expect(tx.store[FirestorePaths.activityDoc('f1', 'ev1')], isNotNull);
    expect(tx.store[FirestorePaths.auditLogDoc('f1', 'ev1')], isNotNull);
  });

  test('commitAdd stages an advance, a new item and a usage bump', () async {
    tx.store[FirestorePaths.bazarItemDoc('f1', 'i_existing')] =
        <String, dynamic>{'useCount': 0};
    final row = expense(
      'e2',
      funding: FundingSource.member,
      payer: 'u1',
      reimbursable: true,
    );
    final advance = MemberAdvance(
      expenseId: row.id,
      memberId: 'u1',
      amount: row.total,
      settled: Money.zero,
      status: AdvanceStatus.pending,
      dateKey: day,
      monthKey: day.monthKey,
    );
    final newItem = Item(
      id: 'i_new',
      nameBn: 'ডাল',
      categoryId: 'c1',
      defaultUnit: Unit.kg,
    );
    final bump = ItemUsageBump(
      itemId: 'i_existing',
      increments: 1,
      lastPrice: row.total,
      lastUnitPrice: row.unitPrice,
      at: at,
    );

    final result = await repository.commitAdd(
      'f1',
      ExpenseWritePlan(
        expense: row,
        advance: advance,
        usage: bump,
        newItem: newItem,
      ),
      event(
        'ev2',
        AuditEventType.bazarExpenseCreated,
        AuditRefType.expense,
        row.id,
      ),
    );

    expect(result.failureOrNull, isNull);
    final storedAdvance =
        tx.store[FirestorePaths.memberAdvanceDoc('f1', 'e2')]!;
    expect(storedAdvance['amountPaisa'], 12000);
    expect(storedAdvance['status'], 'pending');
    expect(
      tx.store[FirestorePaths.bazarItemDoc('f1', 'i_new')]!['nameBn'],
      'ডাল',
    );
    expect(
      tx.store[FirestorePaths.bazarItemDoc('f1', 'i_existing')]!['useCount'],
      isNot(0),
    );
  });

  test('commitTrip stages a 40-line trip well under the batch cap', () async {
    final lines = <ExpenseWritePlan>[
      for (var i = 0; i < 40; i++)
        _line(expense('e_t$i', total: const Money.paisa(1000)), day, at),
    ];
    final trip = Trip(
      id: 't1',
      dateKey: day,
      monthKey: day.monthKey,
      funding: FundingSource.fund,
      lineCount: 40,
      total: const Money.paisa(40000),
    );

    final result = await repository.commitTrip(
      'f1',
      TripWritePlan(trip: trip, lines: lines, usage: const <ItemUsageBump>[]),
      event('ev3', AuditEventType.bazarTripCreated, AuditRefType.trip, trip.id),
    );

    expect(result.failureOrNull, isNull);
    expect(tx.store.length, 83);
    expect(tx.store[FirestorePaths.bazarTripDoc('f1', 't1')]!['lineCount'], 40);
    expect(tx.store[FirestorePaths.expenseDoc('f1', 'e_t39')], isNotNull);
    expect(
      tx.store[FirestorePaths.fundTransactionDoc('f1', 'exp_e_t39')],
      isNotNull,
    );
  });

  test(
    'commitEdit updates the row, appends a revision and repairs the ledger',
    () async {
      final old = expense('e3');
      seedExpense(old);
      final updated = expense('e3', total: const Money.paisa(15000));
      final adjustment = FundTransaction.adjustment(
        eventId: 'ev4',
        amount: const Money.paisa(-3000),
        dateKey: day,
        refType: FundRefType.expense,
        refId: old.id,
        createdBy: 'u1',
        createdAt: at,
      );

      final result = await repository.commitEdit(
        'f1',
        ExpenseEditPlan(
          updated: updated,
          before: const <String, Object?>{'totalPaisa': 12000},
          changedFields: const <String>['totalPaisa'],
          adjustments: <FundTransaction>[adjustment],
        ),
        event(
          'ev4',
          AuditEventType.bazarExpenseUpdated,
          AuditRefType.expense,
          old.id,
        ),
      );

      expect(result.failureOrNull, isNull);
      expect(
        tx.store[FirestorePaths.expenseDoc('f1', 'e3')]!['totalPaisa'],
        15000,
      );
      expect(
        tx.store[FirestorePaths.expenseRevisionDoc(
          'f1',
          'e3',
          'ev4',
        )]!['changedFields'],
        <String>['totalPaisa'],
      );
      expect(
        tx.store[FirestorePaths.fundTransactionDoc(
          'f1',
          'adj_ev4',
        )]!['amountPaisa'],
        -3000,
      );
      expect(
        tx.store[FirestorePaths.expenseDoc('f1', 'e3')]!['createdAt'],
        isNotNull,
      );
    },
  );

  test('commitEdit inserts a missing advance with set', () async {
    final old = expense('e5', funding: FundingSource.member, payer: 'u1');
    seedExpense(old);
    final updated = expense(
      'e5',
      funding: FundingSource.member,
      payer: 'u1',
      reimbursable: true,
    );
    final advance = MemberAdvance(
      expenseId: updated.id,
      memberId: 'u1',
      amount: updated.total,
      settled: Money.zero,
      status: AdvanceStatus.pending,
      dateKey: day,
      monthKey: day.monthKey,
    );

    final result = await repository.commitEdit(
      'f1',
      ExpenseEditPlan(
        updated: updated,
        before: const <String, Object?>{'reimbursable': false},
        changedFields: const <String>['reimbursable'],
        adjustments: const <FundTransaction>[],
        advanceChange: AdvanceChange(after: advance, isNew: true),
      ),
      event(
        'ev5',
        AuditEventType.bazarExpenseUpdated,
        AuditRefType.expense,
        old.id,
      ),
    );

    expect(result.failureOrNull, isNull);
    expect(
      tx.store[FirestorePaths.memberAdvanceDoc('f1', 'e5')]!['status'],
      'pending',
    );
  });

  test(
    'commitDelete stamps the row, voids the advance and repairs the ledger',
    () async {
      final old = expense('e6');
      seedExpense(old);
      final deleted = expense('e6', deletedAt: at, deletedBy: 'u1');
      final adjustment = FundTransaction.adjustment(
        eventId: 'ev6',
        amount: old.total,
        dateKey: day,
        refType: FundRefType.expense,
        refId: old.id,
        createdBy: 'u1',
        createdAt: at,
        suffix: 'del',
      );

      final result = await repository.commitDelete(
        'f1',
        ExpenseDeletePlan(
          updated: deleted,
          before: const <String, Object?>{'deletedAt': null},
          adjustments: <FundTransaction>[adjustment],
        ),
        event(
          'ev6',
          AuditEventType.bazarExpenseDeleted,
          AuditRefType.expense,
          old.id,
        ),
      );

      expect(result.failureOrNull, isNull);
      final document = tx.store[FirestorePaths.expenseDoc('f1', 'e6')]!;
      expect(document['deletedBy'], 'u1');
      expect(BaseMapper.timestampToDateTime(document['deletedAt']), at);
      expect(
        tx.store[FirestorePaths.fundTransactionDoc('f1', 'adj_ev6_del')],
        isNotNull,
      );
      expect(
        tx.store[FirestorePaths.expenseRevisionDoc('f1', 'e6', 'ev6')],
        isNotNull,
      );
    },
  );

  test('commitRestore clears the stamps and appends a reversal row', () async {
    final old = expense('e7', deletedAt: at, deletedBy: 'u1');
    seedExpense(old);
    final restored = expense('e7');
    final adjustment = FundTransaction.adjustment(
      eventId: 'ev7',
      amount: const Money.paisa(-12000),
      dateKey: day,
      refType: FundRefType.expense,
      refId: old.id,
      createdBy: 'u1',
      createdAt: at,
      suffix: 'res',
    );

    final result = await repository.commitRestore(
      'f1',
      ExpenseRestorePlan(
        updated: restored,
        before: <String, Object?>{
          'deletedAt': BaseMapper.dateTimeToTimestamp(at),
        },
        adjustments: <FundTransaction>[adjustment],
      ),
      event(
        'ev7',
        AuditEventType.bazarExpenseRestored,
        AuditRefType.expense,
        old.id,
      ),
    );

    expect(result.failureOrNull, isNull);
    final document = tx.store[FirestorePaths.expenseDoc('f1', 'e7')]!;
    expect(document['deletedAt'], isNull);
    expect(document['deletedBy'], isNull);
    expect(
      tx.store[FirestorePaths.fundTransactionDoc('f1', 'adj_ev7_res')],
      isNotNull,
    );
  });

  test('a rejected batch returns a Failure and writes nothing', () async {
    tx.failNextBatchWith = StateError('offline');
    final row = expense('e8');

    final result = await repository.commitAdd(
      'f1',
      ExpenseWritePlan(expense: row),
      event(
        'ev8',
        AuditEventType.bazarExpenseCreated,
        AuditRefType.expense,
        row.id,
      ),
    );

    expect(result.failureOrNull, isNotNull);
    expect(tx.store, isEmpty);
  });
}

ExpenseWritePlan _line(Expense row, DateKey day, DateTime at) =>
    ExpenseWritePlan(
      expense: row,
      fundTx: FundTransaction.forExpense(
        expenseId: row.id,
        total: row.total,
        dateKey: day,
        createdBy: 'u1',
        createdAt: at,
      ),
    );
