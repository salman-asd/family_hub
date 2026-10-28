import 'package:family_hub/core/audit/audit_event.dart';
import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/features/chores/templates/domain/chore_template.dart';

/// Port for `choreTemplates/{id}`.
///
/// Templates are never deleted: [save] writes a whole document (the use cases
/// build it from the current state), and the audit entry rides in the same
/// batch.
abstract interface class TemplateRepository {
  /// Live templates, in `sortOrder` order, bounded by the caller's limit.
  Stream<List<ChoreTemplate>> watch(String familyId);

  /// One-shot read of every template (for `sortOrder = max + 1`).
  Future<Result<List<ChoreTemplate>>> list(String familyId);

  Future<Result<ChoreTemplate?>> get(String familyId, String templateId);

  /// Creates or replaces one template and writes [event] in the same batch.
  Future<Result<void>> save(
    String familyId,
    ChoreTemplate template,
    AuditEvent event,
  );
}
