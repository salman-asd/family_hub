part of 'template_editor_controller.dart';

/// The draft setters of [TemplateEditorController] (P3-16).
///
/// They only read and replace the draft through the two hooks below, so the
/// mixin never touches the notifier's `state` (it is `@protected`).
mixin TemplateDraftSetters {
  TemplateDraft get _draft;

  void _edit(TemplateDraft draft);

  void setNameBn(String value) => _edit(_draft.copyWith(nameBn: value));

  void setNameEn(String value) => _edit(
    value.trim().isEmpty
        ? _draft.copyWith(clearNameEn: true)
        : _draft.copyWith(nameEn: value),
  );

  void setGroupId(String? value) => _edit(
    value == null
        ? _draft.copyWith(clearGroup: true)
        : _draft.copyWith(groupId: value),
  );

  void setIconKey(String? value) => _edit(
    value == null
        ? _draft.copyWith(clearIconKey: true)
        : _draft.copyWith(iconKey: value),
  );

  void setColorIndex(int? value) => _edit(
    value == null
        ? _draft.copyWith(clearColorIndex: true)
        : _draft.copyWith(colorIndex: value),
  );

  void setRecurrence(Recurrence value) =>
      _edit(_draft.copyWith(recurrence: value));

  /// Moves the start day and re-anchors the patterns that count from it.
  void setStartDate(DateKey value) {
    final recurrence = switch (_draft.recurrence) {
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
    final end = _draft.endDate;
    _edit(
      _draft.copyWith(
        startDate: value,
        recurrence: recurrence,
        endDate: end != null && end.isBefore(value) ? null : end,
        clearEndDate: end != null && end.isBefore(value),
      ),
    );
  }

  void setEndDate(DateKey? value) => _edit(
    value == null
        ? _draft.copyWith(clearEndDate: true)
        : _draft.copyWith(endDate: value),
  );

  void setSlots(List<TemplateSlot> value) =>
      _edit(_draft.copyWith(slots: value));

  void setAssignee(AssigneeSpec value) =>
      _edit(_draft.copyWith(assignee: value));

  void setInstructions(String value) =>
      _edit(_draft.copyWith(instructions: value));

  void setSubtasks(List<TemplateSubtask> value) =>
      _edit(_draft.copyWith(subtasks: value));

  void setEstimatedMinutes(int? value) => _edit(
    value == null
        ? _draft.copyWith(clearEstimatedMinutes: true)
        : _draft.copyWith(estimatedMinutes: value),
  );

  void setDifficulty(Difficulty value) =>
      _edit(_draft.copyWith(difficulty: value));

  void setVerification(VerificationMode value) =>
      _edit(_draft.copyWith(verification: value));

  void setReminders(ReminderConfig value) =>
      _edit(_draft.copyWith(reminders: value));
}

/// Regenerates from today to the marker (or the horizon when it is behind),
/// then replans the unstarted future work when that scope was chosen.
Future<AppFailure?> _planAfterSave(
  Ref ref, {
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
