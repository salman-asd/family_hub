import 'package:family_hub/features/chores/comments/domain/occurrence_comment.dart';
import 'package:family_hub/features/chores/occurrences/domain/chore_occurrence.dart';
import 'package:family_hub/features/chores/occurrences/domain/occurrence_write_plan.dart';

/// The "needs attention" marker of the OCCURRENCE, derived from its comments.
///
/// The occurrence holds one boolean (`needsAttention`) so the calendar and the
/// tiles need no comment read. It is true while at least one flagged comment is
/// neither resolved nor hidden (road map P3-25: "clears when the last flagged
/// comment is resolved").
abstract final class CommentFlags {
  static int openCount(Iterable<OccurrenceComment> comments) =>
      comments.where((comment) => comment.isOpenFlag).length;

  /// The thread after [kind] was applied to [commentId].
  static List<OccurrenceComment> after(
    List<OccurrenceComment> comments,
    String commentId,
    CommentChangeKind kind, {
    required String by,
    required DateTime at,
    String? note,
  }) => <OccurrenceComment>[
    for (final comment in comments)
      if (comment.id == commentId)
        comment.after(kind, by: by, at: at, note: note)
      else
        comment,
  ];

  /// The patch that brings `needsAttention` in line with [openAfter], or null
  /// when it already agrees. `lastCommentAt` is NOT touched: a resolve or a
  /// hide is not a new comment.
  static OccurrencePatch? markerPatch(
    ChoreOccurrence occurrence, {
    required int openAfter,
  }) {
    final shouldFlag = openAfter > 0;
    if (occurrence.needsAttention == shouldFlag) return null;
    return OccurrencePatch(
      occurrenceId: occurrence.id,
      fields: <String, Object?>{'needsAttention': shouldFlag},
    );
  }

  /// Whether the viewer has unread comments: something was said after
  /// [seenAt] (a local instant; null = never opened).
  static bool hasUnread(DateTime? lastCommentAt, DateTime? seenAt) =>
      lastCommentAt != null &&
      (seenAt == null || lastCommentAt.isAfter(seenAt));
}
