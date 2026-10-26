import 'package:family_hub/core/audit/audit_event.dart';
import 'package:family_hub/core/audit/audit_event_type.dart';
import 'package:family_hub/core/audit/audit_ref_type.dart';
import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/core/permissions/permissions.dart';
import 'package:family_hub/core/utils/clock.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/core/utils/id_generator.dart';
import 'package:family_hub/features/bazar/contributions/domain/contribution.dart';
import 'package:family_hub/features/bazar/contributions/domain/contribution_plan_generator.dart';
import 'package:family_hub/features/bazar/contributions/domain/contribution_repository.dart';
import 'package:family_hub/features/bazar/settings/domain/bazar_settings_repository.dart';
import 'package:family_hub/features/family/domain/family_repository.dart';
import 'package:family_hub/features/family/domain/member.dart';
import 'package:family_hub/features/family/domain/permission_access.dart';

/// Creates the month's plans: the family's monthly target (settings) split
/// equally among the ACTIVE members (D-P2-11).
///
/// The split is computed over every active member so the shares always add up
/// to the target, but only members WITHOUT a plan get one written: an existing
/// override is never overwritten.  Returns the plans it created (empty when
/// nobody was missing; nothing is written then).  A target of zero is
/// `Validation('target', 'required')`.
class GenerateMonthPlans {
  const GenerateMonthPlans({
    required this._contributions,
    required this._settings,
    required this._families,
    required this._clock,
    required this._newId,
  });

  final ContributionRepository _contributions;
  final BazarSettingsRepository _settings;
  final FamilyRepository _families;
  final Clock _clock;
  final IdGenerator _newId;

  Future<Result<List<ContributionPlan>>> call({
    required String actorUid,
    required String familyId,
    required MonthKey month,
    String? eventId,
  }) async {
    final permitted = await requirePermission(
      _families,
      familyId: familyId,
      actorUid: actorUid,
      permission: Permission.recordContribution,
    );
    final denied = permitted.failureOrNull;
    if (denied != null) return Failure<List<ContributionPlan>>(denied);

    final settings = await _settings.get(familyId);
    final settingsFailure = settings.failureOrNull;
    if (settingsFailure != null) {
      return Failure<List<ContributionPlan>>(settingsFailure);
    }
    final target = settings.valueOrNull!.defaultMonthlyContribution;
    if (target.paisa <= 0) {
      return const Failure<List<ContributionPlan>>(
        Validation('target', 'required'),
      );
    }

    final members = await _families.getMembers(familyId);
    final membersFailure = members.failureOrNull;
    if (membersFailure != null) {
      return Failure<List<ContributionPlan>>(membersFailure);
    }
    final activeIds = <String>[
      for (final m in members.valueOrNull ?? const <Member>[])
        if (m.isActive) m.uid,
    ];

    final existing = await _contributions.getPlans(familyId, month);
    final existingFailure = existing.failureOrNull;
    if (existingFailure != null) {
      return Failure<List<ContributionPlan>>(existingFailure);
    }
    final hasPlan = <String>{
      for (final p in existing.valueOrNull ?? const <ContributionPlan>[])
        p.memberId,
    };

    final created = <ContributionPlan>[
      for (final plan in generateEqualSplit(
        month: month,
        target: target,
        activeMemberIds: activeIds,
      ))
        if (!hasPlan.contains(plan.memberId)) plan,
    ];
    if (created.isEmpty) {
      return const Success<List<ContributionPlan>>(<ContributionPlan>[]);
    }

    final saved = await _contributions.savePlans(
      familyId,
      created,
      AuditEvent(
        id: eventId ?? _newId(),
        type: AuditEventType.bazarContributionPlanSet,
        actorId: actorUid,
        refType: AuditRefType.contributionPlan,
        refId: month.toString(),
        at: _clock.nowUtc(),
        params: <String, String>{
          'month': month.toString(),
          'count': created.length.toString(),
          'amount': target.paisa.toString(),
        },
      ),
    );
    final failure = saved.failureOrNull;
    return failure != null
        ? Failure<List<ContributionPlan>>(failure)
        : Success<List<ContributionPlan>>(created);
  }
}
