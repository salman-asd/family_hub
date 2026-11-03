import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/features/chores/comments/domain/occurrence_comment.dart';
import 'package:family_hub/features/chores/comments/domain/usecases/add_comment.dart';

/// Flags a chore as incorrect or incomplete (P3-25): a comment with a reason
/// that also sets `needsAttention` on the occurrence and tells the assignee.
///
/// A flag IS a comment (the text is the reason, 1-1000 characters), so this is
/// [AddComment] with `flagged: true`; it exists as its own use case so a screen
/// asks for exactly what it means and a test names the intent.
class MarkNeedsAttention {
  const MarkNeedsAttention(this._addComment);

  final AddComment _addComment;

  Future<Result<OccurrenceComment>> call({
    required String familyId,
    required String actorUid,
    required String occurrenceId,
    required String commentId,
    required String reason,
  }) => _addComment(
    familyId: familyId,
    actorUid: actorUid,
    occurrenceId: occurrenceId,
    commentId: commentId,
    text: reason,
    flagged: true,
  );
}
