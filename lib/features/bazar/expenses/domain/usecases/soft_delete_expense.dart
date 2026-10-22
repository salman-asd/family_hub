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
import 'package:family_hub/features/bazar/advances/domain/member_advance.dart';
import 'package:family_hub/features/bazar/expenses/domain/expense.dart';
import 'package:family_hub/features/bazar/expenses/domain/expense_repository.dart';
import 'package:family_hub/features/bazar/expenses/domain/funding.dart';
import 'package:family_hub/features/bazar/expenses/domain/write_plans.dart';
import 'package:family_hub/features/bazar/fund/domain/fund_repository.dart';
import 'package:family_hub/features/bazar/fund/domain/fund_transaction.dart';
import 'package:family_hub/features/bazar/fund/domain/month_closing.dart';
import 'package:family_hub/features/family/domain/family_repository.dart';
import 'package:family_hub/features/family/domain/permission_access.dart';

/// Soft-deletes an expense and reverses its fund/advance effects.
class SoftDeleteExpense {
  const SoftDeleteExpense({
    required this._expenses,
    required this._funds,
    required this._advances,
    required this._families,
    required this._clock,
    required this._newId,
    required FamilyDateKeys dateKeys,
  });

  final ExpenseRepository _expenses;
  final FundRepository _funds;
  final AdvanceRepository _advances;
  final FamilyRepository _families;
  final Clock _clock;
  final IdGenerator _newId;

  Future<Result<Expense>> call({
    required String actorUid,
    required String familyId,
    required String expenseId,
    String? eventId,
  }) async {
    final loaded = await _expenses.getExpense(familyId, expenseId);
    final loadFailure = loaded.failureOrNull;
    if (loadFailure != null) return Failure<Expense>(loadFailure);
    final old = loaded.valueOrNull;
    if (old == null) return const Failure<Expense>(NotFound(entity: 'expense'));

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

    if (old.isDeleted) return Success<Expense>(old);

    final lockFailure = await _monthLockFailure(familyId, old.monthKey);
    if (lockFailure != null) return Failure<Expense>(lockFailure);

    final advanceResult = await _advances.getAdvance(familyId, old.id);
    final advanceFailure = advanceResult.failureOrNull;
    if (advanceFailure != null) return Failure<Expense>(advanceFailure);
    final currentAdvance = advanceResult.valueOrNull;
    if (currentAdvance != null && currentAdvance.settled.paisa > 0) {
      return const Failure<Expense>(Conflict(code: 'advance_settled'));
    }

    final now = _clock.nowUtc();
    final updated = old.copyWith(deletedAt: now, deletedBy: actorUid);
    final storedEventId = eventId ?? _newId();
    final adjustments = old.funding == FundingSource.fund
        ? <FundTransaction>[
            FundTransaction.adjustment(
              eventId: storedEventId,
              suffix: 'del',
              amount: old.total,
              dateKey: old.dateKey,
              refType: FundRefType.expense,
              refId: old.id,
              createdBy: actorUid,
              createdAt: now,
            ),
          ]
        : const <FundTransaction>[];
    final advanceChange =
        old.funding == FundingSource.member && old.reimbursable
        ? _voidAdvance(currentAdvance)
        : null;

    final event = AuditEvent(
      id: storedEventId,
      type: AuditEventType.bazarExpenseDeleted,
      actorId: actorUid,
      refType: AuditRefType.expense,
      refId: old.id,
      at: now,
      params: <String, String>{
        'item': old.itemName,
        'amount': old.total.paisa.toString(),
      },
    );

    final saved = await _expenses.commitDelete(
      familyId,
      ExpenseDeletePlan(
        updated: updated,
        before: <String, Object?>{
          'deletedAt': old.deletedAt,
          'deletedBy': old.deletedBy,
        },
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

  AdvanceChange? _voidAdvance(MemberAdvance? advance) {
    if (advance == null || advance.status == AdvanceStatus.voided) return null;
    return AdvanceChange(
      after: MemberAdvance(
        expenseId: advance.expenseId,
        memberId: advance.memberId,
        amount: advance.amount,
        settled: advance.settled,
        status: AdvanceStatus.voided,
        dateKey: advance.dateKey,
        monthKey: advance.monthKey,
      ),
    );
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
