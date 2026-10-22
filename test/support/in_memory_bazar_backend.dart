import 'dart:async';

import 'package:family_hub/core/audit/audit_event.dart';
import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/features/bazar/advances/domain/advance_repository.dart';
import 'package:family_hub/features/bazar/advances/domain/member_advance.dart';
import 'package:family_hub/features/bazar/advances/domain/settlement.dart';
import 'package:family_hub/features/bazar/expenses/domain/expense.dart';
import 'package:family_hub/features/bazar/expenses/domain/expense_repository.dart';
import 'package:family_hub/features/bazar/expenses/domain/funding.dart';
import 'package:family_hub/features/bazar/expenses/domain/trip.dart';
import 'package:family_hub/features/bazar/expenses/domain/write_plans.dart';
import 'package:family_hub/features/bazar/fund/domain/fund_repository.dart';
import 'package:family_hub/features/bazar/fund/domain/fund_transaction.dart';
import 'package:family_hub/features/bazar/fund/domain/month_closing.dart';
import 'package:family_hub/features/bazar/items_categories/domain/catalog_repository.dart';
import 'package:family_hub/features/bazar/items_categories/domain/category.dart';
import 'package:family_hub/features/bazar/items_categories/domain/default_catalog.dart';
import 'package:family_hub/features/bazar/items_categories/domain/item.dart';
import 'package:family_hub/features/bazar/items_categories/domain/item_usage_bump.dart';

import 'in_memory_backend.dart';

/// In-memory catalog, expense, ledger and advance repository with live streams
/// and the shared event log.
///
/// It extends [InMemoryBackend], so one instance is both the family port and
/// every Bazar port for a use-case test.  Later Bazar steps add their ports to
/// this same class.
class InMemoryBazarBackend extends InMemoryBackend
    implements
        CatalogRepository,
        ExpenseRepository,
        FundRepository,
        AdvanceRepository {
  final Map<String, Map<String, Category>> categories = {};
  final Map<String, Map<String, Item>> items = {};
  final Map<String, Map<String, Expense>> expenses = {};
  final Map<String, Map<String, Trip>> trips = {};
  final Map<String, Map<String, FundTransaction>> fundTransactions = {};
  final Map<String, Map<String, MemberAdvance>> advances = {};
  final Map<String, Map<String, Settlement>> settlements = {};
  final Map<String, Map<MonthKey, MonthClosing>> closings = {};
  final Map<String, Map<String, Map<String, ExpenseRevision>>> revisions = {};

  final StreamController<void> _catalogChanges =
      StreamController<void>.broadcast();
  final StreamController<void> _expenseChanges =
      StreamController<void>.broadcast();

  List<Category> categoriesOf(String familyId) => <Category>[
    ...(categories[familyId] ?? const <String, Category>{}).values,
  ];

  List<Item> itemsOf(String familyId) => <Item>[
    ...(items[familyId] ?? const <String, Item>{}).values,
  ];

  List<Expense> expensesOf(String familyId) => <Expense>[
    ...(expenses[familyId] ?? const <String, Expense>{}).values,
  ];

  List<Trip> tripsOf(String familyId) => <Trip>[
    ...(trips[familyId] ?? const <String, Trip>{}).values,
  ];

  /// Alias matching the P2-09 card's field name.
  Map<String, Map<String, FundTransaction>> get fundTx => fundTransactions;

  List<FundTransaction> fundTransactionsOf(
    String familyId,
  ) => <FundTransaction>[
    ...(fundTransactions[familyId] ?? const <String, FundTransaction>{}).values,
  ];

  List<MemberAdvance> advancesOf(String familyId) => <MemberAdvance>[
    ...(advances[familyId] ?? const <String, MemberAdvance>{}).values,
  ];

  List<MonthClosing> closingsOf(String familyId) => <MonthClosing>[
    ...(closings[familyId] ?? const <MonthKey, MonthClosing>{}).values,
  ];

  List<ExpenseRevision> revisionsOf(
    String familyId,
    String expenseId,
  ) => <ExpenseRevision>[
    ...(revisions[familyId]?[expenseId] ?? const <String, ExpenseRevision>{})
        .values,
  ];

  /// Lets tests mutate the maps directly and then publish the change.
  void catalogNotify() => _catalogChanges.add(null);

  /// Lets tests publish a direct expense/ledger mutation.
  void expenseNotify() => _expenseChanges.add(null);

  @override
  Stream<List<Category>> watchCategories(String familyId) async* {
    yield categoriesOf(familyId);
    await for (final _ in _catalogChanges.stream) {
      yield categoriesOf(familyId);
    }
  }

  @override
  Stream<List<Item>> watchItems(String familyId) async* {
    yield itemsOf(familyId);
    await for (final _ in _catalogChanges.stream) {
      yield itemsOf(familyId);
    }
  }

  @override
  Future<Result<List<Category>>> getCategories(String familyId) async =>
      Success<List<Category>>(categoriesOf(familyId));

  @override
  Future<Result<List<Item>>> getItems(String familyId) async =>
      Success<List<Item>>(itemsOf(familyId));

  @override
  Future<Result<void>> saveCategory(
    String familyId,
    Category category,
    AuditEvent event, {
    required bool isNew,
  }) async {
    final failed = _takeWriteFailure();
    if (failed != null) return failed;
    final existing = categories[familyId] ??= <String, Category>{};
    if (!isNew && !existing.containsKey(category.id)) {
      return const Failure<void>(NotFound(entity: 'category'));
    }
    existing[category.id] = category;
    _addEventOnce(event);
    writes++;
    catalogNotify();
    return const Success<void>(null);
  }

  @override
  Future<Result<void>> saveItem(
    String familyId,
    Item item,
    AuditEvent event, {
    required bool isNew,
  }) async {
    final failed = _takeWriteFailure();
    if (failed != null) return failed;
    final existing = items[familyId] ??= <String, Item>{};
    if (!isNew && !existing.containsKey(item.id)) {
      return const Failure<void>(NotFound(entity: 'item'));
    }
    existing[item.id] = item;
    _addEventOnce(event);
    writes++;
    catalogNotify();
    return const Success<void>(null);
  }

  @override
  Future<Result<bool>> isCatalogEmpty(String familyId) async =>
      Success<bool>(categories[familyId]?.isEmpty ?? true);

  /// Writes the same 11 categories and 54 items as the real repository.
  @override
  Future<Result<void>> seedDefaultCatalog(
    String familyId,
    String actorUid,
    AuditEvent event,
  ) async {
    final failed = _takeWriteFailure();
    if (failed != null) return failed;
    final categoryMap = categories[familyId] ??= <String, Category>{};
    for (final seed in defaultCatalogCategories) {
      categoryMap[seed.id] = Category(
        id: seed.id,
        nameBn: seed.bn,
        nameEn: seed.en,
        colorIndex: seed.colorIndex,
        emoji: seed.emoji,
        sortOrder: seed.order,
        builtIn: true,
        seedKey: seed.key,
      );
    }
    final itemMap = items[familyId] ??= <String, Item>{};
    for (final seed in defaultCatalogItems) {
      itemMap[seed.id] = Item(
        id: seed.id,
        nameBn: seed.bn,
        nameEn: seed.en,
        categoryId: seed.categoryId,
        defaultUnit: seed.unit,
        aliases: seed.aliases,
        builtIn: true,
        seedKey: seed.key,
      );
    }
    _addEventOnce(event);
    writes++;
    catalogNotify();
    return const Success<void>(null);
  }

  // ── Expenses ──────────────────────────────────────────────────────────────

  @override
  Future<Result<void>> commitAdd(
    String familyId,
    ExpenseWritePlan plan,
    AuditEvent event,
  ) async {
    final failed = _takeWriteFailure();
    if (failed != null) return failed;
    final alreadyThere =
        expenses[familyId]?.containsKey(plan.expense.id) ?? false;
    _applyPlan(familyId, plan);
    if (!alreadyThere && plan.usage != null) {
      _applyUsage(familyId, plan.usage!);
    }
    _addEventOnce(event);
    writes++;
    _expenseChanges.add(null);
    return const Success<void>(null);
  }

  @override
  Future<Result<void>> commitTrip(
    String familyId,
    TripWritePlan plan,
    AuditEvent event,
  ) async {
    final failed = _takeWriteFailure();
    if (failed != null) return failed;
    final alreadyThere = trips[familyId]?.containsKey(plan.trip.id) ?? false;
    (trips[familyId] ??= <String, Trip>{})[plan.trip.id] = plan.trip;
    for (final line in plan.lines) {
      _applyPlan(familyId, line);
    }
    if (!alreadyThere) {
      for (final bump in plan.usage) {
        _applyUsage(familyId, bump);
      }
    }
    _addEventOnce(event);
    writes++;
    _expenseChanges.add(null);
    return const Success<void>(null);
  }

  @override
  Future<Result<void>> commitEdit(
    String familyId,
    ExpenseEditPlan plan,
    AuditEvent event,
  ) async {
    final failed = _takeWriteFailure();
    if (failed != null) return failed;
    (expenses[familyId] ??= <String, Expense>{})[plan.updated.id] =
        plan.updated;
    _applyAdjustments(familyId, plan.adjustments);
    _applyAdvanceChange(familyId, plan.advanceChange);
    _appendRevision(
      familyId,
      plan.updated.id,
      event,
      plan.before,
      plan.changedFields,
    );
    _addEventOnce(event);
    writes++;
    _expenseChanges.add(null);
    return const Success<void>(null);
  }

  @override
  Future<Result<void>> commitDelete(
    String familyId,
    ExpenseDeletePlan plan,
    AuditEvent event,
  ) async {
    final failed = _takeWriteFailure();
    if (failed != null) return failed;
    (expenses[familyId] ??= <String, Expense>{})[plan.updated.id] =
        plan.updated;
    _applyAdjustments(familyId, plan.adjustments);
    _applyAdvanceChange(familyId, plan.advanceChange);
    _appendRevision(
      familyId,
      plan.updated.id,
      event,
      plan.before,
      const <String>['deletedAt', 'deletedBy'],
    );
    _addEventOnce(event);
    writes++;
    _expenseChanges.add(null);
    return const Success<void>(null);
  }

  @override
  Future<Result<void>> commitRestore(
    String familyId,
    ExpenseRestorePlan plan,
    AuditEvent event,
  ) async {
    final failed = _takeWriteFailure();
    if (failed != null) return failed;
    (expenses[familyId] ??= <String, Expense>{})[plan.updated.id] =
        plan.updated;
    _applyAdjustments(familyId, plan.adjustments);
    _applyAdvanceChange(familyId, plan.advanceChange);
    _appendRevision(
      familyId,
      plan.updated.id,
      event,
      plan.before,
      const <String>['deletedAt', 'deletedBy'],
    );
    _addEventOnce(event);
    writes++;
    _expenseChanges.add(null);
    return const Success<void>(null);
  }

  @override
  Future<Result<Expense?>> getExpense(String familyId, String id) async =>
      Success<Expense?>(expenses[familyId]?[id]);

  @override
  Future<Result<List<Expense>>> getByDate(
    String familyId,
    DateKey date, {
    int limit = 50,
  }) async {
    final rows = <Expense>[
      for (final expense in expensesOf(familyId))
        if (expense.dateKey == date) expense,
    ]..sort(_newestFirst);
    return Success<List<Expense>>(rows.take(limit).toList());
  }

  @override
  Stream<List<Expense>> watchMonth(String familyId, MonthKey month) async* {
    yield _monthExpenses(familyId, month);
    await for (final _ in _expenseChanges.stream) {
      yield _monthExpenses(familyId, month);
    }
  }

  @override
  Future<Result<List<Expense>>> queryRange(
    String familyId,
    DateKeyRange range, {
    String? categoryId,
    String? itemId,
    String? purchaserId,
    FundingSource? funding,
    int limit = defaultExpensePageSize,
    Expense? startAfter,
  }) async {
    final rows = <Expense>[
      for (final expense in expensesOf(familyId))
        if (range.contains(expense.dateKey) &&
            (categoryId == null || expense.categoryId == categoryId) &&
            (itemId == null || expense.itemId == itemId) &&
            (purchaserId == null || expense.purchaserId == purchaserId) &&
            (funding == null || expense.funding == funding))
          expense,
    ]..sort(_newestFirst);
    var start = 0;
    if (startAfter != null) {
      final index = rows.indexWhere((row) => row.id == startAfter.id);
      if (index >= 0) start = index + 1;
    }
    return Success<List<Expense>>(rows.skip(start).take(limit).toList());
  }

  @override
  Stream<List<ExpenseRevision>> watchRevisions(
    String familyId,
    String expenseId,
  ) async* {
    yield _revisionList(familyId, expenseId);
    await for (final _ in _expenseChanges.stream) {
      yield _revisionList(familyId, expenseId);
    }
  }

  List<Expense> _monthExpenses(String familyId, MonthKey month) {
    final rows = <Expense>[
      for (final expense in expensesOf(familyId))
        if (expense.monthKey == month) expense,
    ]..sort(_newestFirst);
    return rows.take(500).toList();
  }

  List<ExpenseRevision> _revisionList(String familyId, String expenseId) {
    final rows = revisionsOf(familyId, expenseId)
      ..sort((a, b) {
        final byTime = b.at.compareTo(a.at);
        return byTime != 0 ? byTime : b.id.compareTo(a.id);
      });
    return rows.take(20).toList();
  }

  void _applyPlan(String familyId, ExpenseWritePlan plan) {
    (expenses[familyId] ??= <String, Expense>{})[plan.expense.id] =
        plan.expense;
    if (plan.fundTx != null) {
      (fundTransactions[familyId] ??=
              <String, FundTransaction>{})[plan.fundTx!.id] =
          plan.fundTx!;
    }
    if (plan.advance != null) {
      (advances[familyId] ??=
              <String, MemberAdvance>{})[plan.advance!.expenseId] =
          plan.advance!;
    }
    if (plan.newItem != null) {
      (items[familyId] ??= <String, Item>{})[plan.newItem!.id] = plan.newItem!;
      catalogNotify();
    }
  }

  void _applyUsage(String familyId, ItemUsageBump bump) {
    final item = items[familyId]?[bump.itemId];
    if (item == null) return;
    items[familyId]![bump.itemId] = item.copyWith(
      useCount: item.useCount + bump.increments,
      lastPrice: bump.lastPrice ?? item.lastPrice,
      lastUnitPrice: bump.lastUnitPrice ?? item.lastUnitPrice,
      lastUsedAt: bump.at,
    );
    catalogNotify();
  }

  void _applyAdjustments(String familyId, List<FundTransaction> adjustments) {
    for (final row in adjustments) {
      (fundTransactions[familyId] ??= <String, FundTransaction>{})[row.id] =
          row;
    }
  }

  void _applyAdvanceChange(String familyId, AdvanceChange? change) {
    if (change == null) return;
    (advances[familyId] ??= <String, MemberAdvance>{})[change.after.expenseId] =
        change.after;
  }

  void _appendRevision(
    String familyId,
    String expenseId,
    AuditEvent event,
    Map<String, Object?> before,
    List<String> changedFields,
  ) {
    final byExpense =
        (revisions[familyId] ??=
                <String, Map<String, ExpenseRevision>>{})[expenseId] ??=
            <String, ExpenseRevision>{};
    byExpense[event.id] = ExpenseRevision(
      id: event.id,
      before: before,
      changedFields: changedFields,
      at: event.at,
      by: event.actorId,
    );
  }

  // ── Fund ledger ───────────────────────────────────────────────────────────

  @override
  Stream<List<FundTransaction>> watchTransactionsFrom(
    String familyId,
    MonthKey from,
  ) async* {
    yield _transactionsFrom(familyId, from);
    await for (final _ in _expenseChanges.stream) {
      yield _transactionsFrom(familyId, from);
    }
  }

  @override
  Future<Result<List<FundTransaction>>> getMonthTransactions(
    String familyId,
    MonthKey month,
  ) async {
    final rows =
        <FundTransaction>[
          for (final row in fundTransactionsOf(familyId))
            if (row.monthKey == month) row,
        ]..sort((a, b) {
          final byDate = a.dateKey.compareTo(b.dateKey);
          return byDate != 0 ? byDate : a.id.compareTo(b.id);
        });
    return Success<List<FundTransaction>>(rows);
  }

  @override
  Future<Result<List<FundTransaction>>> getTransactionsForRef(
    String familyId,
    String refId,
  ) async {
    final rows =
        <FundTransaction>[
          for (final row in fundTransactionsOf(familyId))
            if (row.refId == refId) row,
        ]..sort((a, b) {
          final byDate = a.dateKey.compareTo(b.dateKey);
          return byDate != 0 ? byDate : a.id.compareTo(b.id);
        });
    return Success<List<FundTransaction>>(rows.take(20).toList());
  }

  @override
  Stream<List<MonthClosing>> watchClosings(String familyId) async* {
    yield _closingList(familyId);
    await for (final _ in _expenseChanges.stream) {
      yield _closingList(familyId);
    }
  }

  @override
  Future<Result<MonthClosing?>> getClosing(
    String familyId,
    MonthKey month,
  ) async => Success<MonthClosing?>(closings[familyId]?[month]);

  List<FundTransaction> _transactionsFrom(String familyId, MonthKey from) {
    final rows =
        <FundTransaction>[
          for (final row in fundTransactionsOf(familyId))
            if (row.monthKey.compareTo(from) >= 0) row,
        ]..sort((a, b) {
          final byMonth = b.monthKey.compareTo(a.monthKey);
          if (byMonth != 0) return byMonth;
          final byDate = b.dateKey.compareTo(a.dateKey);
          return byDate != 0 ? byDate : b.id.compareTo(a.id);
        });
    return rows.take(500).toList();
  }

  List<MonthClosing> _closingList(String familyId) {
    final rows = closingsOf(familyId)
      ..sort((a, b) => b.monthKey.compareTo(a.monthKey));
    return rows.take(24).toList();
  }

  // ── Advances ──────────────────────────────────────────────────────────────

  @override
  Stream<List<MemberAdvance>> watchOpenAdvances(String familyId) async* {
    yield _openAdvances(familyId);
    await for (final _ in _expenseChanges.stream) {
      yield _openAdvances(familyId);
    }
  }

  @override
  Future<Result<MemberAdvance?>> getAdvance(
    String familyId,
    String expenseId,
  ) async => Success<MemberAdvance?>(advances[familyId]?[expenseId]);

  @override
  Stream<List<Settlement>> watchSettlements(
    String familyId, {
    String? advanceId,
  }) async* {
    yield _settlementList(familyId, advanceId);
    await for (final _ in _expenseChanges.stream) {
      yield _settlementList(familyId, advanceId);
    }
  }

  List<MemberAdvance> _openAdvances(String familyId) {
    final rows =
        <MemberAdvance>[
          for (final advance in advancesOf(familyId))
            if (advance.status == AdvanceStatus.pending ||
                advance.status == AdvanceStatus.partial)
              advance,
        ]..sort((a, b) {
          final byDate = b.dateKey.compareTo(a.dateKey);
          return byDate != 0 ? byDate : b.expenseId.compareTo(a.expenseId);
        });
    return rows.take(100).toList();
  }

  List<Settlement> _settlementList(String familyId, String? advanceId) {
    final rows =
        <Settlement>[
          for (final row
              in (settlements[familyId] ?? const <String, Settlement>{}).values)
            if (advanceId == null || row.advanceId == advanceId) row,
        ]..sort((a, b) {
          final byDate = b.dateKey.compareTo(a.dateKey);
          return byDate != 0 ? byDate : b.id.compareTo(a.id);
        });
    return rows.take(50).toList();
  }

  int _newestFirst(Expense a, Expense b) {
    final byDate = b.dateKey.compareTo(a.dateKey);
    if (byDate != 0) return byDate;
    final byTime = b.occurredAt.compareTo(a.occurredAt);
    return byTime != 0 ? byTime : b.id.compareTo(a.id);
  }

  void _addEventOnce(AuditEvent event) {
    if (events.any((existing) => existing.id == event.id)) return;
    events.add(event);
  }

  Result<void>? _takeWriteFailure() {
    final failure = failNextWrite;
    if (failure == null) return null;
    failNextWrite = null;
    return Failure<void>(failure);
  }

  @override
  Future<void> dispose() async {
    await _catalogChanges.close();
    await _expenseChanges.close();
    await super.dispose();
  }
}
