import 'dart:async';

import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/features/chores/presentation/chores_failure_messages.dart';
import 'package:family_hub/features/chores/presentation/member_names.dart';
import 'package:family_hub/features/chores/swaps/domain/swap_request.dart';
import 'package:family_hub/features/chores/swaps/presentation/swap_providers.dart';
import 'package:family_hub/features/chores/swaps/presentation/swap_response_sheet.dart';
import 'package:family_hub/features/family/presentation/family_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The pending request of one chore, on the detail screen (P3-27):
/// "Request sent to Dave" with Cancel for the person who asked, and the
/// Accept / Decline sheet for the person who was asked. Nothing is shown when
/// the chore has no pending request.
class SwapStatusBanner extends ConsumerWidget {
  const SwapStatusBanner({required this.occurrenceId, super.key});

  final String occurrenceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final t = context.tokens;
    final uid = ref.watch(currentUidProvider);
    final members = ref.watch(membersProvider).value ?? const [];
    final pending = ref.watch(pendingSwapsProvider).value ?? const <SwapRequest>[];
    SwapRequest? request;
    for (final r in pending) {
      if (r.occurrenceId == occurrenceId) request = r;
    }
    if (request == null) return const SizedBox.shrink();
    final shown = request;

    final mine = shown.requestedBy == uid || shown.fromMemberId == uid;
    final forMe = shown.toMemberId == uid;
    final text = forMe
        ? l10n.swapBannerForYou(
            memberNameOf(members, shown.fromMemberId, fallback: l10n.inboxSomeone),
          )
        : l10n.swapBannerSent(
            memberNameOf(members, shown.toMemberId, fallback: l10n.inboxSomeone),
          );

    return Container(
      key: const Key('swap_banner'),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: t.surfaceRaised,
        borderRadius: BorderRadius.circular(t.radiusMd),
        border: Border.all(color: t.outline),
      ),
      child: Row(
        children: [
          Icon(Icons.swap_horiz_rounded, color: t.textSecondary),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
          if (forMe)
            TextButton(
              key: const Key('swap_banner_answer'),
              style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
              onPressed: () => unawaited(ref.respondToSwapWithSheet(context, shown)),
              child: Text(l10n.swapResponseTitle),
            )
          else if (mine)
            TextButton(
              key: const Key('swap_banner_cancel'),
              style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
              onPressed: () async {
                final familyId = ref.read(currentFamilyIdProvider);
                if (familyId == null || uid == null) return;
                final result = await ref.read(cancelSwapProvider)(
                  familyId: familyId,
                  actorUid: uid,
                  requestId: shown.id,
                );
                final failure = result.failureOrNull;
                if (failure != null && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.choresFailureMessage(failure))),
                  );
                }
              },
              child: Text(l10n.swapBannerCancel),
            ),
        ],
      ),
    );
  }
}
