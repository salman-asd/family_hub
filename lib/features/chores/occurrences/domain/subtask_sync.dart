import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/features/chores/occurrences/domain/chore_occurrence.dart';
import 'package:family_hub/features/chores/occurrences/domain/effective_status.dart';
import 'package:family_hub/features/chores/occurrences/domain/occurrence_status.dart';
import 'package:family_hub/features/chores/occurrences/domain/occurrence_write_plan.dart';

/// How [SubtaskSync.completionPatch] treats the steps of the chore.
enum CompletionMode {
  /// The parent checkbox: every open step is ticked by the same patch.
  tickEveryStep,

  /// The one-tap completion: only the completion is recorded; the steps are
  /// ticked only when every one of them is optional.
  recordOnly,
}

/// The pure tick rules of a chore (road map P3-11).
///
/// Each function returns an [OccurrencePatch] that names only the dotted keys
/// it changes, so two phones ticking different boxes merge instead of
/// overwriting. Nothing here writes: the caller puts the patch (and, where the
/// table says so, an `uncompleted` event) into an [OccurrenceWritePlan].
///
/// The permission check (`completeOwnChore` / `completeChoreForOthers`) and the
/// "is it deleted?" read belong to the use case (P3-14); these functions only
/// enforce the STATE rules (verified, skipped, deleted, required steps).
abstract final class SubtaskSync {
  /// Ticks or unticks one subtask.
  ///
  /// Completing the required set also sets `completedAt`/`completedBy`;
  /// unticking a completed task clears them. The caller adds an `uncompleted`
  /// event with `prevCompletedAt: occurrence.completedAt` when the patch
  /// demotes a completed occurrence (Appendix C).
  static Result<OccurrencePatch> toggleSubtask({
    required ChoreOccurrence occurrence,
    required String subtaskId,
    required String actorId,
    required DateTime at,
  }) {
    final blocked = _blocked(occurrence);
    if (blocked != null) return Failure<OccurrencePatch>(blocked);
    if (!occurrence.subtasks.any((subtask) => subtask.id == subtaskId)) {
      // The snapshot was replanned under this screen; the user must reload.
      return const Failure<OccurrencePatch>(Conflict(code: 'concurrent_edit'));
    }

    final done = Map<String, SubtaskDone>.of(occurrence.subtaskDone);
    final wasTicked = done.containsKey(subtaskId);
    if (wasTicked) {
      done.remove(subtaskId);
    } else {
      done[subtaskId] = SubtaskDone(at: at, by: actorId);
    }

    final next = _storedStatusFor(occurrence, done);
    final fields = <String, Object?>{
      'status': next.id,
      'updatedAt': at,
      'updatedBy': actorId,
    };
    final removed = <String>{};
    if (wasTicked) {
      removed.add('subtaskDone.$subtaskId');
    } else {
      fields['subtaskDone.$subtaskId'] = done[subtaskId]!.toMap();
    }

    if (next == OccurrenceStatus.completed) {
      if (occurrence.completedAt == null) {
        fields['completedAt'] = at;
        fields['completedBy'] = actorId;
      }
    } else if (occurrence.completedAt != null ||
        occurrence.completedBy != null) {
      // Also repairs a stale completedAt whose ticks were removed.
      removed.addAll(<String>{'completedAt', 'completedBy'});
    }

    return Success<OccurrencePatch>(
      OccurrencePatch(
        occurrenceId: occurrence.id,
        fields: fields,
        removedFields: removed,
      ),
    );
  }

  /// The parent checkbox.
  ///
  /// Checking ticks every unticked subtask and completes; unchecking is "undo
  /// completion": every subtask is unticked and the chore returns to
  /// `scheduled`. A chore without subtasks uses the parent box as its only
  /// control, so it completes and resets the same way.
  ///
  /// Completing with an open required step is refused with
  /// `Conflict('required_subtasks_open')` unless a manager already recorded an
  /// exception (Appendix C).
  static Result<OccurrencePatch> toggleParent({
    required ChoreOccurrence occurrence,
    required String actorId,
    required DateTime at,
  }) {
    final blocked = _blocked(occurrence);
    if (blocked != null) return Failure<OccurrencePatch>(blocked);

    final fields = <String, Object?>{'updatedAt': at, 'updatedBy': actorId};
    final removed = <String>{};

    if (effectiveStatus(occurrence) == ChoreStatus.completed) {
      for (final subtask in occurrence.subtasks) {
        removed.add('subtaskDone.${subtask.id}');
      }
      fields['status'] = OccurrenceStatus.scheduled.id;
      removed.addAll(<String>{'completedAt', 'completedBy'});
      return Success<OccurrencePatch>(
        OccurrencePatch(
          occurrenceId: occurrence.id,
          fields: fields,
          removedFields: removed,
        ),
      );
    }

    return completionPatch(
      occurrence: occurrence,
      actorId: actorId,
      at: at,
      mode: CompletionMode.tickEveryStep,
    );
  }

  /// The ONE patch that completes a chore (Q-01).
  ///
  /// `ToggleParent` (the checkbox) and `CompleteOccurrence` (the one-tap
  /// action) used to carry their own copy of "is a required step still open?"
  /// and "tick the optional steps". Both now ask here, so the rule exists once
  /// and the use cases only add permission, event and audit.
  ///
  /// * A REQUIRED step that is still open refuses with
  ///   `Conflict('required_subtasks_open')` unless a manager already recorded
  ///   an exception (Appendix C).
  /// * [CompletionMode.tickEveryStep] ticks every open step (the parent box
  ///   means "all done"); [CompletionMode.recordOnly] ticks nothing when a
  ///   required step exists (the completion is recorded under the REAL actor,
  ///   D-P3-14), and ticks the steps only when ALL of them are optional, so the
  ///   derived status can read `completed` from the ticks (D-P3-9).
  /// * The state rules of [toggleSubtask] apply (verified, skipped, deleted).
  static Result<OccurrencePatch> completionPatch({
    required ChoreOccurrence occurrence,
    required String actorId,
    required DateTime at,
    required CompletionMode mode,
  }) {
    final blocked = _blocked(occurrence);
    if (blocked != null) return Failure<OccurrencePatch>(blocked);

    // Only a step marked REQUIRED can block completion: an all-optional chore
    // is completed by the parent box, which ticks every step.
    final hasRequired = occurrence.subtasks.any((subtask) => subtask.required);
    final openRequired = occurrence.subtasks.any(
      (subtask) =>
          subtask.required && !occurrence.subtaskDone.containsKey(subtask.id),
    );
    if (openRequired && occurrence.exception == null) {
      return const Failure<OccurrencePatch>(
        Conflict(code: 'required_subtasks_open'),
      );
    }

    final fields = <String, Object?>{
      'status': OccurrenceStatus.completed.id,
      'completedAt': at,
      'completedBy': actorId,
      'updatedAt': at,
      'updatedBy': actorId,
    };
    final tickSteps = mode == CompletionMode.tickEveryStep || !hasRequired;
    if (tickSteps) {
      for (final subtask in occurrence.subtasks) {
        if (occurrence.subtaskDone.containsKey(subtask.id)) continue;
        fields['subtaskDone.${subtask.id}'] = SubtaskDone(
          at: at,
          by: actorId,
        ).toMap();
      }
    }
    return Success<OccurrencePatch>(
      OccurrencePatch(occurrenceId: occurrence.id, fields: fields),
    );
  }

  /// A verified or skipped chore is frozen; a deleted one is gone.
  static AppFailure? _blocked(ChoreOccurrence occurrence) {
    if (occurrence.isDeleted) {
      return const Conflict(code: 'occurrence_deleted');
    }
    final status = effectiveStatus(occurrence);
    if (status == ChoreStatus.verified) {
      return const Conflict(code: 'already_verified');
    }
    if (status == ChoreStatus.skipped) {
      return const Conflict(code: 'already_skipped');
    }
    return null;
  }

  /// The stored status that matches [done] (the derived status minus
  /// `overdue`, which is never stored).
  static OccurrenceStatus _storedStatusFor(
    ChoreOccurrence occurrence,
    Map<String, SubtaskDone> done,
  ) {
    final derived = effectiveStatus(occurrence.copyWith(subtaskDone: done));
    return switch (derived) {
      ChoreStatus.completed => OccurrenceStatus.completed,
      ChoreStatus.inProgress => OccurrenceStatus.inProgress,
      ChoreStatus.scheduled => OccurrenceStatus.scheduled,
      ChoreStatus.verified => OccurrenceStatus.verified,
      ChoreStatus.skipped => OccurrenceStatus.skipped,
      ChoreStatus.overdue => OccurrenceStatus.inProgress,
    };
  }
}
