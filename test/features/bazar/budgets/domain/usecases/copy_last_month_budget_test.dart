import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/permissions/permissions.dart';
import 'package:family_hub/core/utils/money.dart';
import 'package:family_hub/features/bazar/budgets/domain/budget.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../budget_test_helpers.dart';

void main() {
  late BudgetFixture f;

  setUp(() => f = BudgetFixture());

  Future<AppFailure?> copy({String actor = 'alice'}) async => (await f.copy(
    actorUid: actor,
    familyId: BudgetFixture.familyId,
    month: BudgetFixture.october,
  )).failureOrNull;

  test('copies estimates and lines, clears stock, keeps thresholds', () async {
    f.repository.stored[BudgetFixture.september] = sampleBudget(
      BudgetFixture.september,
      total: const Money.paisa(900000),
      categories: const {'cat_fish': Money.paisa(300000)},
      lines: const [riceLine, oilLine],
      thresholds: const [70, 90],
    );

    expect(await copy(), isNull);

    final copied = f.repository.stored[BudgetFixture.october]!;
    expect(copied.month, BudgetFixture.october);
    expect(copied.totalEstimate, const Money.paisa(900000));
    expect(copied.categoryEstimates['cat_fish'], const Money.paisa(300000));
    expect(
      copied.categoryEstimates[kDryGroceriesCategoryId],
      const Money.paisa(470000),
    );
    expect(copied.lines.map((l) => l.name), ['Rice', 'Oil']);
    expect(copied.lines.every((l) => l.stock == null), isTrue);
    expect(copied.alertThresholds, [70, 90]);
    expect(f.repository.events.single.refId, '2026-10');
  });

  test('a missing previous budget is NotFound(budget)', () async {
    expect(await copy(), const NotFound(entity: 'budget'));
    expect(f.repository.saves, 0);
  });

  test('an existing target is a conflict and is never overwritten', () async {
    f.repository.stored[BudgetFixture.september] = sampleBudget(
      BudgetFixture.september,
    );
    final mine = sampleBudget(
      BudgetFixture.october,
      total: const Money.paisa(123),
    );
    f.repository.stored[BudgetFixture.october] = mine;

    expect(await copy(), const Conflict(code: 'budget_exists'));
    expect(f.repository.stored[BudgetFixture.october], mine);
    expect(f.repository.saves, 0);
  });

  test('permission is checked first', () async {
    expect(await copy(actor: 'cara'), const PermissionDenied());
    f.fx.backend.permissionSettings[BudgetFixture.familyId] =
        PermissionSettings.defaults.copyWith(moderatorManagesFinance: false);
    expect(await copy(actor: 'bob'), const PermissionDenied());
  });
}
