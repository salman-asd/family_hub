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
import 'package:family_hub/features/chores/templates/domain/template_validator.dart';
import 'package:family_hub/features/family/domain/family_repository.dart';
import 'package:family_hub/features/family/domain/permission_access.dart';

/// Creates a chore template (P3-07).
///
/// Order: permission → validation → repository write. The template gets
/// `revision = 1` and `sortOrder = max + 1`, so the list keeps its order.
///
/// [seedKey] is set only by the starter-pack use case (P3-19): it makes the id
/// `tpl_<seedKey>` so applying the same pack twice cannot duplicate a template.
class CreateTemplate {
  const CreateTemplate({
    required this._templates,
    required this._families,
    required this._clock,
    required this._newId,
  });

  final TemplateRepository _templates;
  final FamilyRepository _families;
  final Clock _clock;
  final IdGenerator _newId;

  Future<Result<ChoreTemplate>> call({
    required String actorUid,
    required String familyId,
    required TemplateDraft draft,
    String? seedKey,
  }) async {
    final permitted = await requirePermission(
      _families,
      familyId: familyId,
      actorUid: actorUid,
      permission: Permission.manageChoreTemplates,
    );
    final denied = permitted.failureOrNull;
    if (denied != null) return Failure<ChoreTemplate>(denied);

    final invalid = TemplateValidator.validate(draft);
    if (invalid != null) return Failure<ChoreTemplate>(invalid);

    final existing = await _templates.list(familyId);
    final failure = existing.failureOrNull;
    if (failure != null) return Failure<ChoreTemplate>(failure);
    final current = <ChoreTemplate>[
      for (final record in existing.valueOrNull ?? const <TemplateRecord>[])
        record.template,
    ];
    if (seedKey != null && current.any((t) => t.seedKey == seedKey)) {
      return const Failure<ChoreTemplate>(Conflict(code: 'duplicate_id'));
    }

    final template = ChoreTemplate(
      id: seedKey == null ? _newId() : 'tpl_$seedKey',
      draft: draft,
      revision: 1,
      sortOrder: _nextSortOrder(current),
      builtIn: seedKey != null,
      seedKey: seedKey,
    );

    final written = await _templates.save(
      familyId,
      template,
      AuditEvent(
        id: _newId(),
        type: AuditEventType.choresTemplateCreated,
        actorId: actorUid,
        refType: AuditRefType.choreTemplate,
        refId: template.id,
        at: _clock.nowUtc(),
        params: <String, String>{'name': draft.nameBn},
      ),
    );
    final writeFailure = written.failureOrNull;
    if (writeFailure != null) return Failure<ChoreTemplate>(writeFailure);
    return Success<ChoreTemplate>(template);
  }

  static int _nextSortOrder(List<ChoreTemplate> templates) {
    var max = -1;
    for (final template in templates) {
      if (template.sortOrder > max) max = template.sortOrder;
    }
    return max + 1;
  }
}
