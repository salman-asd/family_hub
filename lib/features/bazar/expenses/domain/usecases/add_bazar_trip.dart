import 'package:family_hub/core/audit/audit_event.dart';
import 'package:family_hub/core/audit/audit_event_type.dart';
import 'package:family_hub/core/audit/audit_ref_type.dart';
import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/core/permissions/permissions.dart';
import 'package:family_hub/core/utils/clock.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/core/utils/family_date_keys.dart';
import 'package:family_hub/core/utils/id_generator.dart';
import 'package:family_hub/core/utils/money.dart';
import 'package:family_hub/core/utils/quantity.dart';
import 'package:family_hub/features/bazar/advances/domain/advance_repository.dart';
import 'package:family_hub/features/bazar/advances/domain/member_advance.dart';
import 'package:family_hub/features/bazar/expenses/domain/expense.dart';
import 'package:family_hub/features/bazar/expenses/domain/expense_draft.dart';
import 'package:family_hub/features/bazar/expenses/domain/expense_repository.dart';
import 'package:family_hub/features/bazar/expenses/domain/expense_totals.dart';
import 'package:family_hub/features/bazar/expenses/domain/expense_validation.dart';
import 'package:family_hub/features/bazar/expenses/domain/funding.dart';
import 'package:family_hub/features/bazar/expenses/domain/trip.dart';
import 'package:family_hub/features/bazar/expenses/domain/write_plans.dart';
import 'package:family_hub/features/bazar/fund/domain/fund_repository.dart';
import 'package:family_hub/features/bazar/fund/domain/fund_transaction.dart';
import 'package:family_hub/features/bazar/fund/domain/month_closing.dart';
import 'package:family_hub/features/bazar/items_categories/domain/catalog_repository.dart';
import 'package:family_hub/features/bazar/items_categories/domain/item.dart';
import 'package:family_hub/features/bazar/items_categories/domain/item_usage_bump.dart';
import 'package:family_hub/features/family/domain/family_repository.dart';
import 'package:family_hub/features/family/domain/permission_access.dart';

/// Adds a 1–40 line bazar trip as one batch.
class AddBazarTrip {
  const AddBazarTrip({
    required this._expenses,
    required this._catalog,
    required this._funds,
    required AdvanceRepository advances,
    required this._families,
    required this._clock,
    required this._newId,
    required this._dateKeys,
  });

  final ExpenseRepository _expenses;
  final CatalogRepository _catalog;
  final FundRepository _funds;
  final FamilyRepository _families;
  final Clock _clock;
  final IdGenerator _newId;
  final FamilyDateKeys _dateKeys;

  Future<Result<Trip>> call({
    required String actorUid,
    required String familyId,
    required TripDraft header,
    required List<ExpenseDraft> lines,
    String? tripId,
    List<String>? lineIds,
    String? eventId,
  }) async {
    final actor = await requirePermission(
      _families,
      familyId: familyId,
      actorUid: actorUid,
      permission: Permission.addOwnExpense,
      ownerId: actorUid,
    );
    final denied = actor.failureOrNull;
    if (denied != null) return Failure<Trip>(denied);

    if (lines.isEmpty || lines.length > 40) {
      return const Failure<Trip>(Validation('lines', 'too_many_lines'));
    }

    final now = _clock.nowUtc();
    final today = _dateKeys.today();
    if (header.dateKey.isAfter(today)) {
      return const Failure<Trip>(Validation('dateKey', 'future_date'));
    }
    final lockFailure = await _monthLockFailure(
      familyId,
      header.dateKey.monthKey,
    );
    if (lockFailure != null) return Failure<Trip>(lockFailure);

    final payer = header.funding == FundingSource.member
        ? cleanOptional(header.paidByMemberId)
        : null;
    final storedId = tripId ?? _newId();
    final linePlans = <ExpenseWritePlan>[];
    final usage = <String, _UsageAgg>{};
    final itemsById = <String, Item>{};

    final neededItemIds = <String>{
      for (final line in lines)
        if (cleanOptional(line.itemId) != null) cleanOptional(line.itemId)!,
    };
    if (neededItemIds.isNotEmpty) {
      final itemsResult = await _catalog.getItems(familyId);
      final itemsFailure = itemsResult.failureOrNull;
      if (itemsFailure != null) return Failure<Trip>(itemsFailure);
      for (final item in itemsResult.valueOrNull ?? const <Item>[]) {
        if (neededItemIds.contains(item.id)) itemsById[item.id] = item;
      }
      if (itemsById.length != neededItemIds.length) {
        return const Failure<Trip>(NotFound(entity: 'item'));
      }
    }

    for (var index = 0; index < lines.length; index++) {
      final source = lines[index];
      final draft = ExpenseDraft(
        dateKey: header.dateKey,
        itemId: source.itemId,
        itemName: source.itemName,
        categoryId: source.categoryId,
        qty: source.qty,
        unit: source.unit,
        unitPrice: source.unitPrice,
        typedTotal: source.typedTotal,
        funding: header.funding,
        paidByMemberId: header.paidByMemberId,
        reimbursable: header.reimbursable,
        purchaserId: source.purchaserId,
        shop: header.shop,
        note: source.note ?? header.note,
        rememberItem: source.rememberItem,
      );
      final invalid = validateExpenseDraft(draft, today: today);
      if (invalid != null) return Failure<Trip>(invalid);

      final totalResult = computeTotal(
        qty: draft.qty,
        unitPrice: draft.unitPrice,
        typedTotal: draft.typedTotal,
      );
      final totalFailure = totalResult.failureOrNull;
      if (totalFailure != null) return Failure<Trip>(totalFailure);
      final total = totalResult.valueOrNull!;

      final expenseId = lineIds != null && index < lineIds.length
          ? lineIds[index]
          : _newId();
      final itemId = cleanOptional(draft.itemId);
      final expense = Expense(
        id: expenseId,
        dateKey: draft.dateKey,
        monthKey: draft.dateKey.monthKey,
        occurredAt: now,
        itemId: itemId,
        itemName: cleanRequired(draft.itemName),
        categoryId: cleanRequired(draft.categoryId),
        qty: draft.qty,
        unit: draft.unit,
        unitPrice: draft.unitPrice,
        total: total,
        funding: draft.funding,
        paidByMemberId: payer,
        reimbursable:
            draft.funding == FundingSource.member && draft.reimbursable,
        purchaserId: cleanOptional(draft.purchaserId),
        tripId: storedId,
        shop: cleanOptional(draft.shop),
        note: cleanOptional(draft.note),
        source: ExpenseSource.manual,
        createdBy: actorUid,
        createdAt: now,
      );

      final fundTx = draft.funding == FundingSource.fund
          ? FundTransaction.forExpense(
              expenseId: expenseId,
              total: total,
              dateKey: draft.dateKey,
              createdBy: actorUid,
              createdAt: now,
            )
          : null;
      final advance =
          draft.funding == FundingSource.member && draft.reimbursable
          ? MemberAdvance(
              expenseId: expenseId,
              memberId: payer!,
              amount: total,
              settled: Money.zero,
              status: AdvanceStatus.pending,
              dateKey: draft.dateKey,
              monthKey: draft.dateKey.monthKey,
            )
          : null;

      Item? newItem;
      if (draft.rememberItem && itemId == null) {
        newItem = Item(
          id: 'item_$expenseId',
          nameBn: expense.itemName,
          categoryId: expense.categoryId,
          defaultUnit: draft.unit ?? Unit.piece,
        );
      } else if (itemId != null) {
        final aggregate = usage.putIfAbsent(itemId, _UsageAgg.new);
        aggregate.increments++;
        aggregate.lastPrice = total;
        aggregate.lastUnitPrice = draft.unitPrice;
      }

      linePlans.add(
        ExpenseWritePlan(
          expense: expense,
          fundTx: fundTx,
          advance: advance,
          newItem: newItem,
        ),
      );
    }

    final total = Money.sum(linePlans.map((plan) => plan.expense.total));
    final trip = Trip(
      id: storedId,
      dateKey: header.dateKey,
      monthKey: header.dateKey.monthKey,
      shop: cleanOptional(header.shop),
      funding: header.funding,
      paidByMemberId: payer,
      reimbursable:
          header.funding == FundingSource.member && header.reimbursable,
      lineCount: lines.length,
      total: total,
      note: cleanOptional(header.note),
    );
    final event = AuditEvent(
      id: eventId ?? _newId(),
      type: AuditEventType.bazarTripCreated,
      actorId: actorUid,
      refType: AuditRefType.trip,
      refId: storedId,
      at: now,
      params: <String, String>{
        'lines': lines.length.toString(),
        'amount': total.paisa.toString(),
      },
    );

    final saved = await _expenses.commitTrip(
      familyId,
      TripWritePlan(
        trip: trip,
        lines: linePlans,
        usage: <ItemUsageBump>[
          for (final entry in usage.entries)
            ItemUsageBump(
              itemId: entry.key,
              increments: entry.value.increments,
              at: now,
              lastPrice: entry.value.lastPrice,
              lastUnitPrice: entry.value.lastUnitPrice,
            ),
        ],
      ),
      event,
    );
    final saveFailure = saved.failureOrNull;
    return saveFailure != null
        ? Failure<Trip>(saveFailure)
        : Success<Trip>(trip);
  }

  Future<AppFailure?> _monthLockFailure(String familyId, MonthKey month) async {
    final result = await _funds.getClosing(familyId, month);
    final failure = result.failureOrNull;
    if (failure != null) return failure;
    return result.valueOrNull?.status == MonthStatus.closed
        ? const Conflict(code: 'month_locked')
        : null;
  }
}

final class _UsageAgg {
  int increments = 0;
  Money? lastPrice;
  Money? lastUnitPrice;
}
