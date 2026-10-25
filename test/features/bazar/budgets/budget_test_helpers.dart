import 'dart:async';

import 'package:family_hub/core/audit/audit_event.dart';
import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/core/utils/money.dart';
import 'package:family_hub/core/utils/quantity.dart';
import 'package:family_hub/features/bazar/budgets/domain/budget.dart';
import 'package:family_hub/features/bazar/budgets/domain/budget_repository.dart';
import 'package:family_hub/features/bazar/budgets/domain/usecases/copy_last_month_budget.dart';
import 'package:family_hub/features/bazar/budgets/domain/usecases/save_budget.dart';

import '../bazar_test_helpers.dart';

/// Small in-memory [BudgetRepository] with a live stream per month.
class FakeBudgetRepository implements BudgetRepository {
  final Map<MonthKey, Budget> stored = <MonthKey, Budget>{};
  final List<AuditEvent> events = <AuditEvent>[];
  final StreamController<void> _changes = StreamController<void>.broadcast();
  int saves = 0;
  AppFailure? nextFailure;

  @override
  Stream<Budget?> watchBudget(String familyId, MonthKey month) async* {
    yield stored[month];
    await for (final _ in _changes.stream) {
      yield stored[month];
    }
  }

  @override
  Future<Result<Budget?>> getBudget(String familyId, MonthKey month) async =>
      Success<Budget?>(stored[month]);

  @override
  Future<Result<void>> saveBudget(
    String familyId,
    Budget budget,
    AuditEvent event,
  ) async {
    saves++;
    final failure = nextFailure;
    if (failure != null) {
      nextFailure = null;
      return Failure<void>(failure);
    }
    stored[budget.month] = budget;
    events.add(event);
    _changes.add(null);
    return const Success<void>(null);
  }
}

/// Fixture + fake repository + both use cases, wired like the providers.
class BudgetFixture {
  BudgetFixture()
    : fx = BazarFixture(),
      repository = FakeBudgetRepository() {
    save = SaveBudget(
      budgets: repository,
      families: fx.backend,
      clock: fx.clock,
      newId: fx.ids.call,
    );
    copy = CopyLastMonthBudget(
      budgets: repository,
      families: fx.backend,
      clock: fx.clock,
      newId: fx.ids.call,
    );
  }

  final BazarFixture fx;
  final FakeBudgetRepository repository;
  late final SaveBudget save;
  late final CopyLastMonthBudget copy;

  static const String familyId = BazarFixture.familyId;
  static final MonthKey october = MonthKey(2026, 10);
  static final MonthKey september = MonthKey(2026, 9);
}

/// A dry-grocery line: 50 kg at ৳70 = ৳3,500.
const BudgetLine riceLine = BudgetLine(
  name: 'Rice',
  plannedQty: Quantity.milli(50000),
  unit: Unit.kg,
  estimatedRate: Money.paisa(7000),
  estimatedTotal: Money.paisa(350000),
  stock: Quantity.milli(5000),
);

/// A line with only a typed total (৳1,200).
const BudgetLine oilLine = BudgetLine(
  name: 'Oil',
  estimatedTotal: Money.paisa(120000),
);

Budget sampleBudget(
  MonthKey month, {
  Money total = const Money.paisa(1000000),
  Map<String, Money> categories = const <String, Money>{},
  List<BudgetLine> lines = const <BudgetLine>[],
  List<int> thresholds = const <int>[80, 100],
}) => Budget(
  month: month,
  totalEstimate: total,
  categoryEstimates: categories,
  lines: lines,
  alertThresholds: thresholds,
);
