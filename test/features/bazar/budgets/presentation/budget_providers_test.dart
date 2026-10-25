import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/core/utils/money.dart';
import 'package:family_hub/core/utils/quantity.dart';
import 'package:family_hub/features/bazar/budgets/domain/budget.dart';
import 'package:family_hub/features/bazar/budgets/domain/budget_status.dart';
import 'package:family_hub/features/bazar/budgets/presentation/budget_providers.dart';
import 'package:family_hub/features/bazar/budgets/presentation/controllers/budget_controller.dart';
import 'package:family_hub/features/bazar/expenses/presentation/expense_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../expenses/presentation/expense_test_container.dart';
import '../budget_test_helpers.dart';

void main() {
  late BudgetFixture f;

  setUp(() => f = BudgetFixture());

  ProviderContainer make() {
    final container = ProviderContainer(
      overrides: [
        ...bazarOverrides(f.fx),
        budgetRepositoryProvider.overrideWithValue(f.repository),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  Future<void> pump() async {
    for (var i = 0; i < 4; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  T keep<T>(ProviderContainer c, ProviderListenable<T> p) {
    final sub = c.listen<T>(p, (_, _) {});
    addTearDown(sub.close);
    return sub.read();
  }

  test('the budget stream follows saves', () async {
    final c = make();
    keep(c, monthBudgetProvider(BudgetFixture.october));
    await pump();
    expect(c.read(monthBudgetProvider(BudgetFixture.october)).value, isNull);

    await f.save(
      actorUid: 'alice',
      familyId: BudgetFixture.familyId,
      budget: sampleBudget(
        BudgetFixture.october,
        total: const Money.paisa(777),
      ),
    );
    await pump();
    expect(
      c.read(monthBudgetProvider(BudgetFixture.october)).value!.totalEstimate,
      const Money.paisa(777),
    );
  });

  test('status moves when an expense is added, using the family levels', () async {
    f.fx.putCategory();
    f.repository.stored[BudgetFixture.october] = sampleBudget(
      BudgetFixture.october,
      total: const Money.paisa(10000),
      categories: const {'cat_food': Money.paisa(10000)},
    );
    final c = make();
    keep(c, budgetStatusProvider(BudgetFixture.october));
    await pump();
    expect(
      c.read(budgetStatusProvider(BudgetFixture.october)).total.level,
      BudgetLevel.ok,
    );

    f.fx.putExpense(id: 'e1', total: const Money.paisa(8500));
    f.fx.backend.expenseNotify();
    await pump();
    final report = c.read(budgetStatusProvider(BudgetFixture.october));
    expect(report.total.level, BudgetLevel.warning);
    expect(report.byCategory['cat_food']!.percentBp, 8500);
  });

  test('alerts are for the current month only, worst first', () async {
    f.fx.putCategory();
    f.repository.stored[BudgetFixture.october] = sampleBudget(
      BudgetFixture.october,
      total: const Money.paisa(100000),
      categories: const {'cat_food': Money.paisa(10000)},
    );
    f.repository.stored[BudgetFixture.september] = sampleBudget(
      BudgetFixture.september,
      total: const Money.paisa(1),
    );
    f.fx.putExpense(id: 'e1', total: const Money.paisa(12000));
    final c = make();
    keep(c, budgetAlertsProvider);
    await pump();
    final alerts = c.read(budgetAlertsProvider);
    expect(alerts.map((a) => a.categoryId), ['cat_food']);
    expect(alerts.single.status.level, BudgetLevel.exceeded);
    expect(c.read(monthSpendProvider(MonthKey(2026, 10))).total,
        const Money.paisa(12000));
  });

  group('BudgetController', () {
    test('save reads the draft, writes once and closes the editor', () async {
      final c = make();
      final month = BudgetFixture.october;
      final controller = c.read(budgetControllerProvider(month).notifier);
      keep(c, budgetControllerProvider(month));

      controller
        ..startEditing(null)
        ..setTotal('৫০০০')
        ..setCategory('cat_fish', '3000')
        ..addLine();
      final id = c.read(budgetControllerProvider(month)).lines.single.id;
      controller.updateLine(
        id,
        (l) => l.copyWith(name: 'চাল', qtyText: '2', rateText: '70'),
      );
      // A lone quantity without a unit is rejected, nothing is written.
      expect(await controller.save(), isFalse);
      expect(f.repository.saves, 0);
      expect(
        c.read(budgetControllerProvider(month)).lineErrors[id]!['unit'],
        'qty_unit_required',
      );

      controller.updateLine(id, (l) => l.copyWith(unit: Unit.kg));
      expect(await controller.save(), isTrue);

      final saved = f.repository.stored[month]!;
      expect(saved.totalEstimate, const Money.paisa(500000));
      expect(saved.categoryEstimates['cat_fish'], const Money.paisa(300000));
      expect(saved.lines.single.estimatedTotal, const Money.paisa(14000));
      expect(
        saved.categoryEstimates[kDryGroceriesCategoryId],
        const Money.paisa(14000),
      );
      expect(c.read(budgetControllerProvider(month)).editing, isFalse);
    });

    test('a failed save keeps the draft and the event id for the retry', () async {
      final c = make();
      final month = BudgetFixture.october;
      final controller = c.read(budgetControllerProvider(month).notifier);
      keep(c, budgetControllerProvider(month));
      controller
        ..startEditing(null)
        ..setTotal('100');
      final eventId = c.read(budgetControllerProvider(month)).eventId;
      f.repository.nextFailure = const Network();

      expect(await controller.save(), isFalse);
      final after = c.read(budgetControllerProvider(month));
      expect(after.editing, isTrue);
      expect(after.failure, const Network());
      expect(after.eventId, eventId);

      expect(await controller.save(), isTrue);
      expect(f.repository.events.single.id, eventId);
    });

    test('an unreadable amount is shown inline and nothing is saved', () async {
      final c = make();
      final month = BudgetFixture.october;
      final controller = c.read(budgetControllerProvider(month).notifier);
      keep(c, budgetControllerProvider(month));
      controller
        ..startEditing(null)
        ..setTotal('abc')
        ..setCategory('cat_fish', 'x');
      expect(await controller.save(), isFalse);
      final state = c.read(budgetControllerProvider(month));
      expect(state.totalError, 'invalid_amount');
      expect(state.categoryErrors['cat_fish'], 'invalid_amount');
      expect(f.repository.saves, 0);
    });

    test('startEditing fills the draft from an existing budget', () {
      final c = make();
      final month = BudgetFixture.october;
      keep(c, budgetControllerProvider(month));
      c.read(budgetControllerProvider(month).notifier).startEditing(
        sampleBudget(
          month,
          total: const Money.paisa(864000),
          categories: const {'cat_fish': Money.paisa(300000)},
          lines: const [riceLine],
        ),
      );
      final state = c.read(budgetControllerProvider(month));
      expect(state.totalText, '8640');
      expect(state.categoryTexts['cat_fish'], '3000');
      expect(state.lines.single.name, 'Rice');
      expect(state.lines.single.qtyText, '50');
    });

    test('copyLastMonth fills a month from the previous one', () async {
      f.repository.stored[BudgetFixture.september] = sampleBudget(
        BudgetFixture.september,
        total: const Money.paisa(5000),
      );
      final c = make();
      final month = BudgetFixture.october;
      keep(c, budgetControllerProvider(month));
      expect(
        await c.read(budgetControllerProvider(month).notifier).copyLastMonth(),
        isTrue,
      );
      expect(f.repository.stored[month]!.totalEstimate, const Money.paisa(5000));
    });
  });
}
