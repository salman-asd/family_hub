import 'package:family_hub/core/firebase/base_mapper.dart';
import 'package:family_hub/features/chores/comments/data/comment_mappers.dart';
import 'package:family_hub/features/chores/comments/domain/comment_write_plan.dart';
import 'package:family_hub/features/chores/comments/domain/occurrence_comment.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/rules_source.dart';

void main() {
  final at = DateTime.utc(2026, 10, 24, 9);
  const comment = NewComment(
    id: 'c1',
    occurrenceId: 'tpl_1_20261024',
    text: 'The sink is dirty',
    needsAttention: true,
  );

  test('toMap keys == commentKeys() in firestore.rules', () {
    final map = CommentMappers.toMap(comment, authorId: 'dave', at: at);
    expect(map.keys.toSet(), rulesList('commentKeys'));
    expect(map['hidden'], false);
    expect(map['resolvedAt'], isNull);
    expect(map['createdBy'], 'dave');
  });

  test('a change writes only the keys the rules allow', () {
    final allowed = rulesList('commentKeys');
    for (final kind in CommentChangeKind.values) {
      final map = CommentMappers.changeMap(
        CommentChange(
          commentId: 'c1',
          occurrenceId: 'o',
          kind: kind,
          note: 'Not kind',
        ),
        actorId: 'bob',
        at: at,
      );
      expect(allowed.containsAll(map.keys), isTrue, reason: kind.name);
      expect(map.containsKey('text'), isFalse);
      expect(map.containsKey('authorId'), isFalse);
      expect(map[BaseMapper.keyUpdatedBy], 'bob');
    }
  });

  test('round trip', () {
    final map = CommentMappers.toMap(comment, authorId: 'dave', at: at);
    final read = CommentMappers.fromDoc('tpl_1_20261024', 'c1', map);
    expect(read?.text, 'The sink is dirty');
    expect(read?.authorId, 'dave');
    expect(read?.needsAttention, isTrue);
    expect(read?.createdAt, at);
    expect(read?.isOpenFlag, isTrue);
  });

  test('a malformed document is dropped, never thrown', () {
    expect(CommentMappers.fromDoc('o', 'c', null), isNull);
    expect(CommentMappers.fromDoc('o', 'c', {'authorId': 'a'}), isNull);
    expect(CommentMappers.fromDoc('o', 'c', {'text': 'x'}), isNull);
  });

  test('limits', () {
    expect(CommentLimits.text('  hi ').valueOrNull, 'hi');
    expect(CommentLimits.text('').failureOrNull, isNotNull);
    expect(CommentLimits.note('ab').failureOrNull, isNotNull);
    expect(CommentLimits.note('abc').valueOrNull, 'abc');
  });
}
