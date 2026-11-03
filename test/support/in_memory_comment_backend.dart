import 'dart:async';

import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/features/chores/comments/domain/comment_repository.dart';
import 'package:family_hub/features/chores/comments/domain/comment_write_plan.dart';
import 'package:family_hub/features/chores/comments/domain/occurrence_comment.dart';

import 'in_memory_chores_backend.dart';

/// In-memory [CommentRepository] (P3-25).
///
/// Like the real one it stages the occurrence part of a plan FIRST (through the
/// occurrence backend, so `lastCommentAt` / `needsAttention` change together
/// with the comment), then applies the comment documents.
class InMemoryCommentBackend implements CommentRepository {
  InMemoryCommentBackend(this._occurrences);

  final InMemoryOccurrenceBackend _occurrences;

  /// `familyId -> occurrenceId -> thread (oldest first)`.
  final Map<String, Map<String, List<OccurrenceComment>>> threads = {};

  /// Every plan that reached [stage].
  final List<CommentWritePlan> plans = <CommentWritePlan>[];

  /// Set to make the next write fail (then cleared).
  AppFailure? nextStageFailure;

  /// Live [watchComments] subscriptions right now.
  int activeListeners = 0;

  final StreamController<void> _changes = StreamController<void>.broadcast();

  List<OccurrenceComment> thread(String familyId, String occurrenceId) =>
      threads[familyId]?[occurrenceId] ?? const <OccurrenceComment>[];

  @override
  Stream<List<OccurrenceComment>> watchComments(
    String familyId,
    String occurrenceId,
  ) async* {
    activeListeners++;
    try {
      yield thread(familyId, occurrenceId);
      await for (final _ in _changes.stream) {
        yield thread(familyId, occurrenceId);
      }
    } finally {
      activeListeners--;
    }
  }

  @override
  Future<Result<List<OccurrenceComment>>> list(
    String familyId,
    String occurrenceId,
  ) async => Success<List<OccurrenceComment>>(thread(familyId, occurrenceId));

  @override
  Future<Result<void>> stage(String familyId, CommentWritePlan plan) async {
    final failure = nextStageFailure;
    if (failure != null) {
      nextStageFailure = null;
      return Failure<void>(failure);
    }
    final staged = await _occurrences.stage(familyId, plan.occurrence);
    final stagedFailure = staged.failureOrNull;
    if (stagedFailure != null) return Failure<void>(stagedFailure);

    final family = threads.putIfAbsent(
      familyId,
      () => <String, List<OccurrenceComment>>{},
    );
    for (final comment in plan.comments) {
      final list = family.putIfAbsent(
        comment.occurrenceId,
        () => <OccurrenceComment>[],
      );
      list.removeWhere((c) => c.id == comment.id);
      list.add(
        OccurrenceComment(
          id: comment.id,
          occurrenceId: comment.occurrenceId,
          authorId: plan.actorId,
          text: comment.text,
          createdAt: plan.at,
          needsAttention: comment.needsAttention,
        ),
      );
    }
    for (final change in plan.changes) {
      final list = family[change.occurrenceId];
      final index = list?.indexWhere((c) => c.id == change.commentId) ?? -1;
      if (list == null || index < 0) continue;
      list[index] = list[index].after(
        change.kind,
        by: plan.actorId,
        at: plan.at,
        note: change.note,
      );
    }
    plans.add(plan);
    _changes.add(null);
    return const Success<void>(null);
  }
}
