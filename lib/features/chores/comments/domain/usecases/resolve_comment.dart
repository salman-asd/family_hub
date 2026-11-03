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

/// Marks a flagged comment as answered (P3-25).
///
/// Only the person who may act on the chore (its assignee, a manager, or any
/// member while `membersCanCompleteForOthers` is on: the same `mayTick` the
/// rules use) may resolve a flag. When it was the LAST open flag, the same batch
/// clears `needsAttention` on the occurrence.
///
/// A stale screen (the flag was resolved or hidden meanwhile) gets
/// `Conflict('concurrent_edit')`. EVERYDAY write.
class ResolveComment {
  const ResolveComment({
    required this.loader,
    required this.comments,
    required this.clock,
    this.newId = randomId,
  });

  final CommentLoader loader;
  final CommentRepository comments;
  final Clock clock;
  final IdGenerator newId;

  Future<Result<OccurrenceComment>> call({
    required String familyId,
    required String actorUid,
    required String occurrenceId,
    required String commentId,
  }) async {
    final loaded = await loader.load(
      familyId: familyId,
      actorUid: actorUid,
      occurrenceId: occurrenceId,
    );
    final loadFailure = loaded.failureOrNull;
    if (loadFailure != null) return Failure<OccurrenceComment>(loadFailure);
    final context = loaded.valueOrNull!;
    final denied = context.require(Permission.commentOnChore).failureOrNull;
    if (denied != null) return Failure<OccurrenceComment>(denied);
    if (!context.actor.mayTick) {
      return const Failure<OccurrenceComment>(
        Conflict(code: 'not_assigned_to_you'),
      );
    }

    final listed = await comments.list(familyId, occurrenceId);
    final listFailure = listed.failureOrNull;
    if (listFailure != null) return Failure<OccurrenceComment>(listFailure);
    final thread = listed.valueOrNull!;
    final target = thread.where((c) => c.id == commentId).firstOrNull;
    if (target == null) {
      return const Failure<OccurrenceComment>(NotFound(entity: 'comment'));
    }
    if (!target.accepts(CommentChangeKind.resolve)) {
      return const Failure<OccurrenceComment>(
        Conflict(code: 'concurrent_edit'),
      );
    }

    final at = clock.nowUtc();
    final openAfter = CommentFlags.openCount(
      CommentFlags.after(
        thread,
        commentId,
        CommentChangeKind.resolve,
        by: actorUid,
        at: at,
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
          newId: newId,
        ),
        changes: <CommentChange>[
          CommentChange(
            commentId: commentId,
            occurrenceId: occurrenceId,
            kind: CommentChangeKind.resolve,
          ),
        ],
      ),
    );
    final writeFailure = staged.failureOrNull;
    if (writeFailure != null) return Failure<OccurrenceComment>(writeFailure);
    return Success<OccurrenceComment>(
      target.after(CommentChangeKind.resolve, by: actorUid, at: at),
    );
  }
}
