import 'dart:async';

import 'package:family_hub/app/routing/app_routes.dart';
import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:family_hub/core/audit/audit_ref_type.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/features/chores/swaps/presentation/swap_providers.dart';
import 'package:family_hub/features/chores/swaps/presentation/swap_response_sheet.dart';
import 'package:family_hub/features/family/presentation/family_providers.dart';
import 'package:family_hub/features/notifications/domain/inbox_item.dart';
import 'package:family_hub/features/notifications/presentation/inbox_providers.dart';
import 'package:family_hub/features/notifications/presentation/inbox_text.dart';
import 'package:family_hub/features/notifications/presentation/inbox_tile.dart';
import 'package:family_hub/modules/module_providers.dart';
import 'package:family_hub/shared/widgets/empty_state.dart';
import 'package:family_hub/shared/widgets/error_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// The member's inbox (P3-27): grouped Today / Earlier, an unread dot, tap =
/// mark read + open what it is about. Items of a module that is switched off
/// are hidden. One info row explains the Spark limit (D-P3-19): a request shows
/// up when the app is opened.
class InboxScreen extends ConsumerWidget {
  const InboxScreen({super.key});

  Future<void> _open(BuildContext context, WidgetRef ref, InboxItem item) async {
    final familyId = ref.read(currentFamilyIdProvider);
    final uid = ref.read(currentUidProvider);
    if (item.isUnread && familyId != null && uid != null) {
      unawaited(
        ref.read(markInboxReadProvider)(
          familyId: familyId,
          actorUid: uid,
          ids: <String>[item.id],
        ),
      );
    }
    switch (item.refType) {
      case AuditRefType.swapRequest:
        final pending = ref.read(pendingSwapsProvider).value ?? const [];
        for (final request in pending) {
          if (request.id == item.refId && request.toMemberId == uid) {
            await ref.respondToSwapWithSheet(context, request);
            return;
          }
        }
      case AuditRefType.availability:
        if (context.mounted) unawaited(context.push(AppRoutes.choresAvailability));
      case AuditRefType.occurrence:
        if (context.mounted) {
          unawaited(context.push(AppRoutes.choresOccurrence(item.refId)));
        }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final t = context.tokens;
    final formatters = ref.watch(appFormattersProvider);
    final inbox = ref.watch(inboxProvider);
    final members = ref.watch(membersProvider).value ?? const [];
    final choresOn = ref
        .watch(enabledModulesProvider)
        .any((module) => module.id == 'chores');
    final today = ref.watch(familyDateKeysProvider);
    final now = today.today();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.inboxTitle),
        actions: [
          IconButton(
            key: const Key('inbox_mark_all'),
            tooltip: l10n.inboxMarkAllRead,
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            icon: const Icon(Icons.done_all_rounded),
            onPressed: () {
              final familyId = ref.read(currentFamilyIdProvider);
              final uid = ref.read(currentUidProvider);
              final unread = <String>[
                for (final i in inbox.value ?? const <InboxItem>[])
                  if (i.isUnread) i.id,
              ];
              if (familyId == null || uid == null || unread.isEmpty) return;
              unawaited(
                ref.read(markInboxReadProvider)(
                  familyId: familyId,
                  actorUid: uid,
                  ids: unread,
                ),
              );
            },
          ),
        ],
      ),
      body: inbox.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => ErrorView(
          message: l10n.choresFailure_unknown,
          onRetry: () => ref.invalidate(inboxProvider),
        ),
        data: (all) {
          final items = choresOn ? all : const <InboxItem>[];
          final todays = <InboxItem>[];
          final earlier = <InboxItem>[];
          for (final item in items) {
            (today.dateKeyOf(item.createdAt) == now ? todays : earlier).add(item);
          }
          return ListView(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded, size: 18, color: t.textSecondary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.inboxSparkNote,
                        style: TextStyle(color: t.textSecondary, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              if (items.isEmpty)
                EmptyState(
                  icon: Icons.notifications_none_rounded,
                  title: l10n.inboxEmpty,
                ),
              for (final group in <(String, List<InboxItem>)>[
                (l10n.inboxToday, todays),
                (l10n.inboxEarlier, earlier),
              ])
                if (group.$2.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: Text(
                      group.$1,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: t.textSecondary,
                      ),
                    ),
                  ),
                  for (final item in group.$2)
                    InboxTile(
                      item: item,
                      text: inboxTextOf(l10n, formatters, item, members),
                      onTap: () => unawaited(_open(context, ref, item)),
                    ),
                ],
            ],
          );
        },
      ),
    );
  }
}
