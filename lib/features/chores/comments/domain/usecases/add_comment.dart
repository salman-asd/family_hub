import 'package:family_hub/core/audit/audit_event_type.dart';
import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/core/permissions/permissions.dart';
import 'package:family_hub/core/utils/clock.dart';
import 'package:family_hub/core/utils/id_generator.dart';
import 'package:family_hub/features/chores/comments/domain/comment_loader.dart';
import 'package:family_hub/features/chores/comments/domain/comment_repository.dart';
import 'package:family_hub/features/chores/comments/domain/comment_write_plan.dart';
import 'package:family_hub/features/chores/comments/domain/occurrence_comment.dart';
import 'package:family_hub/features/chores/occurrences/domain/occurrence_write_plan.dart';
import 'package:family_hub/features/chores/occurrences/domain/usecases/occurrence_action_writer.dart';
import 'package:family_hub/features/notifications/domain/inbox_port.dart';

/// Adds a comment to a chore (P3-25). Any active member may comment
/// (`commentOnChore`), on a finished or verified chore too.
///
/// ONE batch: the comment, the occurrence marker (`lastCommentAt`, and
/// `needsAttention = true` for a FLAG), the materialized draft when the chore
/// was only projected, the inbox row for the assignee of a flagged chore and
/// the audit entry. EVERYDAY write: it queues offline.
///
/// The caller generates [commentId] once per intent (the composer, when it
/// opens), so a retry after a lost acknowledgement rewrites the same document.
class AddComment {
  const AddComment({
    required this.loader,
    required this.comments,
    required this.clock,
    this.inbox = const NoopInboxPort(),
    this.newId = randomId,
  });

  final CommentLoader loader;
  final CommentRepository comments;
  final Clock clock;
  final InboxPort inbox;
  final IdGenerator newId;

  Future<Result<OccurrenceComment>> call({
    required String familyId,
    required String actorUid,
    required String occurrenceId,
    required String commentId,
    required String text,
    bool flagged = false,
  }) async {
    final validated = CommentLimits.text(text);
    final invalid = validated.failureOrNull;
    if (invalid != null) return Failure<OccurrenceComment>(invalid);
    final body = validated.valueOrNull!;

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

    final occurrence = context.occurrence;
    final at = clock.nowUtc();
    final assignee = occurrence.assigneeId;
    final plan = OccurrenceActionWriter.planFor(
      context: context,
      at: at,
      patch: OccurrencePatch(
        occurrenceId: occurrenceId,
        fields: <String, Object?>{
          'lastCommentAt': at,
          if (flagged) 'needsAttention': true,
        },
      ),
      inbox: flagged && assignee != null && assignee != actorUid
          ? inbox.commentAttention(
              occurrenceId: occurrenceId,
              toMemberId: assignee,
              choreName: occurrence.nameBn,
              dateKey: occurrence.dateKey.toString(),
              authorId: actorUid,
            )
          : null,
      audit: const RequiredAudit(type: AuditEventType.choresCommentAdded),
      newId: newId,
    );

    final staged = await comments.stage(
      familyId,
      CommentWritePlan(
        occurrence: plan,
        comments: <NewComment>[
          NewComment(
            id: commentId,
            occurrenceId: occurrenceId,
            text: body,
            needsAttention: flagged,
          ),
        ],
      ),
    );
    final writeFailure = staged.failureOrNull;
    if (writeFailure != null) return Failure<OccurrenceComment>(writeFailure);
    return Success<OccurrenceComment>(
      OccurrenceComment(
        id: commentId,
        occurrenceId: occurrenceId,
        authorId: actorUid,
        text: body,
        createdAt: at,
        needsAttention: flagged,
      ),
    );
  }
}
