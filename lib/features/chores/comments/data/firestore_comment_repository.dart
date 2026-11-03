import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/core/firebase/base_mapper.dart';
import 'package:family_hub/core/firebase/firestore_guard.dart';
import 'package:family_hub/core/firebase/firestore_paths.dart';
import 'package:family_hub/core/firebase/query_limits.dart';
import 'package:family_hub/core/firebase/tx_runner.dart';
import 'package:family_hub/features/chores/comments/data/comment_mappers.dart';
import 'package:family_hub/features/chores/comments/domain/comment_repository.dart';
import 'package:family_hub/features/chores/comments/domain/comment_write_plan.dart';
import 'package:family_hub/features/chores/comments/domain/occurrence_comment.dart';
import 'package:family_hub/features/chores/occurrences/data/occurrence_write_stager.dart';

/// Firestore implementation of [CommentRepository].
///
/// ONE listener per open chore, bounded by [kMaxCommentsPerOccurrence] and
/// ordered by `createdAt` (a single-field order: no composite index). A write is
/// ONE batch that stages the occurrence part through the same
/// [OccurrenceWriteStager] every chore action uses, then the comment documents,
/// so a flag can never exist without its marker. Everyday write: no server
/// probe, so it queues offline.
class FirestoreCommentRepository implements CommentRepository {
  FirestoreCommentRepository({required TxRunner tx, FirebaseFirestore? firestore})
    : _tx = tx,
      _firestore = firestore;

  final TxRunner _tx;
  final FirebaseFirestore? _firestore;

  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  Query<Map<String, dynamic>> _thread(String familyId, String occurrenceId) =>
      _db
          .collection(FirestorePaths.occurrenceComments(familyId, occurrenceId))
          .orderBy(BaseMapper.keyCreatedAt)
          .limit(kMaxCommentsPerOccurrence);

  static List<OccurrenceComment> _read(
    String occurrenceId,
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) => <OccurrenceComment>[
    for (final doc in snapshot.docs)
      ?CommentMappers.fromDoc(occurrenceId, doc.id, doc.data()),
  ];

  @override
  Stream<List<OccurrenceComment>> watchComments(
    String familyId,
    String occurrenceId,
  ) => _thread(familyId, occurrenceId).snapshots().map(
    (snapshot) => _read(occurrenceId, snapshot),
  );

  @override
  Future<Result<List<OccurrenceComment>>> list(
    String familyId,
    String occurrenceId,
  ) => guardFirestore(() async {
    final snapshot = await _thread(familyId, occurrenceId).get();
    return _read(occurrenceId, snapshot);
  });

  @override
  Future<Result<void>> stage(String familyId, CommentWritePlan plan) =>
      guardWrite(
        () => _tx.runBatch((batch) {
          OccurrenceWriteStager.stage(batch, familyId, plan.occurrence);
          for (final comment in plan.comments) {
            batch.set(
              FirestorePaths.occurrenceCommentDoc(
                familyId,
                comment.occurrenceId,
                comment.id,
              ),
              CommentMappers.toMap(
                comment,
                authorId: plan.actorId,
                at: plan.at,
              ),
            );
          }
          for (final change in plan.changes) {
            batch.update(
              FirestorePaths.occurrenceCommentDoc(
                familyId,
                change.occurrenceId,
                change.commentId,
              ),
              CommentMappers.changeMap(
                change,
                actorId: plan.actorId,
                at: plan.at,
              ),
            );
          }
        }),
      );
}
