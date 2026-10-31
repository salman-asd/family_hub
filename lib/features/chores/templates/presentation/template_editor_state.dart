import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/features/chores/templates/domain/chore_template.dart';
import 'package:family_hub/features/chores/templates/domain/template_saved.dart';

/// What the last save attempt did.
enum TemplateSaveStatus {
  /// Nothing has been attempted yet (or a field changed since the last try).
  idle,

  /// The draft failed [TemplateValidator]; [TemplateEditorState.fieldError]
  /// names the field and the stable code.
  invalid,

  /// The content write failed; nothing was saved.
  failed,

  /// The content and the planning run both succeeded.
  saved,

  /// The content was saved but the follow-up (active switch or planning) failed.
  /// The template is never rolled back; the screen offers a retry.
  planningFailed,
}

/// Everything the template editor holds while it is open.
///
/// [draft] is the immutable content being edited; [savedDraft] is the last
/// version the server accepted, so "unsaved changes" is one value comparison.
final class TemplateEditorState {
  const TemplateEditorState({
    required this.draft,
    required this.savedDraft,
    required this.active,
    required this.savedActive,
    this.templateId,
    this.archived = false,
    this.saving = false,
    this.fieldError,
    this.saveFailure,
    this.planningFailure,
    this.lastSaved,
    this.status = TemplateSaveStatus.idle,
  });

  final TemplateDraft draft;
  final TemplateDraft savedDraft;

  /// Null until the first successful save of a new template.
  final String? templateId;

  /// The active switch as the user wants it.
  final bool active;

  /// The active switch as the server has it.
  final bool savedActive;

  /// Archived templates are read-only in this step.
  final bool archived;

  final bool saving;

  /// The first validator problem, if the last save was rejected locally.
  final Validation? fieldError;

  /// The content write failed.
  final AppFailure? saveFailure;

  /// The content was saved but the active switch or planning failed.
  final AppFailure? planningFailure;

  /// The last successful content save, used by [retryPlanning].
  final TemplateSaved? lastSaved;

  final TemplateSaveStatus status;

  bool get isNew => templateId == null;

  bool get isDirty => draft != savedDraft || active != savedActive;

  /// True when the save bar should stay disabled.
  bool get cannotSave => saving || archived;

  TemplateEditorState copyWith({
    TemplateDraft? draft,
    TemplateDraft? savedDraft,
    String? templateId,
    bool? active,
    bool? savedActive,
    bool? archived,
    bool? saving,
    Validation? fieldError,
    AppFailure? saveFailure,
    AppFailure? planningFailure,
    TemplateSaved? lastSaved,
    TemplateSaveStatus? status,
    bool clearFieldError = false,
    bool clearSaveFailure = false,
    bool clearPlanningFailure = false,
  }) => TemplateEditorState(
    draft: draft ?? this.draft,
    savedDraft: savedDraft ?? this.savedDraft,
    templateId: templateId ?? this.templateId,
    active: active ?? this.active,
    savedActive: savedActive ?? this.savedActive,
    archived: archived ?? this.archived,
    saving: saving ?? this.saving,
    fieldError: clearFieldError ? null : (fieldError ?? this.fieldError),
    saveFailure: clearSaveFailure ? null : (saveFailure ?? this.saveFailure),
    planningFailure: clearPlanningFailure
        ? null
        : (planningFailure ?? this.planningFailure),
    lastSaved: lastSaved ?? this.lastSaved,
    status: status ?? this.status,
  );

  @override
  String toString() =>
      'TemplateEditorState(${templateId ?? 'new'}, '
      'dirty: $isDirty, status: ${status.name})';
}
