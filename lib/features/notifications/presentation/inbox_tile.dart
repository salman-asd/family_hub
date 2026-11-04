import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/features/notifications/domain/inbox_item.dart';
import 'package:family_hub/features/notifications/domain/inbox_port.dart';
import 'package:flutter/material.dart';

/// One row of the inbox (P3-27): icon, sentence, an unread marker that is a dot
/// AND bold text AND a semantic label (never colour alone), 48dp tall at least.
class InboxTile extends StatelessWidget {
  const InboxTile({
    required this.item,
    required this.text,
    required this.onTap,
    super.key,
  });

  final InboxItem item;
  final String text;
  final VoidCallback onTap;

  static IconData iconOf(String type) => switch (type) {
    InboxType.swapRequest => Icons.swap_horiz_rounded,
    InboxType.swapResult => Icons.handshake_outlined,
    InboxType.needsCover => Icons.person_search_outlined,
    InboxType.choreReopened => Icons.refresh_rounded,
    InboxType.commentAttention => Icons.flag_outlined,
    InboxType.verificationNeeded => Icons.fact_check_outlined,
    InboxType.absenceDecision => Icons.event_available_outlined,
    _ => Icons.notifications_none_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final unread = item.isUnread;
    return Semantics(
      container: true,
      button: true,
      label: unread ? '${context.l10n.inboxUnreadSemantics}: $text' : text,
      excludeSemantics: true,
      onTap: onTap,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(iconOf(item.type), color: t.textSecondary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    text,
                    style: TextStyle(
                      color: t.textPrimary,
                      fontSize: 14,
                      fontWeight: unread ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                ),
                if (unread) ...[
                  const SizedBox(width: 8),
                  Container(
                    key: const Key('inbox_unread_dot'),
                    width: 10,
                    height: 10,
                    margin: const EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(
                      color: t.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
