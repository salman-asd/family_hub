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
import 'package:family_hub/features/bazar/advances/domain/advance_repository.dart';
import 'package:family_hub/features/bazar/advances/domain/settlement_builder.dart';
import 'package:family_hub/features/bazar/advances/domain/settlement_plan.dart';
import 'package:family_hub/features/bazar/contributions/domain/contribution_guards.dart';
import 'package:family_hub/features/bazar/fund/domain/fund_repository.dart';
import 'package:family_hub/features/family/domain/family_repository.dart';
import 'package:family_hub/features/family/domain/permission_access.dart';

/// Pays a member back for a member-funded, reimbursable expense.
///
/// Permission `recordContribution`; the amount must be positive, the date must
/// not be in the future and its month must be open.  The repository then reads
/// the advance INSIDE a transaction and calls [buildSettlementPlan], so the
/// remaining amount is always the current one (`Conflict('overpayment')`,
/// `Conflict('advance_voided')`, `NotFound('advance')`).  ONE batch: the
/// settlement, the `stl_<id>` ledger row, the advance update and the audit
/// entry.
///
/// Needs the server (rule 26): a queued offline settlement could pay the same
/// rupees twice.
class SettleAdvance {
  const SettleAdvance({
    required this._advances,
    required this._funds,
    required this._families,
    required this._clock,
    required this._newId,
    required this._dateKeys,
  });

  final AdvanceRepository _advances;
  final FundRepository _funds;
  final FamilyRepository _families;
  final Clock _clock;
  final IdGenerator _newId;
  final FamilyDateKeys _dateKeys;

  Future<Result<SettlementPlan>> call({
    required String actorUid,
    required String familyId,
    required String expenseId,
    required Money amount,
    DateKey? date,
    String? method,
    String? note,
    String? settlementId,
    String? eventId,
  }) async {
    final permitted = await requirePermission(
      _families,
      familyId: familyId,
      actorUid: actorUid,
      permission: Permission.recordContribution,
    );
    final denied = permitted.failureOrNull;
    if (denied != null) return Failure<SettlementPlan>(denied);

    if (amount.paisa <= 0) {
      return const Failure<SettlementPlan>(
        Validation('amount', 'amount_not_positive'),
      );
    }
    final day = date ?? _dateKeys.today();
    if (day.isAfter(_dateKeys.today())) {
      return const Failure<SettlementPlan>(
        Validation('dateKey', 'future_date'),
      );
    }
    if ((note ?? '').trim().runes.length > kMaxContributionNote) {
      return const Failure<SettlementPlan>(Validation('note', 'too_long'));
    }
    final locked = await monthLockFailure(_funds, familyId, [day.monthKey]);
    if (locked != null) return Failure<SettlementPlan>(locked);

    final now = _clock.nowUtc();
    final id = settlementId ?? _newId();
    final plan = await _advances.commitSettlement(
      familyId,
      advanceId: expenseId,
      build: (current) => buildSettlementPlan(
        current: current,
        amount: amount,
        date: day,
        at: now,
        actorUid: actorUid,
        settlementId: id,
        method: _clean(method),
        note: _clean(note),
      ),
      event: AuditEvent(
        id: eventId ?? id,
        type: AuditEventType.bazarAdvanceSettled,
        actorId: actorUid,
        // The vocabulary has no `advance` ref type; a settlement is the record.
        refType: AuditRefType.settlement,
        refId: id,
        at: now,
        params: <String, String>{
          'settlement': id,
          'amount': amount.paisa.toString(),
          'date': day.toString(),
        },
      ),
    );
    final failure = plan.failureOrNull;
    return failure != null
        ? Failure<SettlementPlan>(failure)
        : Success<SettlementPlan>(plan.valueOrNull!);
  }

  static String? _clean(String? text) {
    final trimmed = text?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }
}
