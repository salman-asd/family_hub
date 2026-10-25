import 'package:family_hub/core/audit/audit_event.dart';
import 'package:family_hub/core/audit/audit_event_type.dart';
import 'package:family_hub/core/audit/audit_ref_type.dart';
import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/core/permissions/permissions.dart';
import 'package:family_hub/core/utils/clock.dart';
import 'package:family_hub/core/utils/id_generator.dart';
import 'package:family_hub/features/bazar/budgets/domain/budget.dart';
import 'package:family_hub/features/bazar/budgets/domain/budget_repository.dart';
import 'package:family_hub/features/bazar/budgets/domain/budget_validation.dart';
import 'package:family_hub/features/family/domain/family_repository.dart';
import 'package:family_hub/features/family/domain/permission_access.dart';

/// Saves a month's budget: permission, validation, then ONE batch (the budget
/// document plus its audit entry).
///
/// An everyday write: no server probe, so it queues offline.  A budget is a
/// plan, so a closed month does not block it (it never touches the ledger).
/// Pass the same [eventId] when retrying so the log gets one entry.
class SaveBudget {
  const SaveBudget({
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
    required Budget budget,
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

    final prepared = prepareBudget(budget);
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
        refId: ready.month.toString(),
        at: _clock.nowUtc(),
        params: <String, String>{
          'month': ready.month.toString(),
          'amount': ready.totalEstimate.paisa.toString(),
        },
      ),
    );
  }
}
