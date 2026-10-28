import 'package:family_hub/core/audit/audit_event.dart';
import 'package:family_hub/core/audit/audit_event_type.dart';
import 'package:family_hub/core/audit/audit_ref_type.dart';
import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/core/permissions/permissions.dart';
import 'package:family_hub/core/utils/clock.dart';
import 'package:family_hub/core/utils/id_generator.dart';
import 'package:family_hub/features/chores/templates/domain/chore_template.dart';
import 'package:family_hub/features/chores/templates/domain/template_repository.dart';
import 'package:family_hub/features/chores/templates/domain/template_saved.dart';
import 'package:family_hub/features/chores/templates/domain/template_validator.dart';
import 'package:family_hub/features/family/domain/family_repository.dart';
import 'package:family_hub/features/family/domain/permission_access.dart';

/// Edits a template's content and bumps its `revision` (P3-07, D-P3-23).
///
/// It returns [TemplateSaved] with the [ReplanScope] the user chose. The CALLER
/// (the editor controller, P3-16) then runs `RegenerateRange` /
/// `ReplanOccurrences` (P3-12): this use case never touches occurrences, so a
/// domain step cannot half-fail across two features.
///
/// A content edit always bumps `revision` by exactly one (the P3-08 rule
/// enforces the same); the identity fields (`id`, `builtIn`, `seedKey`,
/// `sortOrder`, `active`, `archivedAt`) are kept as they were.
class UpdateTemplate {
  const UpdateTemplate({
    required this._templates,
    required this._families,
    required this._clock,
    required this._newId,
  });

  final TemplateRepository _templates;
  final FamilyRepository _families;
  final Clock _clock;
  final IdGenerator _newId;

  Future<Result<TemplateSaved>> call({
    required String actorUid,
    required String familyId,
    required String templateId,
    required TemplateDraft draft,
    ReplanScope replanScope = ReplanScope.futureOnly,
  }) async {
    final permitted = await requirePermission(
      _families,
      familyId: familyId,
      actorUid: actorUid,
      permission: Permission.manageChoreTemplates,
    );
    final denied = permitted.failureOrNull;
    if (denied != null) return Failure<TemplateSaved>(denied);

    final invalid = TemplateValidator.validate(draft);
    if (invalid != null) return Failure<TemplateSaved>(invalid);

    final found = await _templates.get(familyId, templateId);
    final readFailure = found.failureOrNull;
    if (readFailure != null) return Failure<TemplateSaved>(readFailure);
    final current = found.valueOrNull?.template;
    if (current == null) {
      return const Failure<TemplateSaved>(NotFound(entity: 'template'));
    }

    final updated = current.copyWith(
      draft: draft,
      revision: current.revision + 1,
    );

    final written = await _templates.save(
      familyId,
      updated,
      AuditEvent(
        id: _newId(),
        type: AuditEventType.choresTemplateUpdated,
        actorId: actorUid,
        refType: AuditRefType.choreTemplate,
        refId: templateId,
        at: _clock.nowUtc(),
        params: <String, String>{
          'name': draft.nameBn,
          'rev': '${updated.revision}',
        },
      ),
    );
    final writeFailure = written.failureOrNull;
    if (writeFailure != null) return Failure<TemplateSaved>(writeFailure);
    return Success<TemplateSaved>(
      TemplateSaved(template: updated, replanScope: replanScope),
    );
  }
}
