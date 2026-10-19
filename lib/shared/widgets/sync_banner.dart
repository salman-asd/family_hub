import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:flutter/material.dart';

/// Slim banner that tells the user their changes are waiting to sync.
///
/// Takes plain values (no Firebase): [pendingWrites] changes are queued;
/// [offline] is true once they have been waiting longer than the grace period.
/// Status is never conveyed by colour alone: icon + text + colour.
/// Renders nothing when [pendingWrites] is 0.
class SyncBanner extends StatelessWidget {
  const SyncBanner({
    required this.pendingWrites,
    this.offline = false,
    super.key,
  });

  final int pendingWrites;
  final bool offline;

  @override
  Widget build(BuildContext context) {
    if (pendingWrites <= 0) return const SizedBox.shrink();
    final t = context.tokens;
    final l10n = context.l10n;
    final text = offline
        ? l10n.syncBannerOffline(pendingWrites)
        : l10n.syncBannerSyncing(pendingWrites);
    final foreground = t.statusInProgressOn;

    return Semantics(
      container: true,
      liveRegion: true,
      label: text,
      excludeSemantics: true,
      child: Container(
        key: const Key('sync_banner'),
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 36),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        color: t.statusInProgressContainer,
        child: Row(
          children: [
            Icon(
              offline ? Icons.cloud_off_rounded : Icons.sync_rounded,
              size: 18,
              color: foreground,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  color: foreground,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
