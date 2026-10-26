import 'package:family_hub/core/audit/audit_event_type.dart';
import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/core/permissions/permissions.dart';
import 'package:family_hub/core/utils/clock.dart';
import 'package:family_hub/core/utils/id_generator.dart';
import 'package:family_hub/features/bazar/contributions/domain/contribution.dart';
import 'package:family_hub/features/bazar/contributions/domain/contribution_guards.dart';
import 'package:family_hub/features/bazar/contributions/domain/contribution_repository.dart';
import 'package:family_hub/features/bazar/fund/domain/fund_repository.dart';
import 'package:family_hub/features/family/domain/family_repository.dart';
import 'package:family_hub/features/family/domain/permission_access.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/core/utils/family_date_keys.dart';
import 'package:family_hub/core/utils/money.dart';
import 'package:family_hub/features/bazar/expenses/domain/expense_validation.dart';

/// The owner of an APPROVED contribution asks for a change.
///
/// Only `pendingChange` is written; the ledger and `received` stay as they
/// are until a manager approves (`ApproveContributionChange`).  The request
/// carries the full new values, so an unchanged field is simply repeated.
class RequestContributionChange {
  const RequestContributionChange({
    required this._contributions,
    required this._funds,
    required this._families,
    required this._clock,
    required this._newId,
    required this._dateKeys,
  });

  final ContributionRepository _contributions;
  final FundRepository _funds;
  final FamilyRepository _families;
  final Clock _clock;
  final IdGenerator _newId;
  final FamilyDateKeys _dateKeys;

  Future<Result<Contribution>> call({
    required String actorUid,
    required String familyId,
    required String contributionId,
    required Money amount,
    required DateKey date,
    ContributionMethod? method,
    String? note,
    String? eventId,
  }) async {
    final permitted = await requirePermission(
      _families,
      familyId: familyId,
      actorUid: actorUid,
      permission: Permission.requestContribution,
    );
    final denied = permitted.failureOrNull;
    if (denied != null) return Failure<Contribution>(denied);

    final loaded = await _contributions.getContribution(
      familyId,
      contributionId,
    );
    final loadFailure = loaded.failureOrNull;
    if (loadFailure != null) return Failure<Contribution>(loadFailure);
    final current = loaded.valueOrNull;
    if (current == null) {
      return const Failure<Contribution>(NotFound(entity: 'contribution'));
    }
    // Only the member the money belongs to may ask for a change.
    if (current.memberId != actorUid) {
      return const Failure<Contribution>(PermissionDenied());
    }
    if (!current.isApproved) {
      return const Failure<Contribution>(
        Conflict(code: 'contribution_not_approved'),
      );
    }
    if (current.pendingChange != null) {
      return const Failure<Contribution>(
        Conflict(code: 'change_already_pending'),
      );
    }

    final invalid = validateContributionInput(
      amount: amount,
      date: date,
      today: _dateKeys.today(),
      note: note,
    );
    if (invalid != null) return Failure<Contribution>(invalid);
    final locked = await monthLockFailure(_funds, familyId, [
      current.monthKey,
      date.monthKey,
    ]);
    if (locked != null) return Failure<Contribution>(locked);

    final now = _clock.nowUtc();
    final updated = current.copyWith(
      pendingChange: ContributionChange(
        amount: amount,
        date: date,
        method: method,
        note: cleanOptional(note),
        requestedAt: now,
      ),
    );
    final saved = await _contributions.saveContribution(
      familyId,
      updated,
      contributionEvent(
        id: eventId ?? _newId(),
        type: AuditEventType.bazarContributionChangeRequested,
        actorId: actorUid,
        contribution: updated,
        at: now,
        extra: <String, String>{'newAmount': amount.paisa.toString()},
      ),
    );
    final failure = saved.failureOrNull;
    return failure != null
        ? Failure<Contribution>(failure)
        : Success<Contribution>(updated);
  }
}
