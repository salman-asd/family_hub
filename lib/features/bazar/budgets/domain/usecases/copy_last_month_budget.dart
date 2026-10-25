import 'package:family_hub/core/audit/audit_event.dart';
import 'package:family_hub/core/audit/audit_event_type.dart';
import 'package:family_hub/core/audit/audit_ref_type.dart';
import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/core/permissions/permissions.dart';
import 'package:family_hub/core/utils/clock.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/core/utils/id_generator.dart';
import 'package:family_hub/features/bazar/budgets/domain/budget.dart';
import 'package:family_hub/features/bazar/budgets/domain/budget_repository.dart';
import 'package:family_hub/features/bazar/budgets/domain/budget_validation.dart';
import 'package:family_hub/features/family/domain/family_repository.dart';
import 'package:family_hub/features/family/domain/permission_access.dart';

/// Starts [month]'s plan from the previous month's: estimates, lines and alert
/// levels are copied, the "in stock" quantities are cleared (they were true
/// last month only).
///
/// A missing previous budget is `NotFound(entity: 'budget')`; a month that
/// already has a budget is `Conflict(code: 'budget_exists')`, so a copy can
/// never overwrite somebody's plan.
class CopyLastMonthBudget {
  const CopyLastMonthBudget({
    required this._budgets,
    required this._families,
    required this._clock,
    required this._newId,
  });

  final BudgetRepository _budgets;
  final FamilyRepository _families;
  final Clock _clock;
  final IdGenerator _newId;

  Future<Result<void>> call({
    required String actorUid,
    required String familyId,
    required MonthKey month,
    String? eventId,
  }) async {
    final permitted = await requirePermission(
      _families,
      familyId: familyId,
      actorUid: actorUid,
      permission: Permission.manageCatalogAndBudgets,
    );
    final denied = permitted.failureOrNull;
    if (denied != null) return Failure<void>(denied);

    final previousResult = await _budgets.getBudget(
      familyId,
      month.addMonths(-1),
    );
    final readFailure = previousResult.failureOrNull;
    if (readFailure != null) return Failure<void>(readFailure);
    final previous = previousResult.valueOrNull;
    if (previous == null) {
      return const Failure<void>(NotFound(entity: 'budget'));
    }

    final existingResult = await _budgets.getBudget(familyId, month);
    final existingFailure = existingResult.failureOrNull;
    if (existingFailure != null) return Failure<void>(existingFailure);
    if (existingResult.valueOrNull != null) {
      return const Failure<void>(Conflict(code: 'budget_exists'));
    }

    final copy = Budget(
      month: month,
      totalEstimate: previous.totalEstimate,
      categoryEstimates: previous.categoryEstimates,
      lines: <BudgetLine>[
        for (final line in previous.lines) line.copyWith(clearStock: true),
      ],
      alertThresholds: previous.alertThresholds,
    );
    final prepared = prepareBudget(copy);
    final invalid = prepared.failureOrNull;
    if (invalid != null) return Failure<void>(invalid);
    final ready = prepared.valueOrNull!;

    return _budgets.saveBudget(
      familyId,
      ready,
      AuditEvent(
        id: eventId ?? _newId(),
        type: AuditEventType.bazarBudgetSaved,
        actorId: actorUid,
        refType: AuditRefType.budget,
        refId: month.toString(),
        at: _clock.nowUtc(),
        params: <String, String>{
          'month': month.toString(),
          'amount': ready.totalEstimate.paisa.toString(),
        },
      ),
    );
  }
}
