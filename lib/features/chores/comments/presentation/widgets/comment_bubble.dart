import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/features/chores/comments/domain/occurrence_comment.dart';
import 'package:family_hub/shared/widgets/app_avatar.dart';
import 'package:flutter/material.dart';

/// One comment of a chore (P3-25).
///
/// A plain widget: the section hands it the names, the time label and ONLY the
/// actions that can work for this viewer, so a button never appears and then
/// fails. A flag shows icon + label (never colour alone); a hidden comment says
/// "hidden by a manager" to everyone and keeps the original text for managers.
class CommentBubble extends StatelessWidget {
  const CommentBubble({
    required this.comment,
    required this.authorName,
    required this.timeLabel,
    required this.mine,
    required this.canModerate,
    this.onResolve,
    this.onReopen,
    this.onHide,
    this.onUnhide,
    super.key,
  });

  final OccurrenceComment comment;
  final String authorName;
  final String timeLabel;
  final bool mine;

  /// A manager sees the text of a hidden comment and its note.
  final bool canModerate;
  final VoidCallback? onResolve;
  final VoidCallback? onReopen;
  final VoidCallback? onHide;
  final VoidCallback? onUnhide;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l10n = context.l10n;
    final showText = !comment.hidden || canModerate;
    final body = showText ? comment.text : l10n.commentHiddenByManager;
    final flagLabel = comment.isResolved
        ? l10n.commentResolved
        : (comment.needsAttention ? l10n.commentFlagged : null);
    final spoken = <String>[
      l10n.commentBubbleLabel(authorName, timeLabel, body),
      ?flagLabel,
      if (comment.hidden && canModerate) l10n.commentHiddenByManager,
    ].join(', ');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppAvatar(
            id: comment.authorId,
            name: authorName,
            size: 32,
            semanticLabel: authorName,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: comment.isOpenFlag ? t.statusOverdueContainer : t.surface,
                borderRadius: BorderRadius.circular(t.radiusMd),
                border: Border.all(
                  color: comment.isOpenFlag ? t.statusOverdue : t.divider,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      container: true,
                      label: spoken,
                      excludeSemantics: true,
                      child: _text(context, body, flagLabel, showText),
                    ),
                    _actions(context),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _text(BuildContext context, String body, String? flag, bool real) {
    final t = context.tokens;
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              mine ? l10n.commentYou : authorName,
              style: TextStyle(
                color: t.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            Text(
              timeLabel,
              style: TextStyle(color: t.textSecondary, fontSize: 12),
            ),
          ],
        ),
        if (flag != null) ...[
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                comment.isResolved
                    ? Icons.check_circle_outline_rounded
                    : Icons.flag_outlined,
                size: 14,
                color: comment.isResolved ? t.success : t.statusOverdue,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  flag,
                  style: TextStyle(
                    color: t.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 6),
        if (comment.hidden)
          Row(
            children: [
              Icon(Icons.visibility_off_outlined, size: 14, color: t.textSecondary),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  l10n.commentHiddenByManager,
                  style: TextStyle(color: t.textSecondary, fontSize: 12),
                ),
              ),
            ],
          ),
        if (real)
          Text(body, style: TextStyle(color: t.textPrimary, fontSize: 14)),
        if (comment.hidden && real && comment.hiddenNote != null) ...[
          const SizedBox(height: 4),
          Text(
            comment.hiddenNote!,
            style: TextStyle(color: t.textSecondary, fontSize: 12),
          ),
        ],
      ],
    );
  }

  Widget _actions(BuildContext context) {
    final l10n = context.l10n;
    final buttons = <Widget>[
      if (onResolve != null)
        _button(l10n.commentResolve, Icons.check_rounded, onResolve!),
      if (onReopen != null)
        _button(l10n.commentReopenWithReason, Icons.refresh_rounded, onReopen!),
      if (onHide != null)
        _button(l10n.commentHide, Icons.visibility_off_outlined, onHide!),
      if (onUnhide != null)
        _button(l10n.commentUnhide, Icons.visibility_outlined, onUnhide!),
    ];
    if (buttons.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Wrap(spacing: 4, runSpacing: 4, children: buttons),
    );
  }

  Widget _button(String label, IconData icon, VoidCallback onPressed) =>
      TextButton.icon(
        style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label),
      );
}
