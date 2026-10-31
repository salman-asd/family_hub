import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/features/chores/occurrences/presentation/occurrence_providers.dart';
import 'package:family_hub/features/chores/settings/presentation/chore_settings_providers.dart';
import 'package:family_hub/features/chores/templates/domain/chore_template.dart';
import 'package:family_hub/features/chores/templates/domain/recurrence/recurrence.dart';
import 'package:family_hub/features/chores/templates/domain/template_parts.dart';
import 'package:family_hub/features/chores/templates/domain/template_saved.dart';
import 'package:family_hub/features/chores/templates/domain/template_validator.dart';
import 'package:family_hub/features/chores/templates/presentation/template_editor_state.dart';
import 'package:family_hub/features/chores/templates/presentation/template_providers.dart';
import 'package:family_hub/features/family/presentation/family_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The editor of one template; `null` means a new one.
///
/// Auto-disposed with its screen, so an abandoned draft never survives a
/// navigation (and two editors can never share state).
final templateEditorProvider = NotifierProvider.autoDispose
    .family<TemplateEditorController, TemplateEditorState, String?>(
      TemplateEditorController.new,
    );

/// Holds the immutable [TemplateDraft] and runs the save/planning flow.
///
/// Order inside [save] follows CLAUDE.md rule 12: validate → content write →
/// active switch → generate/regenerate. The content save is never rolled back
/// when planning fails; the screen shows a retry instead (road map P3-16).
class TemplateEditorController extends Notifier<TemplateEditorState> {
  TemplateEditorController(this.templateId);

  final String? templateId;

  @override
  TemplateEditorState build() {
    final template = templateId == null
        ? null
        : ref.read(templateProvider(templateId!));
    final today = ref.read(familyDateKeysProvider).today();
    final groups = ref.read(choreGroupsProvider);
    final draft =
        template?.draft ??
        TemplateDraft(
          nameBn: '',
          recurrence: const DailyRecurrence(),
          startDate: today,
          groupId: groups.isEmpty ? null : groups.first.id,
        );
    final active = template?.active ?? true;
    return TemplateEditorState(
      draft: draft,
      savedDraft: draft,
      templateId: templateId,
      active: active,
      savedActive: active,
      archived: template?.isArchived ?? false,
    );
  }

  // ── Setters ────────────────────────────────────────────────────────────────

  void setNameBn(String value) => _edit(state.draft.copyWith(nameBn: value));

  void setNameEn(String value) => _edit(
    value.trim().isEmpty
        ? state.draft.copyWith(clearNameEn: true)
        : state.draft.copyWith(nameEn: value),
  );

  void setGroupId(String? value) => _edit(
    value == null
        ? state.draft.copyWith(clearGroup: true)
        : state.draft.copyWith(groupId: value),
  );

  void setIconKey(String? value) => _edit(
    value == null
        ? state.draft.copyWith(clearIconKey: true)
        : state.draft.copyWith(iconKey: value),
  );

  void setColorIndex(int? value) => _edit(
    value == null
        ? state.draft.copyWith(clearColorIndex: true)
        : state.draft.copyWith(colorIndex: value),
  );

  void setRecurrence(Recurrence value) =>
      _edit(state.draft.copyWith(recurrence: value));

  /// Moves the start day and re-anchors the patterns that count from it.
  void setStartDate(DateKey value) {
    final recurrence = switch (state.draft.recurrence) {
      OnceRecurrence() => OnceRecurrence(value),
      EveryNDaysRecurrence(:final n) => EveryNDaysRecurrence(
        n: n,
        anchor: value,
      ),
      EveryNWeeksRecurrence(:final n, :final weekdays, :final weekStart) =>
        EveryNWeeksRecurrence(
          n: n,
          anchor: value,
          weekdays: weekdays,
          weekStart: weekStart,
        ),
      final other => other,
    };
    final end = state.draft.endDate;
    _edit(
      state.draft.copyWith(
        startDate: value,
        recurrence: recurrence,
        endDate: end != null && end.isBefore(value) ? null : end,
        clearEndDate: end != null && end.isBefore(value),
      ),
    );
  }

  void setEndDate(DateKey? value) => _edit(
    value == null
        ? state.draft.copyWith(clearEndDate: true)
        : state.draft.copyWith(endDate: value),
  );

  void setSlots(List<TemplateSlot> value) =>
      _edit(state.draft.copyWith(slots: value));

  void setAssignee(AssigneeSpec value) =>
      _edit(state.draft.copyWith(assignee: value));

  void setInstructions(String value) =>
      _edit(state.draft.copyWith(instructions: value));

  void setSubtasks(List<TemplateSubtask> value) =>
      _edit(state.draft.copyWith(subtasks: value));

  void setEstimatedMinutes(int? value) => _edit(
    value == null
        ? state.draft.copyWith(clearEstimatedMinutes: true)
        : state.draft.copyWith(estimatedMinutes: value),
  );

  void setDifficulty(Difficulty value) =>
      _edit(state.draft.copyWith(difficulty: value));

  void setVerification(VerificationMode value) =>
      _edit(state.draft.copyWith(verification: value));

  void setReminders(ReminderConfig value) =>
      _edit(state.draft.copyWith(reminders: value));

  void setActive(bool value) => state = state.copyWith(
    active: value,
    clearFieldError: true,
    clearSaveFailure: true,
    status: TemplateSaveStatus.idle,
  );

  void _edit(TemplateDraft draft) => state = state.copyWith(
    draft: draft,
    clearFieldError: true,
    clearSaveFailure: true,
    status: TemplateSaveStatus.idle,
  );

  // ── Save ───────────────────────────────────────────────────────────────────

  /// Validates, writes the content, applies the active switch and plans.
  ///
  /// Returns the outcome so the screen can decide whether to pop, show a
  /// failure banner, or offer the planning retry.
  Future<TemplateSaveStatus> save({
    ReplanScope replanScope = ReplanScope.futureOnly,
  }) async {
    if (state.saving || state.archived) return TemplateSaveStatus.idle;

    final invalid = TemplateValidator.validate(state.draft);
    if (invalid != null) {
      state = state.copyWith(
        fieldError: invalid,
        status: TemplateSaveStatus.invalid,
        clearSaveFailure: true,
        clearPlanningFailure: true,
      );
      return TemplateSaveStatus.invalid;
    }

    final uid = ref.read(currentUidProvider);
    final familyId = ref.read(currentFamilyIdProvider);
    if (uid == null || familyId == null) {
      return _fail(const Unknown('no_session'));
    }

    state = state.copyWith(
      saving: true,
      status: TemplateSaveStatus.idle,
      clearFieldError: true,
      clearSaveFailure: true,
      clearPlanningFailure: true,
    );

    try {
      final TemplateSaved saved;
      final currentId = state.templateId;
      if (currentId == null) {
        final result = await ref.read(createTemplateProvider)(
          actorUid: uid,
          familyId: familyId,
          draft: state.draft,
        );
        final failure = result.failureOrNull;
        if (failure != null) return _fail(failure);
        saved = TemplateSaved(
          template: result.valueOrNull!,
          replanScope: ReplanScope.futureOnly,
        );
      } else {
        final result = await ref.read(updateTemplateProvider)(
          actorUid: uid,
          familyId: familyId,
          templateId: currentId,
          draft: state.draft,
          replanScope: replanScope,
        );
        final failure = result.failureOrNull;
        if (failure != null) return _fail(failure);
        saved = result.valueOrNull!;
      }

      state = state.copyWith(
        templateId: saved.template.id,
        savedDraft: state.draft,
        savedActive: saved.template.active,
        lastSaved: saved,
        saving: false,
      );

      final postFailure =
          await _applyActiveSwitch(uid: uid, familyId: familyId) ??
          await _plan(
            uid: uid,
            familyId: familyId,
            saved: saved,
          );
      if (postFailure != null) {
        state = state.copyWith(
          planningFailure: postFailure,
          status: TemplateSaveStatus.planningFailed,
        );
        return TemplateSaveStatus.planningFailed;
      }
      state = state.copyWith(
        status: TemplateSaveStatus.saved,
        clearPlanningFailure: true,
      );
      return TemplateSaveStatus.saved;
    } on Object catch (error) {
      return _fail(Unknown(error));
    }
  }

  /// Re-runs the active switch and planning of the last content save.
  Future<TemplateSaveStatus> retryPlanning() async {
    final saved = state.lastSaved;
    final uid = ref.read(currentUidProvider);
    final familyId = ref.read(currentFamilyIdProvider);
    if (state.saving || saved == null || uid == null || familyId == null) {
      return state.status;
    }
    state = state.copyWith(saving: true, clearPlanningFailure: true);
    try {
      final postFailure =
          await _applyActiveSwitch(uid: uid, familyId: familyId) ??
          await _plan(uid: uid, familyId: familyId, saved: saved);
      if (postFailure != null) {
        state = state.copyWith(
          saving: false,
          planningFailure: postFailure,
          status: TemplateSaveStatus.planningFailed,
        );
        return TemplateSaveStatus.planningFailed;
      }
      state = state.copyWith(
        saving: false,
        status: TemplateSaveStatus.saved,
        clearPlanningFailure: true,
      );
      return TemplateSaveStatus.saved;
    } on Object catch (error) {
      state = state.copyWith(
        saving: false,
        planningFailure: Unknown(error),
        status: TemplateSaveStatus.planningFailed,
      );
      return TemplateSaveStatus.planningFailed;
    }
  }

  TemplateSaveStatus _fail(AppFailure failure) {
    state = state.copyWith(
      saving: false,
      saveFailure: failure,
      status: TemplateSaveStatus.failed,
    );
    return TemplateSaveStatus.failed;
  }

  /// Pause or resume when the switch differs from what is stored.
  Future<AppFailure?> _applyActiveSwitch({
    required String uid,
    required String familyId,
  }) async {
    final id = state.templateId;
    if (id == null || state.active == state.savedActive) return null;
    final Result<ChoreTemplate> result;
    if (state.active) {
      result = await ref.read(resumeTemplateProvider)(
        actorUid: uid,
        familyId: familyId,
        templateId: id,
      );
    } else {
      result = await ref.read(pauseTemplateProvider)(
        actorUid: uid,
        familyId: familyId,
        templateId: id,
      );
    }
    final failure = result.failureOrNull;
    if (failure != null) return failure;
    state = state.copyWith(savedActive: state.active);
    return null;
  }

  /// Regenerates from today to the marker (or the horizon when it is behind),
  /// then replans the unstarted future work when that scope was chosen.
  Future<AppFailure?> _plan({
    required String uid,
    required String familyId,
    required TemplateSaved saved,
  }) async {
    final today = ref.read(familyDateKeysProvider).today();
    final marker = ref.read(generationThroughProvider);
    final horizon = ref.read(choreSettingsProvider).generationHorizonDays;
    final to = marker != null && !marker.isBefore(today)
        ? marker
        : today.addDays(horizon);

    final regenerated = await ref.read(regenerateRangeProvider)(
      familyId: familyId,
      actorUid: uid,
      from: today,
      to: to,
      templateId: saved.template.id,
    );
    final regenerateFailure = regenerated.failureOrNull;
    if (regenerateFailure != null) return regenerateFailure;

    if (saved.replanScope != ReplanScope.includeUpcoming) return null;
    final replanned = await ref.read(replanOccurrencesProvider)(
      familyId: familyId,
      actorUid: uid,
      templateId: saved.template.id,
      from: today,
    );
    return replanned.failureOrNull;
  }
}
