import 'package:family_hub/core/audit/audit_event_type.dart';
import 'package:family_hub/core/audit/audit_ref_type.dart';
import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/permissions/permissions.dart';
import 'package:family_hub/core/utils/money.dart';
import 'package:family_hub/core/utils/quantity.dart';
import 'package:family_hub/features/bazar/budgets/domain/budget.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../budget_test_helpers.dart';

void main() {
  late BudgetFixture f;

  setUp(() => f = BudgetFixture());

  Future<AppFailure?> save(
    Budget budget, {
    String actor = 'alice',
    String? eventId,
  }) async => (await f.save(
    actorUid: actor,
    familyId: BudgetFixture.familyId,
    budget: budget,
    eventId: eventId,
  )).failureOrNull;

  test('an admin saves; one audit entry with month and amount', () async {
    final failure = await save(
      sampleBudget(BudgetFixture.october, total: const Money.paisa(500000)),
    );

    expect(failure, isNull);
    expect(f.repository.saves, 1);
    final event = f.repository.events.single;
    expect(event.type, AuditEventType.bazarBudgetSaved);
    expect(event.refType, AuditRefType.budget);
    expect(event.refId, '2026-10');
    expect(event.params, {'month': '2026-10', 'amount': '500000'});
    expect(event.actorId, 'alice');
  });

  test('a finance moderator may save', () async {
    expect(await save(sampleBudget(BudgetFixture.october), actor: 'bob'), isNull);
  });

  test('a moderator without finance is denied', () async {
    f.fx.backend.permissionSettings[BudgetFixture.familyId] =
        PermissionSettings.defaults.copyWith(moderatorManagesFinance: false);
    expect(
      await save(sampleBudget(BudgetFixture.october), actor: 'bob'),
      const PermissionDenied(),
    );
    expect(f.repository.saves, 0);
  });

  test('a member and a pending member are denied', () async {
    expect(
      await save(sampleBudget(BudgetFixture.october), actor: 'cara'),
      const PermissionDenied(),
    );
    expect(
      await save(sampleBudget(BudgetFixture.october), actor: 'dave'),
      const PermissionDenied(),
    );
    expect(f.repository.saves, 0);
  });

  test('lines drive the dry-grocery estimate, overriding a typed one', () async {
    await save(
      sampleBudget(
        BudgetFixture.october,
        total: Money.zero,
        categories: const {
          kDryGroceriesCategoryId: Money.paisa(1),
          'cat_fish': Money.paisa(300000),
        },
        lines: const [riceLine, oilLine],
      ),
    );
    final saved = f.repository.stored[BudgetFixture.october]!;
    expect(
      saved.categoryEstimates[kDryGroceriesCategoryId],
      const Money.paisa(470000),
    );
    // Zero total defaults to the sum of the category estimates.
    expect(saved.totalEstimate, const Money.paisa(770000));
  });

  test('a typed total is kept when given', () async {
    await save(
      sampleBudget(
        BudgetFixture.october,
        total: const Money.paisa(900000),
        categories: const {'cat_fish': Money.paisa(300000)},
      ),
    );
    expect(
      f.repository.stored[BudgetFixture.october]!.totalEstimate,
      const Money.paisa(900000),
    );
  });

  test('a line with quantity and rate gets the calculated total', () async {
    const stale = BudgetLine(
      name: '  Rice  ',
      plannedQty: Quantity.milli(50000),
      estimatedRate: Money.paisa(7000),
      estimatedTotal: Money.paisa(1),
    );
    await save(sampleBudget(BudgetFixture.october, lines: const [stale]));
    final line = f.repository.stored[BudgetFixture.october]!.lines.single;
    expect(line.name, 'Rice');
    expect(line.estimatedTotal, const Money.paisa(350000));
  });

  group('validation', () {
    test('negative total', () async {
      expect(
        await save(
          sampleBudget(BudgetFixture.october, total: const Money.paisa(-1)),
        ),
        const Validation('totalEstimate', 'negative'),
      );
    });

    test('negative category estimate', () async {
      expect(
        await save(
          sampleBudget(
            BudgetFixture.october,
            categories: const {'c': Money.paisa(-5)},
          ),
        ),
        const Validation('categoryEstimates', 'negative'),
      );
    });

    test('more than 40 category estimates', () async {
      final many = {
        for (var i = 0; i < 41; i++) 'cat_$i': const Money.paisa(100),
      };
      expect(
        await save(sampleBudget(BudgetFixture.october, categories: many)),
        const Validation('categoryEstimates', 'too_large'),
      );
    });

    test('151 lines fail, 150 pass', () async {
      List<BudgetLine> lines(int n) => [
        for (var i = 0; i < n; i++)
          BudgetLine(name: 'L$i', estimatedTotal: const Money.paisa(100)),
      ];
      expect(
        await save(sampleBudget(BudgetFixture.october, lines: lines(151))),
        const Validation('lines', 'too_many_lines'),
      );
      // 150 lines add the dry-grocery category: still within 40.
      expect(
        await save(sampleBudget(BudgetFixture.october, lines: lines(150))),
        isNull,
      );
    });

    test('blank, too long and negative lines', () async {
      expect(
        await save(
          sampleBudget(
            BudgetFixture.october,
            lines: const [
              BudgetLine(name: '   ', estimatedTotal: Money.paisa(100)),
            ],
          ),
        ),
        const Validation('lines', 'required'),
      );
      expect(
        await save(
          sampleBudget(
            BudgetFixture.october,
            lines: [
              BudgetLine(name: 'x' * 81, estimatedTotal: const Money.paisa(1)),
            ],
          ),
        ),
        const Validation('lines', 'too_long'),
      );
      expect(
        await save(
          sampleBudget(
            BudgetFixture.october,
            lines: const [
              BudgetLine(name: 'x', estimatedTotal: Money.paisa(-1)),
            ],
          ),
        ),
        const Validation('lines', 'negative'),
      );
    });

    test('thresholds', () async {
      Future<AppFailure?> with_(List<int> t) =>
          save(sampleBudget(BudgetFixture.october, thresholds: t));
      expect(await with_([]), const Validation('alertThresholds', 'empty'));
      expect(
        await with_([10, 20, 30, 40, 50]),
        const Validation('alertThresholds', 'too_many'),
      );
      expect(
        await with_([0, 100]),
        const Validation('alertThresholds', 'out_of_range'),
      );
      expect(
        await with_([201]),
        const Validation('alertThresholds', 'out_of_range'),
      );
      expect(
        await with_([80, 80]),
        const Validation('alertThresholds', 'duplicate'),
      );
      expect(
        await with_([100, 80]),
        const Validation('alertThresholds', 'not_ascending'),
      );
      expect(await with_([80, 100]), isNull);
    });

    test('an invalid budget writes nothing', () async {
      await save(
        sampleBudget(BudgetFixture.october, total: const Money.paisa(-1)),
      );
      expect(f.repository.saves, 0);
    });
  });

  test('a retry with the same event id reuses it', () async {
    await save(sampleBudget(BudgetFixture.october), eventId: 'ev-fixed');
    expect(f.repository.events.single.id, 'ev-fixed');
  });

  test('a repository failure is returned', () async {
    f.repository.nextFailure = const Network();
    expect(await save(sampleBudget(BudgetFixture.october)), const Network());
  });

  test('a closed month does not block a plan', () async {
    // Budgets are plans: they never touch the ledger.
    expect(await save(sampleBudget(BudgetFixture.september)), isNull);
  });
}
