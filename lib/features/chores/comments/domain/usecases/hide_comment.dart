import 'package:family_hub/core/audit/audit_event_type.dart';
import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/core/utils/clock.dart';
import 'package:family_hub/core/utils/id_generator.dart';
import 'package:family_hub/features/chores/comments/domain/comment_loader.dart';
import 'package:family_hub/features/chores/comments/domain/comment_moderation.dart';
import 'package:family_hub/features/chores/comments/domain/comment_repository.dart';
import 'package:family_hub/features/chores/comments/domain/occurrence_comment.dart';

/// Hides a comment from the thread (P3-25). Comments are never deleted (D-P3-18, rule 42): a manager hides one with a note of 3-200 characters, everybody then sees "hidden by a manager" and only managers read the original text. The note goes to the audit entry and to the comment itself.
///
/// EVERYDAY write.
class HideComment {
  const HideComment({
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
    required String note,
  }) => moderateComment(
    loader: loader,
    comments: comments,
    clock: clock,
    newId: newId,
    familyId: familyId,
    actorUid: actorUid,
    occurrenceId: occurrenceId,
    commentId: commentId,
    kind: CommentChangeKind.hide,
    auditType: AuditEventType.choresCommentHidden,
    note: note,
  );
}
