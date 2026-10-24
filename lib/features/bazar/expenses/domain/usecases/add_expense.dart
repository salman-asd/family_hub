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
import 'package:family_hub/features/bazar/expenses/domain/write_plans.dart';
import 'package:family_hub/features/bazar/fund/domain/fund_repository.dart';
import 'package:family_hub/features/bazar/fund/domain/fund_transaction.dart';
import 'package:family_hub/features/bazar/fund/domain/month_closing.dart';
import 'package:family_hub/features/bazar/items_categories/domain/catalog_repository.dart';
import 'package:family_hub/features/bazar/items_categories/domain/catalog_validation.dart'
    show findItem;
import 'package:family_hub/features/bazar/items_categories/domain/item.dart';
import 'package:family_hub/features/bazar/items_categories/domain/item_usage_bump.dart';
import 'package:family_hub/features/family/domain/family_repository.dart';
import 'package:family_hub/features/family/domain/permission_access.dart';

/// Adds one expense and, when needed, its fund row, advance and usage bump.
class AddExpense {
  const AddExpense({
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

  Future<Result<Expense>> call({
    required String actorUid,
    required String familyId,
    required ExpenseDraft draft,
    String? id,
    String? eventId,
    String? newItemId,
  }) async {
    final actor = await requirePermission(
      _families,
      familyId: familyId,
      actorUid: actorUid,
      permission: Permission.addOwnExpense,
      ownerId: actorUid,
    );
    final denied = actor.failureOrNull;
    if (denied != null) return Failure<Expense>(denied);

    final invalid = validateExpenseDraft(draft, today: _dateKeys.today());
    if (invalid != null) return Failure<Expense>(invalid);

    final lockFailure = await _monthLockFailure(
      familyId,
      draft.dateKey.monthKey,
    );
    if (lockFailure != null) return Failure<Expense>(lockFailure);

    final totalResult = computeTotal(
      qty: draft.qty,
      unitPrice: draft.unitPrice,
      typedTotal: draft.typedTotal,
    );
    final totalFailure = totalResult.failureOrNull;
    if (totalFailure != null) return Failure<Expense>(totalFailure);
    final total = totalResult.valueOrNull!;

    final expenseId = id ?? _newId();
    final now = _clock.nowUtc();
    final itemId = cleanOptional(draft.itemId);
    final payer = draft.funding == FundingSource.member
        ? cleanOptional(draft.paidByMemberId)
        : null;

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
      reimbursable: draft.funding == FundingSource.member && draft.reimbursable,
      purchaserId: cleanOptional(draft.purchaserId),
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

    final advance = draft.funding == FundingSource.member && draft.reimbursable
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
    ItemUsageBump? usage;
    if (draft.rememberItem && itemId == null) {
      newItem = Item(
        id: newItemId ?? _newId(),
        nameBn: expense.itemName,
        categoryId: expense.categoryId,
        defaultUnit: draft.unit ?? Unit.piece,
      );
    } else if (itemId != null) {
      final itemsResult = await _catalog.getItems(familyId);
      final itemsFailure = itemsResult.failureOrNull;
      if (itemsFailure != null) return Failure<Expense>(itemsFailure);
      if (findItem(itemsResult.valueOrNull ?? const <Item>[], itemId) == null) {
        return const Failure<Expense>(NotFound(entity: 'item'));
      }
      usage = ItemUsageBump(
        itemId: itemId,
        increments: 1,
        at: now,
        lastPrice: total,
        lastUnitPrice: draft.unitPrice,
      );
    }

    final event = AuditEvent(
      id: eventId ?? _newId(),
      type: AuditEventType.bazarExpenseCreated,
      actorId: actorUid,
      refType: AuditRefType.expense,
      refId: expenseId,
      at: now,
      params: <String, String>{
        'item': expense.itemName,
        'amount': total.paisa.toString(),
        'funding': draft.funding.name,
      },
    );

    final saved = await _expenses.commitAdd(
      familyId,
      ExpenseWritePlan(
        expense: expense,
        fundTx: fundTx,
        advance: advance,
        usage: usage,
        newItem: newItem,
      ),
      event,
    );
    final saveFailure = saved.failureOrNull;
    return saveFailure != null
        ? Failure<Expense>(saveFailure)
        : Success<Expense>(expense);
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
