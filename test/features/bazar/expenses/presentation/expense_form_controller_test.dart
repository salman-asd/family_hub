import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/core/utils/money.dart';
import 'package:family_hub/core/utils/quantity.dart';
import 'package:family_hub/features/bazar/advances/domain/member_advance.dart';
import 'package:family_hub/features/bazar/expenses/presentation/controllers/expense_form_controller.dart';
import 'package:family_hub/features/bazar/expenses/presentation/controllers/expense_form_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../bazar_test_helpers.dart';
import 'expense_test_container.dart';

void main() {
  late BazarFixture fx;
  const args = ExpenseFormArgs();

  setUp(() => fx = BazarFixture());

  ProviderContainer make({ExpenseFormArgs a = args}) {
    final c = ProviderContainer(overrides: bazarOverrides(fx));
    addTearDown(c.dispose);
    final sub = c.listen(expenseFormProvider(a), (_, _) {});
    addTearDown(sub.close);
    return c;
  }

  Future<void> pump() async {
    for (var i = 0; i < 4; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  ExpenseFormController formOf(ProviderContainer c, [ExpenseFormArgs a = args]) =>
      c.read(expenseFormProvider(a).notifier);
  ExpenseFormState stateOf(ProviderContainer c, [ExpenseFormArgs a = args]) =>
      c.read(expenseFormProvider(a));

  void fill(ExpenseFormController form, {String total = '120'}) {
    form
      ..chooseNewItem('চাল')
      ..setCategory('cat_food')
      ..setTotal(total);
  }

  test('a typed total is saved from the fund with one ledger row', () async {
    final c = make();
    fill(formOf(c));

    final outcome = await formOf(c).save(addAnother: false);

    expect(outcome?.expense.total, const Money.paisa(12000));
    final saved = fx.backend.expensesOf(BazarFixture.familyId).single;
    expect(saved.itemName, 'চাল');
    expect(saved.dateKey, DateKey(2026, 10, 18));
    expect(
      fx.backend.fundTransactionsOf(BazarFixture.familyId).single.amount,
      const Money.paisa(-12000),
    );
  });

  test('quantity x unit price is calculated and saved with the pair', () async {
    final c = make();
    fill(formOf(c), total: '');
    formOf(c)
      ..setQty('2.5')
      ..setUnit(Unit.kg)
      ..setUnitPrice('80');

    expect(stateOf(c).amount.total, const Money.paisa(20000));
    final outcome = await formOf(c).save(addAnother: false);

    expect(outcome?.expense.total, const Money.paisa(20000));
    expect(outcome?.expense.unit, Unit.kg);
    expect(outcome?.expense.unitPrice, const Money.paisa(8000));
  });

  test('an incomplete form shows every error and writes nothing', () async {
    final c = make();
    final before = stateOf(c);

    final outcome = await formOf(c).save(addAnother: false);

    expect(outcome, isNull);
    final errors = stateOf(c).fieldErrors;
    expect(errors['itemName'], 'item_name_required');
    expect(errors['categoryId'], 'category_required');
    expect(errors['total'], 'invalid_amount');
    expect(fx.backend.expensesOf(BazarFixture.familyId), isEmpty);
    // The ids survive a failed save, so a retry rewrites the same documents.
    expect(stateOf(c).expenseId, before.expenseId);
    expect(stateOf(c).eventId, before.eventId);
  });

  test('a future date is refused and the date is kept', () {
    final c = make();
    formOf(c).setDate(DateKey(2026, 10, 19));
    expect(stateOf(c).fieldErrors['dateKey'], 'future_date');
    expect(stateOf(c).date, DateKey(2026, 10, 18));

    formOf(c).setDate(DateKey(2026, 10, 10));
    expect(stateOf(c).date, DateKey(2026, 10, 10));
    expect(stateOf(c).fieldErrors, isEmpty);
  });

  test('a member-paid expense needs a payer and writes an advance', () async {
    final c = make();
    fill(formOf(c));
    formOf(c)
      ..setFunding(FundingChoice.memberReimbursable)
      ..setPaidBy(null);
    expect(await formOf(c).save(addAnother: false), isNull);
    expect(stateOf(c).fieldErrors['paidByMemberId'], 'member_required');

    formOf(c).setPaidBy('bob');
    final outcome = await formOf(c).save(addAnother: false);

    expect(outcome, isNotNull);
    final advance = fx.backend.advancesOf(BazarFixture.familyId).single;
    expect(advance.memberId, 'bob');
    expect(advance.status, AdvanceStatus.pending);
    expect(fx.backend.fundTransactionsOf(BazarFixture.familyId), isEmpty);
  });

  test('selecting an item fills category, unit and the price hint', () {
    fx.putCategory();
    final item = fx.putItem(lastUnitPrice: const Money.paisa(8000));
    final c = make();

    formOf(c).selectItem(item);

    final s = stateOf(c);
    expect(s.item?.id, item.id);
    expect(s.categoryId, 'cat_food');
    expect(s.unit, Unit.kg);
    expect(s.unitPriceHint, const Money.paisa(8000));
    expect(s.unitPriceText, isEmpty, reason: 'a hint is never a value');

    formOf(c).typeItem('চালে');
    expect(stateOf(c).item, isNull);
    expect(stateOf(c).unitPriceHint, isNull);
  });

  test('a duplicate is a warning; Save anyway writes it', () async {
    final c = make();
    fill(formOf(c));
    await formOf(c).save(addAnother: true);
    fill(formOf(c));

    final blocked = await formOf(c).save(addAnother: false);

    expect(blocked, isNull);
    expect(stateOf(c).duplicate, isNotNull);
    expect(stateOf(c).saving, isFalse);
    expect(fx.backend.expensesOf(BazarFixture.familyId), hasLength(1));

    final confirmed = await formOf(c).saveConfirmed(addAnother: false);
    expect(confirmed, isNotNull);
    expect(fx.backend.expensesOf(BazarFixture.familyId), hasLength(2));
  });

  test('Save and add another keeps date, shop and funding only', () async {
    final c = make();
    fill(formOf(c));
    formOf(c)
      ..setDate(DateKey(2026, 10, 12))
      ..setShop('Karwan Bazar')
      ..setNote('weekly');
    final before = stateOf(c);

    final outcome = await formOf(c).save(addAnother: true);

    expect(outcome?.addAnother, isTrue);
    final s = stateOf(c);
    expect(s.date, DateKey(2026, 10, 12));
    expect(s.shop, 'Karwan Bazar');
    expect(s.itemName, isEmpty);
    expect(s.totalText, isEmpty);
    expect(s.note, isEmpty);
    expect(s.expenseId, isNot(before.expenseId));
    expect(s.saving, isFalse);
  });

  test('a locked month refuses the save with MonthLocked', () async {
    final c = make();
    fill(formOf(c));
    formOf(c).setDate(DateKey(2026, 9, 5));
    fx.putClosing(monthKey: MonthKey(2026, 9));

    final outcome = await formOf(c).save(addAnother: false);

    expect(outcome, isNull);
    expect(stateOf(c).failure, isA<Conflict>());
    expect(stateOf(c).saving, isFalse);
  });

  group('edit mode', () {
    test('loads the expense, saves a change and keeps the old total in history',
        () async {
      await fx.addExpense(
        actorUid: 'alice',
        familyId: BazarFixture.familyId,
        draft: fx.draft(typedTotal: const Money.paisa(10000)),
        id: 'e1',
        eventId: 'ev1',
      );
      const editArgs = ExpenseFormArgs(editingId: 'e1');
      final c = make(a: editArgs);
      expect(stateOf(c, editArgs).load, ExpenseFormLoad.loading);
      await pump();

      final loaded = stateOf(c, editArgs);
      expect(loaded.load, ExpenseFormLoad.ready);
      expect(loaded.editing, isTrue);
      expect(loaded.totalText, '100');
      expect(loaded.itemName, 'চাল');

      formOf(c, editArgs).setTotal('150');
      final outcome = await formOf(c, editArgs).save(addAnother: false);

      expect(outcome?.expense.total, const Money.paisa(15000));
      expect(
        fx.backend.expensesOf(BazarFixture.familyId).single.total,
        const Money.paisa(15000),
      );
    });

    test('a missing expense fails to load with NotFound', () async {
      const editArgs = ExpenseFormArgs(editingId: 'nope');
      final c = make(a: editArgs);
      await pump();
      expect(stateOf(c, editArgs).load, ExpenseFormLoad.failed);
      expect(stateOf(c, editArgs).failure, isA<NotFound>());
    });
  });
}
