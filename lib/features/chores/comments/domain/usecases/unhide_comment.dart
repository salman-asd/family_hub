import 'package:family_hub/core/audit/audit_event_type.dart';
import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/core/utils/clock.dart';
import 'package:family_hub/core/utils/id_generator.dart';
import 'package:family_hub/features/chores/comments/domain/comment_loader.dart';
import 'package:family_hub/features/chores/comments/domain/comment_moderation.dart';
import 'package:family_hub/features/chores/comments/domain/comment_repository.dart';
import 'package:family_hub/features/chores/comments/domain/occurrence_comment.dart';

/// Shows a hidden comment again (P3-25). A manager only; the note (3-200 characters) is kept in the audit entry and the comment's hide fields are cleared.
///
/// EVERYDAY write.
class UnhideComment {
  const UnhideComment({
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
    kind: CommentChangeKind.unhide,
    auditType: AuditEventType.choresCommentUnhidden,
    note: note,
  );
}
