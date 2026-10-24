import 'package:family_hub/core/utils/money.dart';
import 'package:family_hub/features/bazar/expenses/domain/trip_limits.dart';
import 'package:family_hub/features/bazar/expenses/presentation/controllers/expense_form_state.dart';
import 'package:family_hub/features/bazar/expenses/presentation/controllers/trip_form_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../bazar_test_helpers.dart';
import 'expense_test_container.dart';

void main() {
  late BazarFixture fx;
  setUp(() => fx = BazarFixture());

  ProviderContainer make() {
    final c = ProviderContainer(overrides: bazarOverrides(fx));
    addTearDown(c.dispose);
    final sub = c.listen(tripFormProvider, (_, _) {});
    addTearDown(sub.close);
    return c;
  }

  TripLineDraft line(String id, int paisa, {String name = 'আলু'}) =>
      TripLineDraft(
        id: id,
        itemName: name,
        categoryId: 'cat_food',
        typedTotal: Money.paisa(paisa),
        total: Money.paisa(paisa),
      );

  test('lines add up and Undo puts a removed line back in place', () {
    final c = make();
    final form = c.read(tripFormProvider.notifier);
    form
      ..addLine(line('l1', 1000))
      ..addLine(line('l2', 2500, name: 'পেঁয়াজ'))
      ..addLine(line('l3', 500, name: 'ডিম'));
    expect(c.read(tripFormProvider).total, const Money.paisa(4000));

    final removed = form.removeLine(1)!;
    expect(c.read(tripFormProvider).total, const Money.paisa(1500));

    form.insertLine(1, removed);
    expect(
      c.read(tripFormProvider).lines.map((l) => l.id),
      ['l1', 'l2', 'l3'],
    );
  });

  test('a trip stops at the line cap', () {
    final c = make();
    final form = c.read(tripFormProvider.notifier);
    for (var i = 0; i < kMaxTripLines; i++) {
      expect(form.addLine(line('l$i', 100)), isTrue);
    }
    expect(form.addLine(line('extra', 100)), isFalse);
    expect(c.read(tripFormProvider).atLineLimit, isTrue);
  });

  test('Save writes every line, linked by one trip id, in one go', () async {
    final c = make();
    final form = c.read(tripFormProvider.notifier)
      ..setShop('Karwan Bazar')
      ..addLine(line('l1', 1000))
      ..addLine(line('l2', 2500, name: 'পেঁয়াজ'));

    final trip = await form.save();

    expect(trip, isNotNull);
    final rows = fx.backend.expensesOf(BazarFixture.familyId);
    expect(rows, hasLength(2));
    expect(rows.map((e) => e.tripId).toSet(), hasLength(1));
    expect(rows.every((e) => e.shop == 'Karwan Bazar'), isTrue);
    expect(
      fx.backend.fundTransactionsOf(BazarFixture.familyId),
      hasLength(2),
    );
  });

  test('an empty trip is not saved; a member-paid one needs a payer', () async {
    final c = make();
    final form = c.read(tripFormProvider.notifier);
    expect(await form.save(), isNull);

    form
      ..addLine(line('l1', 1000))
      ..setFunding(FundingChoice.memberReimbursable)
      ..setPaidBy(null);
    expect(await form.save(), isNull);
    expect(
      c.read(tripFormProvider).fieldErrors['paidByMemberId'],
      'member_required',
    );
    expect(fx.backend.expensesOf(BazarFixture.familyId), isEmpty);
  });
}
