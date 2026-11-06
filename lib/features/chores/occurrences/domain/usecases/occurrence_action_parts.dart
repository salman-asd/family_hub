part of 'occurrence_action.dart';

/// A failure when the Appendix C table forbids [action], else null.
///
/// The use case has already checked the permission; this only turns a
/// "not allowed in this state" into the stable code the UI localizes.
///
/// Q-05: every action answers with the code that names WHY it was refused -
/// the actor (a missing right is `PermissionDenied`, a chore that is somebody
/// else's is `not_assigned_to_you`) or the state (`already_*`, `not_*`) - and
/// never falls back to "not assigned to you" for a reason that has nothing to
/// do with the assignee.
AppFailure? stateFailure(OccurrenceContext context, OccurrenceAction action) {
  final status = effectiveStatus(context.occurrence);
  if (OccurrenceStateMachine.can(status, action, context.actor)) return null;
  final actor = context.actor;
  return switch (action) {
    OccurrenceAction.verify =>
      !actor.isManager
          ? const PermissionDenied()
          : actor.isCompleter
          ? const Conflict(code: 'self_verification')
          : const Conflict(code: 'not_completed'),
    OccurrenceAction.reopen =>
      status == ChoreStatus.verified
          ? const Conflict(code: 'verified_requires_manager')
          : status == ChoreStatus.completed
          ? const PermissionDenied()
          : const Conflict(code: 'not_completed'),
    OccurrenceAction.unskip =>
      !actor.isManager
          ? const PermissionDenied()
          : const Conflict(code: 'not_skipped'),
    OccurrenceAction.tickSubtask ||
    OccurrenceAction.untickSubtask ||
    OccurrenceAction.checkParent ||
    OccurrenceAction.uncheckParent => _tickFailure(status, action, actor),
    OccurrenceAction.recordException ||
    OccurrenceAction.skip ||
    OccurrenceAction.reassign =>
      !actor.isManager
          ? const PermissionDenied()
          : _closedFailure(status) ?? const Conflict(code: 'concurrent_edit'),
    OccurrenceAction.acceptSwap =>
      !actor.hasAcceptedSwap
          ? const Conflict(code: 'not_a_recipient')
          : _closedFailure(status) ?? const Conflict(code: 'concurrent_edit'),
    OccurrenceAction.softDelete || OccurrenceAction.replan =>
      !actor.isManager
          ? const PermissionDenied()
          : const Conflict(code: 'occurrence_started'),
  };
}

/// Why a tick, untick or parent-box action was refused.
AppFailure _tickFailure(
  ChoreStatus status,
  OccurrenceAction action,
  OccurrenceActor actor,
) {
  if (status == ChoreStatus.skipped) {
    return const Conflict(code: 'already_skipped');
  }
  if (status == ChoreStatus.verified) {
    return const Conflict(code: 'already_verified');
  }
  if (!actor.mayTick) return const Conflict(code: 'not_assigned_to_you');
  return switch (action) {
    // Checking a chore that is already completed.
    OccurrenceAction.checkParent => const Conflict(code: 'already_completed'),
    // Unchecking or unticking a chore that is not completed / has no tick.
    _ => const Conflict(code: 'not_completed'),
  };
}

/// The code for an action that needs an OPEN chore, or null when the chore is
/// open (so the caller picks its own fallback).
AppFailure? _closedFailure(ChoreStatus status) => switch (status) {
  ChoreStatus.skipped => const Conflict(code: 'already_skipped'),
  ChoreStatus.verified => const Conflict(code: 'already_verified'),
  ChoreStatus.completed => const Conflict(code: 'already_completed'),
  _ => null,
};

/// A trimmed, validated reason (D-P3-17: 3-300 characters).
Result<String> requireReason(String? raw) {
  final reason = raw?.trim() ?? '';
  if (reason.length < 3) {
    return const Failure<String>(Validation('reason', 'reason_required'));
  }
  if (reason.length > 300) {
    return const Failure<String>(Validation('reason', 'too_long'));
  }
  return Success<String>(reason);
}
