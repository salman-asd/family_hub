import 'package:family_hub/core/audit/audit_event_type.dart';
import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/utils/money.dart';
import 'package:family_hub/core/utils/quantity.dart';
import 'package:family_hub/features/bazar/advances/domain/member_advance.dart';
import 'package:family_hub/features/bazar/expenses/domain/expense_draft.dart';
import 'package:family_hub/features/bazar/expenses/domain/funding.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../bazar_test_helpers.dart';

void main() {
  late BazarFixture f;

  setUp(() => f = BazarFixture());

  test(
    'a fund expense writes the expense and one negative ledger row',
    () async {
      final result = await f.addExpense(
        actorUid: 'alice',
        familyId: BazarFixture.familyId,
        draft: f.draft(shop: 'Karwan Bazar', note: 'weekly'),
        id: 'e1',
        eventId: 'ev1',
      );

      expect(result.valueOrNull?.id, 'e1');
      expect(f.backend.expensesOf(BazarFixture.familyId).single.id, 'e1');
      final row = f.backend.fundTransactionsOf(BazarFixture.familyId).single;
      expect(row.id, 'exp_e1');
      expect(row.amount, const Money.paisa(-10000));
      expect(row.refId, 'e1');
      expect(f.backend.advancesOf(BazarFixture.familyId), isEmpty);
      expect(
        f.backend.events
            .where((event) => event.type == AuditEventType.bazarExpenseCreated)
            .length,
        1,
      );
    },
  );

  test(
    'a reimbursable member expense writes a pending advance, no fund row',
    () async {
      final result = await f.addExpense(
        actorUid: 'alice',
        familyId: BazarFixture.familyId,
        draft: f.draft(
          funding: FundingSource.member,
          paidByMemberId: 'bob',
          reimbursable: true,
        ),
        id: 'e1',
      );

      expect(result.isSuccess, isTrue);
      expect(f.backend.fundTransactionsOf(BazarFixture.familyId), isEmpty);
      final advance = f.backend.advancesOf(BazarFixture.familyId).single;
      expect(advance.memberId, 'bob');
      expect(advance.amount, const Money.paisa(10000));
      expect(advance.settled, Money.zero);
      expect(advance.status, AdvanceStatus.pending);
    },
  );

  test('a personal member expense writes no advance and no fund row', () async {
    await f.addExpense(
      actorUid: 'alice',
      familyId: BazarFixture.familyId,
      draft: f.draft(funding: FundingSource.member, paidByMemberId: 'bob'),
      id: 'e1',
    );

    expect(f.backend.fundTransactionsOf(BazarFixture.familyId), isEmpty);
    expect(f.backend.advancesOf(BazarFixture.familyId), isEmpty);
  });

  test('item, category and payer validation happen before any write', () async {
    final missingName = await f.addExpense(
      actorUid: 'alice',
      familyId: BazarFixture.familyId,
      draft: f.draft(itemName: '  '),
      id: 'e1',
    );
    expect(
      missingName.failureOrNull,
      const Validation('itemName', 'item_name_required'),
    );

    final missingCategory = await f.addExpense(
      actorUid: 'alice',
      familyId: BazarFixture.familyId,
      draft: f.draft(categoryId: ''),
      id: 'e2',
    );
    expect(
      missingCategory.failureOrNull,
      const Validation('categoryId', 'category_required'),
    );

    final missingPayer = await f.addExpense(
      actorUid: 'alice',
      familyId: BazarFixture.familyId,
      draft: ExpenseDraft(
        dateKey: f.dateKeys.today(),
        itemName: 'চাল',
        categoryId: 'cat_food',
        typedTotal: const Money.paisa(10000),
        funding: FundingSource.member,
      ),
      id: 'e3',
    );
    expect(
      missingPayer.failureOrNull,
      const Validation('paidByMemberId', 'member_required'),
    );
    expect(f.backend.expensesOf(BazarFixture.familyId), isEmpty);
    expect(f.backend.events, isEmpty);
  });

  test('rejects a future date and a locked month', () async {
    final future = await f.addExpense(
      actorUid: 'alice',
      familyId: BazarFixture.familyId,
      draft: f.draft(date: DateTime.utc(2026, 10, 19, 9)),
      id: 'e1',
    );
    expect(future.failureOrNull, const Validation('dateKey', 'future_date'));

    f.putClosing(monthKey: f.dateKeys.today().monthKey);
    final locked = await f.addExpense(
      actorUid: 'alice',
      familyId: BazarFixture.familyId,
      draft: f.draft(),
      id: 'e2',
    );
    expect(locked.failureOrNull, const Conflict(code: 'month_locked'));
  });

  test('a pending member is denied before validation', () async {
    final result = await f.addExpense(
      actorUid: 'dave',
      familyId: BazarFixture.familyId,
      draft: f.draft(itemName: ''),
      id: 'e1',
    );

    expect(result.failureOrNull, const PermissionDenied());
    expect(f.backend.expensesOf(BazarFixture.familyId), isEmpty);
  });

  test('remembering a new item creates it without a usage bump', () async {
    final result = await f.addExpense(
      actorUid: 'alice',
      familyId: BazarFixture.familyId,
      draft: f.draft(
        itemName: 'New spice',
        unit: Unit.g,
        rememberItem: true,
        typedTotal: const Money.paisa(2500),
      ),
      id: 'e1',
      newItemId: 'item_new',
    );

    expect(result.isSuccess, isTrue);
    final item = f.backend.itemsOf(BazarFixture.familyId).single;
    expect(item.id, 'item_new');
    expect(item.nameBn, 'New spice');
    expect(item.defaultUnit, Unit.g);
    expect(item.useCount, 0);
  });

  test('a known item gets +1 usage and the last price', () async {
    f.putItem(id: 'item_rice');
    await f.addExpense(
      actorUid: 'alice',
      familyId: BazarFixture.familyId,
      draft: f.draft(
        itemId: 'item_rice',
        qty: const Quantity.milli(2000),
        unit: Unit.kg,
        unitPrice: const Money.paisa(5000),
        typedTotal: null,
      ),
      id: 'e1',
    );

    final item = f.backend.itemsOf(BazarFixture.familyId).single;
    expect(item.useCount, 1);
    expect(item.lastPrice, const Money.paisa(10000));
    expect(item.lastUnitPrice, const Money.paisa(5000));
    expect(item.lastUsedAt, f.clock.nowUtc());
  });

  test(
    'retrying the same ids keeps one expense, fund row, event and usage',
    () async {
      f.putItem(id: 'item_rice');
      for (var i = 0; i < 2; i++) {
        final result = await f.addExpense(
          actorUid: 'alice',
          familyId: BazarFixture.familyId,
          draft: f.draft(itemId: 'item_rice'),
          id: 'e1',
          eventId: 'ev1',
        );
        expect(result.isSuccess, isTrue);
      }

      expect(f.backend.expensesOf(BazarFixture.familyId).length, 1);
      expect(f.backend.fundTransactionsOf(BazarFixture.familyId).length, 1);
      expect(
        f.backend.events
            .where((event) => event.type == AuditEventType.bazarExpenseCreated)
            .length,
        1,
      );
      expect(f.backend.itemsOf(BazarFixture.familyId).single.useCount, 1);
    },
  );

  test('a repository failure is passed through and writes nothing', () async {
    f.backend.failNextWrite = const Network();
    final result = await f.addExpense(
      actorUid: 'alice',
      familyId: BazarFixture.familyId,
      draft: f.draft(),
      id: 'e1',
    );

    expect(result.failureOrNull, const Network());
    expect(f.backend.expensesOf(BazarFixture.familyId), isEmpty);
    expect(f.backend.fundTransactionsOf(BazarFixture.familyId), isEmpty);
    expect(f.backend.events, isEmpty);
  });
}
