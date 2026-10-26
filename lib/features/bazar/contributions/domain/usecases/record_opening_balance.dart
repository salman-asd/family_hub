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
import 'package:family_hub/features/bazar/contributions/domain/contribution_guards.dart';
import 'package:family_hub/features/bazar/contributions/domain/contribution_repository.dart';
import 'package:family_hub/features/bazar/contributions/domain/contribution_write_plans.dart';
import 'package:family_hub/features/bazar/expenses/domain/expense_validation.dart';
import 'package:family_hub/features/bazar/fund/domain/fund_repository.dart';
import 'package:family_hub/features/bazar/fund/domain/fund_transaction.dart';
import 'package:family_hub/features/bazar/settings/domain/bazar_settings_repository.dart';
import 'package:family_hub/features/family/domain/family_repository.dart';
import 'package:family_hub/features/family/domain/permission_access.dart';

/// Sets up the fund once: its first month and, when not zero, the money that is
/// already in it (an `opening` ledger row, `open_<yyyy-MM>`).
///
/// Allowed only while `settings/bazar.fundStartMonth` is empty (otherwise
/// `Conflict('fund_already_started')`).  The row and the setting are written
/// in ONE server-required batch.
///
/// Permission: `editFamilySettings` (admin).  The rules let only an admin
/// write an `opening` row (P2-10), so a Household Manager would be denied at
/// commit; asking for the admin permission here keeps the UI honest.
class RecordOpeningBalance {
  const RecordOpeningBalance({
    required this._contributions,
    required this._settings,
    required this._funds,
    required this._families,
    required this._clock,
    required this._newId,
    required this._dateKeys,
  });

  final ContributionRepository _contributions;
  final BazarSettingsRepository _settings;
  final FundRepository _funds;
  final FamilyRepository _families;
  final Clock _clock;
  final IdGenerator _newId;
  final FamilyDateKeys _dateKeys;

  Future<Result<void>> call({
    required String actorUid,
    required String familyId,
    required MonthKey startMonth,
    required Money amount,
    String? note,
    String? eventId,
  }) async {
    final permitted = await requirePermission(
      _families,
      familyId: familyId,
      actorUid: actorUid,
      permission: Permission.editFamilySettings,
    );
    final denied = permitted.failureOrNull;
    if (denied != null) return Failure<void>(denied);

    if (startMonth.compareTo(_dateKeys.thisMonth()) > 0) {
      return const Failure<void>(Validation('startMonth', 'future_date'));
    }
    if ((note ?? '').trim().runes.length > kMaxContributionNote) {
      return const Failure<void>(Validation('note', 'too_long'));
    }

    final settings = await _settings.get(familyId);
    final settingsFailure = settings.failureOrNull;
    if (settingsFailure != null) return Failure<void>(settingsFailure);
    if (settings.valueOrNull!.fundStartMonth != null) {
      return const Failure<void>(Conflict(code: 'fund_already_started'));
    }

    final locked = await monthLockFailure(_funds, familyId, [startMonth]);
    if (locked != null) return Failure<void>(locked);

    final now = _clock.nowUtc();
    return _contributions.commitOpeningBalance(
      familyId,
      OpeningBalancePlan(
        startMonth: startMonth,
        opening: amount.isZero
            ? null
            : FundTransaction.opening(
                monthKey: startMonth,
                amount: amount,
                createdBy: actorUid,
                createdAt: now,
                note: cleanOptional(note),
              ),
      ),
      AuditEvent(
        id: eventId ?? _newId(),
        type: AuditEventType.bazarOpeningBalanceSet,
        actorId: actorUid,
        refType: AuditRefType.month,
        refId: startMonth.toString(),
        at: now,
        params: <String, String>{
          'month': startMonth.toString(),
          'amount': amount.paisa.toString(),
        },
      ),
    );
  }
}
