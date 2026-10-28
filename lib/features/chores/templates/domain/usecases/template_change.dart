import 'package:family_hub/core/audit/audit_event.dart';
import 'package:family_hub/core/audit/audit_ref_type.dart';
import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/core/permissions/permissions.dart';
import 'package:family_hub/core/utils/clock.dart';
import 'package:family_hub/core/utils/id_generator.dart';
import 'package:family_hub/features/chores/templates/domain/chore_template.dart';
import 'package:family_hub/features/chores/templates/domain/template_repository.dart';
import 'package:family_hub/features/family/domain/family_repository.dart';
import 'package:family_hub/features/family/domain/permission_access.dart';

/// The skeleton the four lifecycle use cases share (pause, resume, archive,
/// duplicate): check the permission, load the template, apply ONE change, save
/// it with an audit entry.
///
/// Kept in one place so the four use cases cannot drift in their permission
/// order or their "not found" behaviour. Not exported from the feature's
/// barrel: it is an implementation detail of `usecases/`.
Future<Result<ChoreTemplate>> applyTemplateChange({
  required TemplateRepository templates,
  required FamilyRepository families,
  required Clock clock,
  required IdGenerator newId,
  required String actorUid,
  required String familyId,
  required String templateId,
  required String auditType,
  required ChoreTemplate Function(ChoreTemplate current) change,
  Map<String, String> Function(ChoreTemplate saved)? params,

  /// Optional guard: a non-null failure stops the change before any write.
  AppFailure? Function(ChoreTemplate current)? reject,
}) async {
  final permitted = await requirePermission(
    families,
    familyId: familyId,
    actorUid: actorUid,
    permission: Permission.manageChoreTemplates,
  );
  final denied = permitted.failureOrNull;
  if (denied != null) return Failure<ChoreTemplate>(denied);

  final found = await templates.get(familyId, templateId);
  final readFailure = found.failureOrNull;
  if (readFailure != null) return Failure<ChoreTemplate>(readFailure);
  final current = found.valueOrNull;
  if (current == null) {
    return const Failure<ChoreTemplate>(NotFound(entity: 'template'));
  }

  final saved = change(current);
  final rejected = reject?.call(current);
  if (rejected != null) return Failure<ChoreTemplate>(rejected);
  final written = await templates.save(
    familyId,
    saved,
    AuditEvent(
      id: newId(),
      type: auditType,
      actorId: actorUid,
      refType: AuditRefType.choreTemplate,
      refId: saved.id,
      at: clock.nowUtc(),
      params:
          params?.call(saved) ?? <String, String>{'name': saved.draft.nameBn},
    ),
  );
  final writeFailure = written.failureOrNull;
  if (writeFailure != null) return Failure<ChoreTemplate>(writeFailure);
  return Success<ChoreTemplate>(saved);
}
