import 'package:family_hub/features/chores/comments/domain/occurrence_comment.dart';
import 'package:family_hub/features/chores/occurrences/domain/occurrence_write_plan.dart';

/// A comment to create. The author and the instant come from the plan.
final class NewComment {
  const NewComment({
    required this.id,
    required this.occurrenceId,
    required this.text,
    this.needsAttention = false,
  });

  /// Generated ONCE per user intent, so a retry rewrites the same document.
  final String id;
  final String occurrenceId;
  final String text;
  final bool needsAttention;

  @override
  String toString() => 'NewComment($id on $occurrenceId)';
}

/// One change to an existing comment (resolve, hide, unhide).
final class CommentChange {
  const CommentChange({
    required this.commentId,
    required this.occurrenceId,
    required this.kind,
    this.note,
  });

  final String commentId;
  final String occurrenceId;
  final CommentChangeKind kind;

  /// The moderation note of a hide (3-200 characters); null otherwise.
  final String? note;

  @override
  String toString() => 'CommentChange(${kind.name} $commentId)';
}

/// Everything ONE comment action writes, in ONE batch.
///
/// The comment documents and the occurrence marker (`lastCommentAt`,
/// `needsAttention`, a materialized draft, the inbox row, the audit entry) must
/// land together or not at all, so the occurrence part is a plain
/// [OccurrenceWritePlan] that the same batch stages.
final class CommentWritePlan {
  const CommentWritePlan({
    required this.occurrence,
    this.comments = const <NewComment>[],
    this.changes = const <CommentChange>[],
  });

  final OccurrenceWritePlan occurrence;
  final List<NewComment> comments;
  final List<CommentChange> changes;

  String get actorId => occurrence.actorId;
  DateTime get at => occurrence.at;

  @override
  String toString() =>
      'CommentWritePlan(${comments.length} new, ${changes.length} changes, '
      '$occurrence)';
}
