import 'package:family_hub/core/audit/audit_event.dart';
import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/features/chores/templates/domain/chore_template.dart';

/// Port for `choreTemplates/{id}`.
///
/// Templates are never deleted: [save] writes a whole document (the use cases
/// build it from the current state), and the audit entry rides in the same
/// batch.
///
/// Reads return a [TemplateRecord], not a bare [ChoreTemplate], because a
/// template whose stored schedule this build cannot read must still be LISTED
/// (as "invalid schedule") instead of disappearing or crashing the screen.
abstract interface class TemplateRepository {
  /// Live templates, in `sortOrder` order, bounded by `kMaxChoreTemplates`.
  Stream<List<TemplateRecord>> watch(String familyId);

  /// One-shot read of every template (for `sortOrder = max + 1`).
  Future<Result<List<TemplateRecord>>> list(String familyId);

  Future<Result<TemplateRecord?>> get(String familyId, String templateId);

  /// Creates or replaces one template and writes [event] in the same batch.
  Future<Result<void>> save(
    String familyId,
    ChoreTemplate template,
    AuditEvent event,
  );
}

/// A template plus what the READER had to repair.
///
/// [invalidSchedule] is true when the stored `recurrence` could not be read (an
/// unknown `kind`, or a shape this build does not understand). The template is
/// still listed; the UI shows "invalid schedule" and the manager can edit or
/// archive it. Every other repair (a missing `main` slot, a dropped malformed
/// row) is silent and not reported here.
final class TemplateRecord {
  const TemplateRecord({required this.template, this.invalidSchedule = false});

  final ChoreTemplate template;
  final bool invalidSchedule;

  @override
  String toString() =>
      'TemplateRecord(${template.id}, invalidSchedule: $invalidSchedule)';
}
