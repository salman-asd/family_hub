import 'package:family_hub/core/audit/audit_event_type.dart';
import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/features/chores/comments/domain/comment_loader.dart';
import 'package:family_hub/features/chores/comments/domain/occurrence_comment.dart';
import 'package:family_hub/features/chores/comments/domain/usecases/add_comment.dart';
import 'package:family_hub/features/chores/comments/domain/usecases/hide_comment.dart';
import 'package:family_hub/features/chores/comments/domain/usecases/mark_needs_attention.dart';
import 'package:family_hub/features/chores/comments/domain/usecases/resolve_comment.dart';
import 'package:family_hub/features/chores/comments/domain/usecases/unhide_comment.dart';
import 'package:family_hub/features/chores/occurrences/domain/chore_occurrence.dart';
import 'package:family_hub/features/chores/occurrences/domain/occurrence_status.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../chores_test_helpers.dart';
import '../../occurrences/domain/usecases/completion_test_support.dart';

/// P3-25: comments, flags, resolve and moderation.
void main() {
  const familyId = ChoresFixture.familyId;
  const occId = 'tpl_1_20261024';

  late ChoresFixture fixture;
  late CompletionUseCases completion;
  late AddComment add;
  late MarkNeedsAttention flag;
  late ResolveComment resolve;
  late HideComment hide;
  late UnhideComment unhide;

  setUp(() {
    fixture = ChoresFixture();
    completion = CompletionUseCases(fixture);
    final loader = CommentLoader(
      occurrences: fixture.occurrences,
      templates: fixture.chores,
      dutyGroups: fixture.chores.dutyGroups,
      choreSettings: fixture.settings,
      families: fixture.families,
      dateKeys: fixture.dateKeys,
    );
    add = AddComment(
      loader: loader,
      comments: fixture.comments,
      clock: fixture.clock,
      inbox: completion.inbox,
      newId: fixture.ids.call,
    );
    flag = MarkNeedsAttention(add);
    resolve = ResolveComment(
      loader: loader,
      comments: fixture.comments,
      clock: fixture.clock,
      newId: fixture.ids.call,
    );
    hide = HideComment(
      loader: loader,
      comments: fixture.comments,
      clock: fixture.clock,
      newId: fixture.ids.call,
    );
    unhide = UnhideComment(
      loader: loader,
      comments: fixture.comments,
      clock: fixture.clock,
      newId: fixture.ids.call,
    );
    seedOccurrence(fixture, anOccurrence());
  });

  ChoreOccurrence stored() =>
      fixture.occurrences.occurrences[familyId]![occId]!;

  List<OccurrenceComment> thread() => fixture.comments.thread(familyId, occId);

  Future<AppFailure?> say(String uid, String text, {String id = 'c1'}) async =>
      (await add(
        familyId: familyId,
        actorUid: uid,
        occurrenceId: occId,
        commentId: id,
        text: text,
      )).failureOrNull;

  Future<AppFailure?> raise(
    String uid,
    String text, {
    String id = 'f1',
  }) async => (await flag(
    familyId: familyId,
    actorUid: uid,
    occurrenceId: occId,
    commentId: id,
    reason: text,
  )).failureOrNull;

  Future<AppFailure?> answer(String uid, String id) async => (await resolve(
    familyId: familyId,
    actorUid: uid,
    occurrenceId: occId,
    commentId: id,
  )).failureOrNull;

  group('AddComment', () {
    test('a plain member comments on somebody else’s chore', () async {
      expect(await say('dave', '  Looks clean  '), isNull);

      expect(thread().single.text, 'Looks clean');
      expect(thread().single.authorId, 'dave');
      expect(stored().lastCommentAt, fixture.clock.nowUtc());
      expect(stored().needsAttention, isFalse);
      final plan = fixture.comments.plans.single;
      expect(plan.occurrence.patches.single.fields.keys, ['lastCommentAt']);
      expect(
        plan.occurrence.audits.single.type,
        AuditEventType.choresCommentAdded,
      );
      expect(completion.inbox.sent, isEmpty);
    });

    test('text is required and at most 1000 characters', () async {
      expect(await say('dave', '   '), const Validation('text', 'required'));
      expect(
        await say('dave', 'x' * 1001),
        const Validation('text', 'too_long'),
      );
      expect(thread(), isEmpty);
    });

    test('a pending member cannot comment', () async {
      expect(await say('erin', 'hello'), isA<PermissionDenied>());
      expect(thread(), isEmpty);
    });

    test(
      'a failed write leaves nothing behind and a retry reuses the id',
      () async {
        fixture.comments.nextStageFailure = const Network();
        expect(await say('dave', 'hello'), isA<Network>());
        expect(thread(), isEmpty);
        expect(stored().lastCommentAt, isNull);

        expect(await say('dave', 'hello'), isNull);
        expect(await say('dave', 'hello'), isNull);
        expect(thread().length, 1, reason: 'same comment id: one document');
      },
    );

    test('a comment on a finished chore does not change its status', () async {
      seedOccurrence(
        fixture,
        anOccurrence(
          status: OccurrenceStatus.completed,
          completedAt: DateTime.utc(2026, 10, 24, 4),
          completedBy: 'cara',
        ),
      );
      expect(await say('dave', 'nice'), isNull);
      expect(stored().status, OccurrenceStatus.completed);
    });
  });

  group('MarkNeedsAttention', () {
    test('a flag sets the marker and tells the assignee', () async {
      expect(await raise('dave', 'The sink is still dirty'), isNull);

      expect(thread().single.needsAttention, isTrue);
      expect(stored().needsAttention, isTrue);
      expect(stored().lastCommentAt, isNotNull);
      expect(completion.inbox.sent, ['comment_attention -> cara']);
      expect(fixture.comments.plans.single.occurrence.inbox, hasLength(1));
    });

    test('the assignee flagging their own chore sends no inbox row', () async {
      expect(await raise('cara', 'I need help'), isNull);
      expect(stored().needsAttention, isTrue);
      expect(completion.inbox.sent, isEmpty);
    });
  });

  group('ResolveComment', () {
    test('only whoever may act on the chore resolves a flag', () async {
      await raise('dave', 'Dirty');

      expect(
        await answer('dave', 'f1'),
        const Conflict(code: 'not_assigned_to_you'),
      );
      expect(stored().needsAttention, isTrue);

      expect(await answer('cara', 'f1'), isNull);
      expect(thread().single.isResolved, isTrue);
      expect(thread().single.resolvedBy, 'cara');
      expect(stored().needsAttention, isFalse);
    });

    test('the marker clears only with the LAST open flag', () async {
      await raise('dave', 'One', id: 'f1');
      await raise('bob', 'Two', id: 'f2');

      expect(await answer('bob', 'f1'), isNull);
      expect(stored().needsAttention, isTrue);
      expect(await answer('bob', 'f2'), isNull);
      expect(stored().needsAttention, isFalse);
    });

    test(
      'a manager may resolve; a stale or plain comment is a conflict',
      () async {
        await say('dave', 'just a note', id: 'n1');
        await raise('dave', 'Dirty');

        expect(
          await answer('alice', 'n1'),
          const Conflict(code: 'concurrent_edit'),
        );
        expect(await answer('alice', 'f1'), isNull);
        expect(
          await answer('alice', 'f1'),
          const Conflict(code: 'concurrent_edit'),
        );
        expect(
          await answer('alice', 'nope'),
          const NotFound(entity: 'comment'),
        );
      },
    );
  });

  group('HideComment / UnhideComment', () {
    Future<AppFailure?> hideAs(String uid, String id, String note) async =>
        (await hide(
          familyId: familyId,
          actorUid: uid,
          occurrenceId: occId,
          commentId: id,
          note: note,
        )).failureOrNull;

    Future<AppFailure?> showAs(String uid, String id, String note) async =>
        (await unhide(
          familyId: familyId,
          actorUid: uid,
          occurrenceId: occId,
          commentId: id,
          note: note,
        )).failureOrNull;

    test(
      'a member cannot hide; a manager needs a note of 3 characters',
      () async {
        await say('dave', 'rude words');

        expect(await hideAs('cara', 'c1', 'because'), isA<PermissionDenied>());
        expect(
          await hideAs('bob', 'c1', 'no'),
          const Validation('note', 'reason_required'),
        );
        expect(thread().single.hidden, isFalse);

        expect(await hideAs('bob', 'c1', 'Not kind'), isNull);
        expect(thread().single.hidden, isTrue);
        expect(thread().single.hiddenBy, 'bob');
        expect(thread().single.hiddenNote, 'Not kind');
        expect(thread().single.text, 'rude words', reason: 'never deleted');
        final audit = fixture.comments.plans.last.occurrence.audits.single;
        expect(audit.type, AuditEventType.choresCommentHidden);
        expect(audit.params['reason'], 'Not kind');
      },
    );

    test(
      'hiding the last open flag clears the marker; showing it sets it',
      () async {
        await raise('dave', 'Dirty');
        expect(stored().needsAttention, isTrue);

        expect(await hideAs('alice', 'f1', 'Wrong chore'), isNull);
        expect(stored().needsAttention, isFalse);

        expect(await showAs('alice', 'f1', 'It was right'), isNull);
        expect(thread().single.hidden, isFalse);
        expect(thread().single.hiddenBy, isNull);
        expect(stored().needsAttention, isTrue);
        expect(
          fixture.comments.plans.last.occurrence.audits.single.type,
          AuditEventType.choresCommentUnhidden,
        );
      },
    );

    test('hiding twice or unhiding a visible comment is a conflict', () async {
      await say('dave', 'hi');
      expect(
        await showAs('bob', 'c1', 'oops'),
        const Conflict(code: 'concurrent_edit'),
      );
      expect(await hideAs('bob', 'c1', 'reason'), isNull);
      expect(
        await hideAs('bob', 'c1', 'again'),
        const Conflict(code: 'concurrent_edit'),
      );
    });
  });

  group('survival', () {
    test('comments survive a reopen and a reassignment', () async {
      seedOccurrence(
        fixture,
        anOccurrence(
          status: OccurrenceStatus.completed,
          completedAt: DateTime.utc(2026, 10, 24, 4),
          completedBy: 'cara',
        ),
      );
      await raise('dave', 'Missed a spot');

      final reopened = await completion.reopen(
        familyId: familyId,
        actorUid: 'dave',
        occurrenceId: occId,
        reason: 'Missed a spot',
      );
      expect(reopened.failureOrNull, isNull);
      final moved = await completion.reassign(
        familyId: familyId,
        actorUid: 'bob',
        occurrenceId: occId,
        toMemberId: 'dave',
        reason: 'Dave can do it',
      );
      expect(moved.failureOrNull, isNull);

      expect(thread().single.text, 'Missed a spot');
      expect(stored().needsAttention, isTrue, reason: 'reopen keeps the flag');
    });
  });
}
