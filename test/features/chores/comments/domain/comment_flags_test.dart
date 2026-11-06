import 'package:family_hub/features/chores/comments/domain/comment_flags.dart';
import 'package:family_hub/features/chores/comments/domain/occurrence_comment.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../chores_test_helpers.dart';

void main() {
  final at = DateTime.utc(2026, 10, 24, 9);
  OccurrenceComment c(String id, {bool flag = false, bool hidden = false}) =>
      OccurrenceComment(
        id: id,
        occurrenceId: 'o',
        authorId: 'dave',
        text: 't',
        createdAt: at,
        needsAttention: flag,
        hidden: hidden,
      );

  test('only a visible, unresolved flag is open', () {
    expect(CommentFlags.openCount([c('a'), c('b', flag: true)]), 1);
    expect(CommentFlags.openCount([c('a', flag: true, hidden: true)]), 0);
    final done = c(
      'a',
      flag: true,
    ).after(CommentChangeKind.resolve, by: 'cara', at: at);
    expect(done.isOpenFlag, isFalse);
  });

  test('marker patch only when it would change', () {
    final flagged = anOccurrence(needsAttention: true);
    final clean = anOccurrence();
    expect(CommentFlags.markerPatch(flagged, openAfter: 1), isNull);
    expect(CommentFlags.markerPatch(clean, openAfter: 0), isNull);
    expect(
      CommentFlags.markerPatch(flagged, openAfter: 0)!.fields['needsAttention'],
      false,
    );
    expect(
      CommentFlags.markerPatch(clean, openAfter: 2)!.fields['needsAttention'],
      true,
    );
  });

  test('unread: newer than the local last-seen instant', () {
    expect(CommentFlags.hasUnread(null, null), isFalse);
    expect(CommentFlags.hasUnread(at, null), isTrue);
    expect(CommentFlags.hasUnread(at, at), isFalse);
    expect(
      CommentFlags.hasUnread(at, at.subtract(const Duration(minutes: 1))),
      isTrue,
    );
  });
}
