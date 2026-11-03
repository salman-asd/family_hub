import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/features/chores/comments/domain/comment_write_plan.dart';
import 'package:family_hub/features/chores/comments/domain/occurrence_comment.dart';

/// Port for `choreOccurrences/{id}/comments` (P3-25).
///
/// Reads are bounded by `kMaxCommentsPerOccurrence` and ordered oldest first.
/// There is ONE write entry, [stage]: a comment action always changes the
/// occurrence marker too, so it is one batch (road map 3.4, EVERYDAY: it queues
/// offline). A use case never writes a comment field directly.
abstract interface class CommentRepository {
  /// The thread of one chore, oldest first. Hidden comments are included (the
  /// screen decides what each viewer may read).
  Stream<List<OccurrenceComment>> watchComments(
    String familyId,
    String occurrenceId,
  );

  /// One-shot read of the same thread (a resolve/hide asks "is this the last
  /// open flag?" on current data).
  Future<Result<List<OccurrenceComment>>> list(
    String familyId,
    String occurrenceId,
  );

  /// Applies [plan] in one batch.
  Future<Result<void>> stage(String familyId, CommentWritePlan plan);
}
