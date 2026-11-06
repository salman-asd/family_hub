import 'dart:async';

import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/core/firebase/query_limits.dart';
import 'package:family_hub/core/localization/app_formatters.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/core/permissions/permissions.dart';
import 'package:family_hub/core/utils/id_generator.dart';
import 'package:family_hub/features/chores/comments/domain/occurrence_comment.dart';
import 'package:family_hub/features/chores/comments/presentation/comment_providers.dart';
import 'package:family_hub/features/chores/comments/presentation/widgets/comment_bubble.dart';
import 'package:family_hub/features/chores/comments/presentation/widgets/comment_composer.dart';
import 'package:family_hub/features/chores/occurrences/domain/chore_item.dart';
import 'package:family_hub/features/chores/occurrences/domain/chore_occurrence.dart';
import 'package:family_hub/features/chores/occurrences/domain/occurrence_status.dart';
import 'package:family_hub/features/chores/presentation/chores_failure_messages.dart';
import 'package:family_hub/features/chores/presentation/occurrence_action_sheets.dart';
import 'package:family_hub/features/family/presentation/family_providers.dart';
import 'package:family_hub/features/family/presentation/permission_providers.dart';
import 'package:family_hub/shared/widgets/error_view.dart';
import 'package:family_hub/shared/widgets/reason_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The comment thread under a chore (P3-25).
///
/// Everything it shows comes from [commentsProvider] (ONE listener) and every
/// button runs a use case; the actions a viewer may not take are simply not
/// offered. Opening the thread marks it read on this device.
class CommentsSection extends ConsumerStatefulWidget {
  const CommentsSection({
    required this.occurrence,
    required this.item,
    required this.formatters,
    super.key,
  });

  final ChoreOccurrence occurrence;
  final ChoreItem item;
  final AppFormatters formatters;

  @override
  ConsumerState<CommentsSection> createState() => _CommentsSectionState();
}

class _CommentsSectionState extends ConsumerState<CommentsSection> {
  /// Generated ONCE per intent: a retry after a failure reuses it.
  String _commentId = randomId();
  int _newOnOpen = 0;
  bool _opened = false;

  String get _id => widget.occurrence.id;

  @override
  void initState() {
    super.initState();
    ref.listenManual(commentsProvider(_id), (previous, next) {
      final thread = next.value;
      if (thread == null || _opened) return;
      _opened = true;
      setState(() => _newOnOpen = ref.read(unreadCommentsProvider(_id)));
      final last = thread.isEmpty ? null : thread.last.createdAt;
      if (last != null) unawaited(markCommentsSeen(ref, _id, last));
    }, fireImmediately: true);
  }

  void _show(AppFailure failure) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.choresFailureMessage(failure))),
    );
  }

  /// Runs [call]; true when it worked, the failure is shown otherwise.
  Future<bool> _run(
    Future<Result<Object?>> Function(String familyId, String uid) call,
  ) async {
    final familyId = ref.read(currentFamilyIdProvider);
    final uid = ref.read(currentUidProvider);
    if (familyId == null || uid == null) return false;
    final result = await call(familyId, uid);
    final failure = result.failureOrNull;
    if (failure != null) {
      _show(failure);
      return false;
    }
    return true;
  }

  Future<bool> _submit(String text, bool flagged) async {
    DateTime? at;
    final done = await _run((familyId, uid) async {
      final Result<OccurrenceComment> result = flagged
          ? await ref.read(markNeedsAttentionProvider)(
              familyId: familyId,
              actorUid: uid,
              occurrenceId: _id,
              commentId: _commentId,
              reason: text,
            )
          : await ref.read(addCommentProvider)(
              familyId: familyId,
              actorUid: uid,
              occurrenceId: _id,
              commentId: _commentId,
              text: text,
            );
      at = result.valueOrNull?.createdAt;
      return result;
    });
    if (done) {
      _commentId = randomId();
      final seen = at;
      if (seen != null) unawaited(markCommentsSeen(ref, _id, seen));
    }
    return done;
  }

  Future<void> _resolve(OccurrenceComment c) => _run(
    (familyId, uid) => ref.read(resolveCommentProvider)(
      familyId: familyId,
      actorUid: uid,
      occurrenceId: _id,
      commentId: c.id,
    ),
  );

  Future<void> _reopen(OccurrenceComment c) async {
    final result = await ref.reopenWithSheet(
      context,
      occurrenceId: _id,
      initialReason: c.text,
    );
    final failure = result?.failureOrNull;
    if (failure != null) _show(failure);
  }

  Future<void> _moderate(OccurrenceComment c, {required bool hide}) async {
    final l10n = context.l10n;
    final note = await showReasonSheet(
      context,
      title: hide ? l10n.commentHideTitle : l10n.commentUnhideTitle,
      hint: l10n.commentHideHint,
      maxLength: CommentLimits.maxNote,
    );
    if (note == null) return;
    await _run(
      (familyId, uid) => hide
          ? ref.read(hideCommentProvider)(
              familyId: familyId,
              actorUid: uid,
              occurrenceId: _id,
              commentId: c.id,
              note: note,
            )
          : ref.read(unhideCommentProvider)(
              familyId: familyId,
              actorUid: uid,
              occurrenceId: _id,
              commentId: c.id,
              note: note,
            ),
    );
  }

  String _name(String uid) {
    for (final member in ref.read(membersProvider).value ?? const []) {
      if (member.uid == uid) return member.displayName;
    }
    return uid;
  }

  String _time(DateTime at) {
    final local = at.toLocal();
    return '${widget.formatters.fullDate(local)} '
        '${widget.formatters.timeOfDay(local.hour * 60 + local.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final t = context.tokens;
    final thread = ref.watch(commentsProvider(_id));
    final uid = ref.watch(currentUidProvider);
    ref.watch(membersProvider);
    final canComment = ref.can(Permission.commentOnChore);
    final canModerate = ref.can(Permission.moderateChoreComments);
    final isAssignee = uid != null && widget.occurrence.assigneeId == uid;
    final canResolve = isAssignee || ref.can(Permission.completeChoreForOthers);
    final finished =
        widget.item.status == ChoreStatus.completed ||
        widget.item.status == ChoreStatus.verified;
    final canReopen =
        widget.item.status == ChoreStatus.completed ||
        (widget.item.status == ChoreStatus.verified &&
            ref.can(Permission.manageChoreOccurrences));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.commentsTitle,
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(color: t.textPrimary),
              ),
            ),
            if (_newOnOpen > 0)
              Text(
                l10n.commentsNew(widget.formatters.number(_newOnOpen)),
                style: TextStyle(
                  color: t.accentStrong,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        switch (thread) {
          AsyncError() when thread.value == null => SizedBox(
            height: 160,
            child: ErrorView(
              message: l10n.choresFailure_unknown,
              onRetry: () => ref.invalidate(commentsProvider(_id)),
            ),
          ),
          AsyncData(:final value) when value.isEmpty => Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              l10n.commentsEmpty,
              style: TextStyle(color: t.textSecondary),
            ),
          ),
          AsyncData(:final value) => Column(
            children: [
              for (final c in value)
                CommentBubble(
                  comment: c,
                  authorName: _name(c.authorId),
                  timeLabel: _time(c.createdAt),
                  mine: c.authorId == uid,
                  canModerate: canModerate,
                  onResolve: c.isOpenFlag && canResolve && canComment
                      ? () => unawaited(_resolve(c))
                      : null,
                  onReopen: c.isOpenFlag && finished && canReopen
                      ? () => unawaited(_reopen(c))
                      : null,
                  onHide: canModerate && !c.hidden
                      ? () => unawaited(_moderate(c, hide: true))
                      : null,
                  onUnhide: canModerate && c.hidden
                      ? () => unawaited(_moderate(c, hide: false))
                      : null,
                ),
              if (value.length >= kMaxCommentsPerOccurrence)
                Text(
                  l10n.commentsLimitReached,
                  style: TextStyle(color: t.textSecondary, fontSize: 12),
                ),
            ],
          ),
          _ => const SizedBox(
            height: 48,
            child: Center(child: CircularProgressIndicator()),
          ),
        },
        if (canComment) ...[
          const SizedBox(height: 8),
          CommentComposer(onSubmit: _submit),
        ],
      ],
    );
  }
}
