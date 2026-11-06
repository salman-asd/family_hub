import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/core/permissions/permission.dart';
import 'package:family_hub/core/permissions/permission_settings.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/core/utils/family_date_keys.dart';
import 'package:family_hub/features/chores/duty_groups/domain/duty_group_repository.dart';
import 'package:family_hub/features/chores/occurrences/domain/chore_occurrence.dart';
import 'package:family_hub/features/chores/occurrences/domain/effective_status.dart';
import 'package:family_hub/features/chores/occurrences/domain/occurrence_draft.dart';
import 'package:family_hub/features/chores/occurrences/domain/occurrence_id.dart';
import 'package:family_hub/features/chores/occurrences/domain/occurrence_repository.dart';
import 'package:family_hub/features/chores/occurrences/domain/occurrence_state_machine.dart';
import 'package:family_hub/features/chores/occurrences/domain/occurrence_status.dart';
import 'package:family_hub/features/chores/occurrences/domain/usecases/drafts_for.dart';
import 'package:family_hub/features/chores/settings/domain/chore_settings_repository.dart';
import 'package:family_hub/features/chores/templates/domain/chore_template.dart';
import 'package:family_hub/features/chores/templates/domain/template_parts.dart';
import 'package:family_hub/features/chores/templates/domain/template_repository.dart';
import 'package:family_hub/features/family/domain/family_repository.dart';
import 'package:family_hub/features/family/domain/member.dart';
import 'package:family_hub/features/family/domain/permission_access.dart';

part 'occurrence_action_parts.dart';

/// What one action needs to know about the occurrence and the actor, loaded
/// once from the current state (P3-14).
///
/// Every completion use case starts here, so "the document is missing but a
/// template still implies it" is materialized the same way everywhere (D-P3-6)
/// and the [OccurrenceActor] value the state machine sees can never differ
/// between two actions on the same occurrence.
final class OccurrenceContext {
  const OccurrenceContext({
    required this.occurrence,
    required this.actor,
    required this.member,
    this.permissions = PermissionSettings.defaults,
    this.draft,
  });

  /// The stored document, or the generator's draft for a PROJECTED item.
  final ChoreOccurrence occurrence;

  /// The pure actor value of [OccurrenceStateMachine].
  final OccurrenceActor actor;

  /// The acting member document (names for the audit params).
  final Member member;

  /// The family's permission switches, read ONCE with the member (Q-02).
  final PermissionSettings permissions;

  /// The create to stage with the action; null when the document exists.
  final OccurrenceDraft? draft;

  /// Asks the permission matrix with the member and the switches this context
  /// already holds, so an action does not read them a second time (Q-02).
  Result<Member> require(
    Permission permission, {
    String? ownerId,
    PermissionTemplate? template,
  }) => checkPermission(
    member,
    permission,
    settings: permissions,
    ownerId: ownerId,
    template: template,
  );

  bool get isProjected => draft != null;

  /// Builds the context from an occurrence, a member and the family switches.
  factory OccurrenceContext.build({
    required ChoreOccurrence occurrence,
    required Member member,
    required PermissionSettings settings,
    OccurrenceDraft? draft,
  }) => OccurrenceContext(
    occurrence: occurrence,
    draft: draft,
    member: member,
    permissions: settings,
    actor: OccurrenceActor(
      uid: member.uid,
      isManager:
          settings.isModuleEnabled(PermissionModule.chores) &&
          member.permissionActor.isManager,
      // M-06: ONE definition of "the assignee" everywhere (rules `mayTick`,
      // `CompleteOccurrence`, this context): `assigneeId` only. A chore nobody
      // owns is somebody else's (road map 3.3) - only a manager or the family
      // switch lets a member act on it.
      isAssignee: occurrence.assigneeId == member.uid,
      canCompleteForOthers: settings.membersCanCompleteForOthers,
      isCompleter:
          occurrence.completedBy != null &&
          occurrence.completedBy == member.uid,
    ),
  );
}

PermissionTemplate permissionTemplateFor(VerificationMode mode) =>
    PermissionTemplate(verificationEnabled: mode == VerificationMode.required);

/// Loads the occurrence an action is about.
///
/// Order: the stored document (`get`), else the template's current snapshot for
/// that exact id (a projected day, D-P3-6), else `NotFound`.
Future<Result<OccurrenceContext>> loadOccurrenceContext({
  required OccurrenceRepository occurrences,
  required TemplateRepository templates,
  required DutyGroupRepository dutyGroups,
  required ChoreSettingsRepository settings,
  required FamilyRepository families,
  required FamilyDateKeys dateKeys,
  required String familyId,
  required String occurrenceId,
  required String actorUid,
}) async {
  final loadedMember = await families.getMember(familyId, actorUid);
  final memberFailure = loadedMember.failureOrNull;
  if (memberFailure != null) {
    return Failure<OccurrenceContext>(memberFailure);
  }
  final member = loadedMember.valueOrNull;
  if (member == null) {
    return const Failure<OccurrenceContext>(NotFound(entity: 'member'));
  }

  final loadedPermissions = await families.getPermissionSettings(familyId);
  final permissionFailure = loadedPermissions.failureOrNull;
  if (permissionFailure != null) {
    return Failure<OccurrenceContext>(permissionFailure);
  }
  final permissions =
      loadedPermissions.valueOrNull ?? PermissionSettings.defaults;

  final stored = await occurrences.get(familyId, occurrenceId);
  final readFailure = stored.failureOrNull;
  if (readFailure != null) return Failure<OccurrenceContext>(readFailure);
  final document = stored.valueOrNull;
  if (document != null) {
    if (document.isDeleted) {
      return const Failure<OccurrenceContext>(
        Conflict(code: 'occurrence_deleted'),
      );
    }
    return Success<OccurrenceContext>(
      OccurrenceContext.build(
        occurrence: document,
        member: member,
        settings: permissions,
      ),
    );
  }

  final projected = await _draftFor(
    occurrenceId: occurrenceId,
    templates: templates,
    dutyGroups: dutyGroups,
    choreSettings: settings,
    families: families,
    familyId: familyId,
    dateKeys: dateKeys,
  );
  final draftFailure = projected.failureOrNull;
  if (draftFailure != null) {
    return Failure<OccurrenceContext>(draftFailure);
  }
  final draft = projected.valueOrNull;
  if (draft == null) {
    return const Failure<OccurrenceContext>(NotFound(entity: 'occurrence'));
  }
  // A projected item that an approved absence already covers is UNASSIGNED
  // (D-P3-12); `OccurrenceContext.build` then treats only a manager (or the
  // family switch) as allowed to act on it, so it is never handed to whoever
  // taps first.
  return Success<OccurrenceContext>(
    OccurrenceContext.build(
      occurrence: draft.toOccurrence(),
      member: member,
      settings: permissions,
      draft: draft,
    ),
  );
}

/// One draft for the requested id, when the template still implies it.
///
/// Built by the shared [draftsFor] (duty groups, absence policy, roster), so it
/// is exactly what `EnsureOccurrences` and the calendar projection would build
/// for that day (B-08, C-9).
Future<Result<OccurrenceDraft?>> _draftFor({
  required String occurrenceId,
  required TemplateRepository templates,
  required DutyGroupRepository dutyGroups,
  required ChoreSettingsRepository choreSettings,
  required FamilyRepository families,
  required String familyId,
  required FamilyDateKeys dateKeys,
}) async {
  final parsed = OccurrenceId.parse(occurrenceId).valueOrNull;
  if (parsed == null) return const Success<OccurrenceDraft?>(null);

  final found = await templates.get(familyId, parsed.templateId);
  final failure = found.failureOrNull;
  if (failure != null) return Failure<OccurrenceDraft?>(failure);
  final template = found.valueOrNull?.template;
  if (template == null) return const Success<OccurrenceDraft?>(null);

  final built = await draftsFor(
    familyId: familyId,
    templates: <ChoreTemplate>[template],
    range: DateKeyRange(parsed.dateKey, parsed.dateKey),
    dutyGroups: dutyGroups,
    settings: choreSettings,
    families: families,
    dateKeys: dateKeys,
  );
  final builtFailure = built.failureOrNull;
  if (builtFailure != null) return Failure<OccurrenceDraft?>(builtFailure);
  for (final draft in built.valueOrNull!) {
    if (draft.id == occurrenceId) return Success<OccurrenceDraft?>(draft);
  }
  return const Success<OccurrenceDraft?>(null);
}
