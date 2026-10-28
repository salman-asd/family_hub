import 'package:family_hub/core/audit/audit_event.dart';
import 'package:family_hub/core/audit/audit_event_type.dart';
import 'package:family_hub/core/audit/audit_ref_type.dart';
import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/core/permissions/permissions.dart';
import 'package:family_hub/core/utils/clock.dart';
import 'package:family_hub/core/utils/id_generator.dart';
import 'package:family_hub/features/chores/templates/domain/chore_template.dart';
import 'package:family_hub/features/chores/templates/domain/template_enums.dart';
import 'package:family_hub/features/chores/templates/domain/template_repository.dart';
import 'package:family_hub/features/family/domain/family_repository.dart';
import 'package:family_hub/features/family/domain/permission_access.dart';

/// Copies a template into an independent new one (P3-07).
///
/// The copy gets a new id, `revision = 1`, `sortOrder = max + 1`, the same
/// schedule and content, `builtIn = false` and `seedKey = null` — so editing
/// the copy never touches the original, and a starter-pack template can be
/// copied without the copy counting as "already applied".
///
/// [nameSuffix] is the localized "(copy)" text from the ARB files; the domain
/// never hard-codes it. When the result would exceed the name limit the suffix
/// is dropped rather than producing an invalid template.
class DuplicateTemplate {
  const DuplicateTemplate({
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
    required String templateId,
    required String nameSuffix,
  }) async {
    final permitted = await requirePermission(
      _families,
      familyId: familyId,
      actorUid: actorUid,
      permission: Permission.manageChoreTemplates,
    );
    final denied = permitted.failureOrNull;
    if (denied != null) return Failure<ChoreTemplate>(denied);

    final found = await _templates.get(familyId, templateId);
    final readFailure = found.failureOrNull;
    if (readFailure != null) return Failure<ChoreTemplate>(readFailure);
    final source = found.valueOrNull;
    if (source == null) {
      return const Failure<ChoreTemplate>(NotFound(entity: 'template'));
    }

    final listed = await _templates.list(familyId);
    final listFailure = listed.failureOrNull;
    if (listFailure != null) return Failure<ChoreTemplate>(listFailure);
    final all = listed.valueOrNull ?? const <ChoreTemplate>[];

    final draft = source.draft.copyWith(
      nameBn: _withSuffix(source.draft.nameBn, nameSuffix),
      nameEn: source.draft.nameEn == null
          ? null
          : _withSuffix(source.draft.nameEn!, nameSuffix),
    );

    var maxSortOrder = -1;
    for (final template in all) {
      if (template.sortOrder > maxSortOrder) maxSortOrder = template.sortOrder;
    }

    final copy = source.copyAsNew(
      newId: _newId(),
      newDraft: draft,
      sortOrder: maxSortOrder + 1,
    );

    final written = await _templates.save(
      familyId,
      copy,
      AuditEvent(
        id: _newId(),
        type: AuditEventType.choresTemplateDuplicated,
        actorId: actorUid,
        refType: AuditRefType.choreTemplate,
        refId: copy.id,
        at: _clock.nowUtc(),
        params: <String, String>{'name': draft.nameBn},
      ),
    );
    final writeFailure = written.failureOrNull;
    if (writeFailure != null) return Failure<ChoreTemplate>(writeFailure);
    return Success<ChoreTemplate>(copy);
  }

  /// `name + suffix`, unless that would pass the limit: then the name is cut
  /// so the suffix still fits (the suffix is the part that identifies the copy).
  static String _withSuffix(String name, String suffix) {
    const max = TemplateLimits.maxNameLength;
    if (name.length + suffix.length <= max) return '$name$suffix';
    final room = max - suffix.length;
    if (room <= 0) return name.substring(0, max);
    return '${name.substring(0, room).trimRight()}$suffix';
  }
}
