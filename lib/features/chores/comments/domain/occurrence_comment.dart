import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/errors/result.dart';

/// Limits of a comment (road map 3.2; mirrored by the P3-25 rules).
abstract final class CommentLimits {
  static const int maxText = 1000;
  static const int minNote = 3;
  static const int maxNote = 200;

  /// A trimmed comment body, or `Validation('text', ...)`.
  static Result<String> text(String? raw) {
    final body = raw?.trim() ?? '';
    if (body.isEmpty) {
      return const Failure<String>(Validation('text', 'required'));
    }
    if (body.length > maxText) {
      return const Failure<String>(Validation('text', 'too_long'));
    }
    return Success<String>(body);
  }

  /// A trimmed moderation note (3-200 characters), or a `Validation`.
  static Result<String> note(String? raw) {
    final note = raw?.trim() ?? '';
    if (note.length < minNote) {
      return const Failure<String>(Validation('note', 'reason_required'));
    }
    if (note.length > maxNote) {
      return const Failure<String>(Validation('note', 'too_long'));
    }
    return Success<String>(note);
  }
}

/// One comment of a chore (`choreOccurrences/{id}/comments/{commentId}`).
///
/// A comment belongs to the OCCURRENCE, so it survives a reopen, a reassign and
/// a swap. It is never deleted (D-P3-18): a manager may HIDE it with a note.
/// The text and the author never change after the first write.
final class OccurrenceComment {
  const OccurrenceComment({
    required this.id,
    required this.occurrenceId,
    required this.authorId,
    required this.text,
    required this.createdAt,
    this.needsAttention = false,
    this.resolvedAt,
    this.resolvedBy,
    this.hidden = false,
    this.hiddenBy,
    this.hiddenNote,
  });

  final String id;
  final String occurrenceId;
  final String authorId;
  final String text;
  final DateTime createdAt;

  /// A FLAG: the author says the chore is incorrect or incomplete.
  final bool needsAttention;
  final DateTime? resolvedAt;
  final String? resolvedBy;
  final bool hidden;
  final String? hiddenBy;
  final String? hiddenNote;

  bool get isResolved => resolvedAt != null;

  /// A flag nobody has answered yet and no manager has hidden.
  bool get isOpenFlag => needsAttention && !isResolved && !hidden;

  /// Whether [change] still makes sense for this comment (a stale screen must
  /// not resolve a resolved flag or hide a hidden comment twice).
  bool accepts(CommentChangeKind kind) => switch (kind) {
    CommentChangeKind.resolve => needsAttention && !isResolved && !hidden,
    CommentChangeKind.hide => !hidden,
    CommentChangeKind.unhide => hidden,
  };

  /// This comment after [change] (the state a use case answers with).
  OccurrenceComment after(
    CommentChangeKind kind, {
    required String by,
    required DateTime at,
    String? note,
  }) => switch (kind) {
    CommentChangeKind.resolve => _copy(resolvedAt: at, resolvedBy: by),
    CommentChangeKind.hide => _copy(
      hidden: true,
      hiddenBy: by,
      hiddenNote: note,
    ),
    CommentChangeKind.unhide => _copy(hidden: false),
  };

  OccurrenceComment _copy({
    DateTime? resolvedAt,
    String? resolvedBy,
    bool? hidden,
    String? hiddenBy,
    String? hiddenNote,
  }) {
    final nowHidden = hidden ?? this.hidden;
    return OccurrenceComment(
      id: id,
      occurrenceId: occurrenceId,
      authorId: authorId,
      text: text,
      createdAt: createdAt,
      needsAttention: needsAttention,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      resolvedBy: resolvedBy ?? this.resolvedBy,
      hidden: nowHidden,
      hiddenBy: nowHidden ? (hiddenBy ?? this.hiddenBy) : null,
      hiddenNote: nowHidden ? (hiddenNote ?? this.hiddenNote) : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is OccurrenceComment &&
      other.id == id &&
      other.occurrenceId == occurrenceId &&
      other.authorId == authorId &&
      other.text == text &&
      other.createdAt == createdAt &&
      other.needsAttention == needsAttention &&
      other.resolvedAt == resolvedAt &&
      other.resolvedBy == resolvedBy &&
      other.hidden == hidden &&
      other.hiddenBy == hiddenBy &&
      other.hiddenNote == hiddenNote;

  @override
  int get hashCode => Object.hash(
    id,
    occurrenceId,
    authorId,
    text,
    createdAt,
    needsAttention,
    resolvedAt,
    resolvedBy,
    hidden,
    hiddenBy,
    hiddenNote,
  );

  @override
  String toString() => 'OccurrenceComment($id on $occurrenceId by $authorId)';
}

/// What a later write may do to an existing comment (never edit the text).
enum CommentChangeKind { resolve, hide, unhide }
