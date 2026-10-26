import 'package:family_hub/core/audit/audit_event_type.dart';
import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/core/permissions/permissions.dart';
import 'package:family_hub/core/utils/clock.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/core/utils/family_date_keys.dart';
import 'package:family_hub/core/utils/id_generator.dart';
import 'package:family_hub/core/utils/money.dart';
import 'package:family_hub/features/bazar/contributions/domain/contribution.dart';
import 'package:family_hub/features/bazar/contributions/domain/contribution_guards.dart';
import 'package:family_hub/features/bazar/contributions/domain/contribution_repository.dart';
import 'package:family_hub/features/bazar/contributions/domain/contribution_write_plans.dart';
import 'package:family_hub/features/bazar/expenses/domain/expense_validation.dart';
import 'package:family_hub/features/bazar/fund/domain/fund_repository.dart';
import 'package:family_hub/features/family/domain/family_repository.dart';
import 'package:family_hub/features/family/domain/permission_access.dart';

/// Member path (D-P2-18): offers a contribution for the manager to decide.
///
/// Writes `status: pending` and NO ledger row, so a request never changes
/// `received` or the fund balance.  Queues offline.  A person who may record
/// contributions uses `RecordContribution` instead (auto-approved).
class RequestContribution {
  const RequestContribution({
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
    required String memberId,
    required Money amount,
    required DateKey date,
    ContributionMethod? method,
    String? note,
    String? id,
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
    // A request is always for oneself.
    if (memberId != actorUid) {
      return const Failure<Contribution>(PermissionDenied());
    }

    final invalid = validateContributionInput(
      amount: amount,
      date: date,
      today: _dateKeys.today(),
      note: note,
    );
    if (invalid != null) return Failure<Contribution>(invalid);

    final locked = await monthLockFailure(_funds, familyId, [date.monthKey]);
    if (locked != null) return Failure<Contribution>(locked);

    final now = _clock.nowUtc();
    final contribution = Contribution(
      id: id ?? _newId(),
      memberId: memberId,
      monthKey: date.monthKey,
      dateKey: date,
      amount: amount,
      method: method,
      note: cleanOptional(note),
      status: ContributionApproval.pending,
      requestedBy: actorUid,
      createdAt: now,
    );
    final saved = await _contributions.commitContribution(
      familyId,
      ContributionWritePlan(contribution: contribution),
      contributionEvent(
        id: eventId ?? _newId(),
        type: AuditEventType.bazarContributionRequested,
        actorId: actorUid,
        contribution: contribution,
        at: now,
      ),
    );
    final failure = saved.failureOrNull;
    return failure != null
        ? Failure<Contribution>(failure)
        : Success<Contribution>(contribution);
  }
}
