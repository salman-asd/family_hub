import 'package:family_hub/core/audit/audit_event.dart';
import 'package:family_hub/core/audit/audit_event_type.dart';
import 'package:family_hub/core/audit/audit_ref_type.dart';
import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/core/permissions/permissions.dart';
import 'package:family_hub/core/utils/clock.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/core/utils/id_generator.dart';
import 'package:family_hub/core/utils/money.dart';
import 'package:family_hub/features/bazar/contributions/domain/contribution.dart';
import 'package:family_hub/features/bazar/contributions/domain/contribution_repository.dart';
import 'package:family_hub/features/family/domain/family_repository.dart';
import 'package:family_hub/features/family/domain/permission_access.dart';

/// Sets one member's expected amount for one month (a per-member override of
/// the equal split).  A plan is a plan, not a ledger row: a closed month does
/// not block it.  An everyday write; it queues offline.
class SetContributionPlan {
  const SetContributionPlan({
    required this._contributions,
    required this._families,
    required this._clock,
    required this._newId,
  });

  final ContributionRepository _contributions;
  final FamilyRepository _families;
  final Clock _clock;
  final IdGenerator _newId;

  Future<Result<ContributionPlan>> call({
    required String actorUid,
    required String familyId,
    required String memberId,
    required MonthKey month,
    required Money expected,
    String? eventId,
  }) async {
    final permitted = await requirePermission(
      _families,
      familyId: familyId,
      actorUid: actorUid,
      permission: Permission.recordContribution,
    );
    final denied = permitted.failureOrNull;
    if (denied != null) return Failure<ContributionPlan>(denied);

    if (expected.isNegative) {
      return const Failure<ContributionPlan>(Validation('expected', 'negative'));
    }
    final memberResult = await _families.getMember(familyId, memberId);
    final memberFailure = memberResult.failureOrNull;
    if (memberFailure != null) return Failure<ContributionPlan>(memberFailure);
    if (!(memberResult.valueOrNull?.isActive ?? false)) {
      return const Failure<ContributionPlan>(
        Validation('memberId', 'member_required'),
      );
    }

    final plan = ContributionPlan(
      month: month,
      memberId: memberId,
      expected: expected,
    );
    final saved = await _contributions.savePlans(
      familyId,
      <ContributionPlan>[plan],
      AuditEvent(
        id: eventId ?? _newId(),
        type: AuditEventType.bazarContributionPlanSet,
        actorId: actorUid,
        refType: AuditRefType.contributionPlan,
        refId: plan.id,
        at: _clock.nowUtc(),
        params: <String, String>{
          'member': memberId,
          'month': month.toString(),
          'amount': expected.paisa.toString(),
        },
      ),
    );
    final failure = saved.failureOrNull;
    return failure != null
        ? Failure<ContributionPlan>(failure)
        : Success<ContributionPlan>(plan);
  }
}
