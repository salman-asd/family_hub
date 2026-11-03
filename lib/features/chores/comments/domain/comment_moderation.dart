import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/core/permissions/permissions.dart';
import 'package:family_hub/core/utils/clock.dart';
import 'package:family_hub/core/utils/id_generator.dart';
import 'package:family_hub/features/chores/comments/domain/comment_flags.dart';
import 'package:family_hub/features/chores/comments/domain/comment_loader.dart';
import 'package:family_hub/features/chores/comments/domain/comment_repository.dart';
import 'package:family_hub/features/chores/comments/domain/comment_write_plan.dart';
import 'package:family_hub/features/chores/comments/domain/occurrence_comment.dart';
import 'package:family_hub/features/chores/occurrences/domain/usecases/occurrence_action_writer.dart';

/// The shared body of `HideComment` and `UnhideComment` (P3-25).
///
/// Both need `moderateChoreComments` (a manager) and a note of 3-200
/// characters, both write ONE audit entry, and both may flip the occurrence's
/// `needsAttention` marker (hiding the last open flag clears it, showing a hidden
/// open flag again sets it). Only the comment's own change differs, so the rule
/// lives here once.
Future<Result<OccurrenceComment>> moderateComment({
  required CommentLoader loader,
  required CommentRepository comments,
  required Clock clock,
  required IdGenerator newId,
  required String familyId,
  required String actorUid,
  required String occurrenceId,
  required String commentId,
  required CommentChangeKind kind,
  required String auditType,
  required String note,
}) async {
  final validated = CommentLimits.note(note);
  final invalid = validated.failureOrNull;
  if (invalid != null) return Failure<OccurrenceComment>(invalid);
  final reason = validated.valueOrNull!;

  final loaded = await loader.load(
    familyId: familyId,
    actorUid: actorUid,
    occurrenceId: occurrenceId,
  );
  final loadFailure = loaded.failureOrNull;
  if (loadFailure != null) return Failure<OccurrenceComment>(loadFailure);
  final context = loaded.valueOrNull!;
  final denied = context.require(Permission.moderateChoreComments).failureOrNull;
  if (denied != null) return Failure<OccurrenceComment>(denied);

  final listed = await comments.list(familyId, occurrenceId);
  final listFailure = listed.failureOrNull;
  if (listFailure != null) return Failure<OccurrenceComment>(listFailure);
  final thread = listed.valueOrNull!;
  final target = thread.where((c) => c.id == commentId).firstOrNull;
  if (target == null) {
    return const Failure<OccurrenceComment>(NotFound(entity: 'comment'));
  }
  if (!target.accepts(kind)) {
    return const Failure<OccurrenceComment>(Conflict(code: 'concurrent_edit'));
  }

  final at = clock.nowUtc();
  final openAfter = CommentFlags.openCount(
    CommentFlags.after(
      thread,
      commentId,
      kind,
      by: actorUid,
      at: at,
      note: reason,
    ),
  );
  final staged = await comments.stage(
    familyId,
    CommentWritePlan(
      occurrence: OccurrenceActionWriter.planFor(
        context: context,
        at: at,
        patch: CommentFlags.markerPatch(
          context.occurrence,
          openAfter: openAfter,
        ),
        audit: RequiredAudit(type: auditType, reason: reason),
        newId: newId,
      ),
      changes: <CommentChange>[
        CommentChange(
          commentId: commentId,
          occurrenceId: occurrenceId,
          kind: kind,
          note: kind == CommentChangeKind.hide ? reason : null,
        ),
      ],
    ),
  );
  final writeFailure = staged.failureOrNull;
  if (writeFailure != null) return Failure<OccurrenceComment>(writeFailure);
  return Success<OccurrenceComment>(
    target.after(kind, by: actorUid, at: at, note: reason),
  );
}
