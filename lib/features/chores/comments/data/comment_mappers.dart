import 'package:family_hub/core/firebase/base_mapper.dart';
import 'package:family_hub/features/chores/comments/domain/comment_write_plan.dart';
import 'package:family_hub/features/chores/comments/domain/occurrence_comment.dart';

/// Pure functions between [OccurrenceComment] and
/// `choreOccurrences/{id}/comments/{commentId}`.
///
/// [toMap] is the closed key set of the P3-25 rules (`commentKeys`), mirrored
/// by `test/contract/rules_key_sets_test.dart` and the contract fixture.
abstract final class CommentMappers {
  static Map<String, dynamic> toMap(
    NewComment comment, {
    required String authorId,
    required DateTime at,
  }) => <String, dynamic>{
    'authorId': authorId,
    'text': comment.text,
    'needsAttention': comment.needsAttention,
    'resolvedAt': null,
    'resolvedBy': null,
    'hidden': false,
    'hiddenBy': null,
    'hiddenNote': null,
    ...BaseMapper.metadataToMap(
      BaseDocumentMetadata(
        createdAt: at,
        createdBy: authorId,
        updatedAt: at,
        updatedBy: authorId,
      ),
    ),
  };

  /// ONLY the keys a later change may touch (the rules allow no others).
  static Map<String, dynamic> changeMap(
    CommentChange change, {
    required String actorId,
    required DateTime at,
  }) => <String, dynamic>{
    ...switch (change.kind) {
      CommentChangeKind.resolve => <String, dynamic>{
        'resolvedAt': BaseMapper.dateTimeToTimestamp(at),
        'resolvedBy': actorId,
      },
      CommentChangeKind.hide => <String, dynamic>{
        'hidden': true,
        'hiddenBy': actorId,
        'hiddenNote': change.note,
      },
      CommentChangeKind.unhide => <String, dynamic>{
        'hidden': false,
        'hiddenBy': null,
        'hiddenNote': null,
      },
    },
    BaseMapper.keyUpdatedAt: BaseMapper.dateTimeToTimestamp(at),
    BaseMapper.keyUpdatedBy: actorId,
  };

  /// Reads one document; null when it is missing or unreadable.
  static OccurrenceComment? fromDoc(
    String occurrenceId,
    String id,
    Map<String, dynamic>? map,
  ) {
    if (map == null) return null;
    final author = map['authorId'];
    final text = map['text'];
    if (author is! String || author.isEmpty) return null;
    if (text is! String || text.isEmpty) return null;
    return OccurrenceComment(
      id: id,
      occurrenceId: occurrenceId,
      authorId: author,
      text: text.length > CommentLimits.maxText
          ? text.substring(0, CommentLimits.maxText)
          : text,
      createdAt:
          BaseMapper.timestampToDateTime(map[BaseMapper.keyCreatedAt]) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      needsAttention: map['needsAttention'] == true,
      resolvedAt: BaseMapper.timestampToDateTime(map['resolvedAt']),
      resolvedBy: _string(map['resolvedBy']),
      hidden: map['hidden'] == true,
      hiddenBy: _string(map['hiddenBy']),
      hiddenNote: _string(map['hiddenNote']),
    );
  }

  static String? _string(Object? value) =>
      value is String && value.isNotEmpty ? value : null;
}
