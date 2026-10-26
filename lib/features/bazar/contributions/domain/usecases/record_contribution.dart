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
import 'package:family_hub/features/bazar/fund/domain/fund_transaction.dart';
import 'package:family_hub/features/family/domain/family_repository.dart';
import 'package:family_hub/features/family/domain/permission_access.dart';

/// Manager path: records a contribution that is approved at once.
///
/// ONE batch: the contribution (`approved`) + its `con_<id>` ledger row + the
/// audit entry.  An everyday write: it queues offline, so pass the same [id]
/// and [eventId] when retrying.
class RecordContribution {
  const RecordContribution({
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
      permission: Permission.recordContribution,
    );
    final denied = permitted.failureOrNull;
    if (denied != null) return Failure<Contribution>(denied);

    final invalid = validateContributionInput(
      amount: amount,
      date: date,
      today: _dateKeys.today(),
      note: note,
    );
    if (invalid != null) return Failure<Contribution>(invalid);

    final memberResult = await _families.getMember(familyId, memberId);
    final memberFailure = memberResult.failureOrNull;
    if (memberFailure != null) return Failure<Contribution>(memberFailure);
    if (!(memberResult.valueOrNull?.isActive ?? false)) {
      return const Failure<Contribution>(
        Validation('memberId', 'member_required'),
      );
    }

    final locked = await monthLockFailure(_funds, familyId, [date.monthKey]);
    if (locked != null) return Failure<Contribution>(locked);

    final contributionId = id ?? _newId();
    final now = _clock.nowUtc();
    final cleanNote = cleanOptional(note);
    final contribution = Contribution(
      id: contributionId,
      memberId: memberId,
      monthKey: date.monthKey,
      dateKey: date,
      amount: amount,
      method: method,
      note: cleanNote,
      status: ContributionApproval.approved,
      requestedBy: actorUid,
      createdAt: now,
      fundTxId: 'con_$contributionId',
      decidedBy: actorUid,
      decidedAt: now,
    );
    final saved = await _contributions.commitContribution(
      familyId,
      ContributionWritePlan(
        contribution: contribution,
        fundTx: FundTransaction.forContribution(
          contributionId: contributionId,
          amount: amount,
          dateKey: date,
          createdBy: actorUid,
          createdAt: now,
          note: cleanNote,
        ),
      ),
      contributionEvent(
        id: eventId ?? _newId(),
        type: AuditEventType.bazarContributionRecorded,
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
