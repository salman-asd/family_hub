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
import 'package:family_hub/features/bazar/advances/domain/advance_repository.dart';
import 'package:family_hub/features/bazar/expenses/domain/expense.dart';
import 'package:family_hub/features/bazar/expenses/domain/expense_compensation.dart';
import 'package:family_hub/features/bazar/expenses/domain/expense_draft.dart';
import 'package:family_hub/features/bazar/expenses/domain/expense_repository.dart';
import 'package:family_hub/features/bazar/expenses/domain/expense_totals.dart';
import 'package:family_hub/features/bazar/expenses/domain/expense_validation.dart';
import 'package:family_hub/features/bazar/expenses/domain/funding.dart';
import 'package:family_hub/features/bazar/expenses/domain/write_plans.dart';
import 'package:family_hub/features/bazar/fund/domain/fund_repository.dart';
import 'package:family_hub/features/bazar/fund/domain/month_closing.dart';
import 'package:family_hub/features/family/domain/family_repository.dart';
import 'package:family_hub/features/family/domain/permission_access.dart';

/// Edits an expense and writes compensating ledger/advance rows.
class UpdateExpense {
  const UpdateExpense({
    required this._expenses,
    required this._funds,
    required this._advances,
    required this._families,
    required this._clock,
    required this._newId,
    required this._dateKeys,
  });

  final ExpenseRepository _expenses;
  final FundRepository _funds;
  final AdvanceRepository _advances;
  final FamilyRepository _families;
  final Clock _clock;
  final IdGenerator _newId;
  final FamilyDateKeys _dateKeys;

  Future<Result<Expense>> call({
    required String actorUid,
    required String familyId,
    required String expenseId,
    required ExpenseDraft draft,
    String? eventId,
  }) async {
    final loaded = await _expenses.getExpense(familyId, expenseId);
    final loadFailure = loaded.failureOrNull;
    if (loadFailure != null) return Failure<Expense>(loadFailure);
    final old = loaded.valueOrNull;
    if (old == null) return const Failure<Expense>(NotFound(entity: 'expense'));
    if (old.isDeleted) {
      return const Failure<Expense>(Conflict(code: 'expense_deleted'));
    }

    final actor = await requirePermission(
      _families,
      familyId: familyId,
      actorUid: actorUid,
      permission: old.createdBy == actorUid
          ? Permission.addOwnExpense
          : Permission.editOthersExpense,
      ownerId: old.createdBy,
    );
    final denied = actor.failureOrNull;
    if (denied != null) return Failure<Expense>(denied);

    final invalid = validateExpenseDraft(draft, today: _dateKeys.today());
    if (invalid != null) return Failure<Expense>(invalid);

    final oldLock = await _monthLockFailure(familyId, old.monthKey);
    if (oldLock != null) return Failure<Expense>(oldLock);
    if (draft.dateKey.monthKey != old.monthKey) {
      final newLock = await _monthLockFailure(familyId, draft.dateKey.monthKey);
      if (newLock != null) return Failure<Expense>(newLock);
    }

    final totalResult = computeTotal(
      qty: draft.qty,
      unitPrice: draft.unitPrice,
      typedTotal: draft.typedTotal,
    );
    final totalFailure = totalResult.failureOrNull;
    if (totalFailure != null) return Failure<Expense>(totalFailure);
    final total = totalResult.valueOrNull!;

    final now = _clock.nowUtc();
    final payer = draft.funding == FundingSource.member
        ? cleanOptional(draft.paidByMemberId)
        : null;
    final updated = Expense(
      id: old.id,
      dateKey: draft.dateKey,
      monthKey: draft.dateKey.monthKey,
      occurredAt: old.dateKey == draft.dateKey ? old.occurredAt : now,
      itemId: cleanOptional(draft.itemId),
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
      tripId: old.tripId,
      shop: cleanOptional(draft.shop),
      note: cleanOptional(draft.note),
      source: old.source,
      importBatchId: old.importBatchId,
      deletedAt: old.deletedAt,
      deletedBy: old.deletedBy,
      createdBy: old.createdBy,
      createdAt: old.createdAt,
    );

    final advanceResult = await _advances.getAdvance(familyId, old.id);
    final advanceFailure = advanceResult.failureOrNull;
    if (advanceFailure != null) return Failure<Expense>(advanceFailure);
    final currentAdvance = advanceResult.valueOrNull;

    final fundingChanged = old.funding != updated.funding;
    final amountChanged = old.total != updated.total;
    final payerChanged = old.paidByMemberId != updated.paidByMemberId;
    if (currentAdvance != null &&
        currentAdvance.settled.paisa > 0 &&
        (fundingChanged || amountChanged || payerChanged)) {
      return const Failure<Expense>(Conflict(code: 'advance_settled'));
    }

    final changedFields = <String>[
      for (final field in expenseEditableFields)
        if (expenseFieldValue(old, field) != expenseFieldValue(updated, field))
          field,
    ];
    final before = <String, Object?>{
      for (final field in changedFields) field: expenseFieldValue(old, field),
    };

    final storedEventId = eventId ?? _newId();
    final adjustments = expenseAdjustmentsFor(
      old: old,
      updated: updated,
      eventId: storedEventId,
      actorUid: actorUid,
      now: now,
    );
    final advanceChange = expenseAdvanceChangeFor(
      old: old,
      updated: updated,
      current: currentAdvance,
    );

    if (changedFields.isEmpty && adjustments.isEmpty && advanceChange == null) {
      return Success<Expense>(updated);
    }

    final event = AuditEvent(
      id: storedEventId,
      type: AuditEventType.bazarExpenseUpdated,
      actorId: actorUid,
      refType: AuditRefType.expense,
      refId: old.id,
      at: now,
      params: <String, String>{
        'item': updated.itemName,
        'fields': changedFields.join(','),
      },
    );

    final saved = await _expenses.commitEdit(
      familyId,
      ExpenseEditPlan(
        updated: updated,
        before: before,
        changedFields: changedFields,
        adjustments: adjustments,
        advanceChange: advanceChange,
      ),
      event,
    );
    final saveFailure = saved.failureOrNull;
    return saveFailure != null
        ? Failure<Expense>(saveFailure)
        : Success<Expense>(updated);
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
