import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:family_hub/core/localization/generated/app_localizations.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:flutter/material.dart';

/// A small state flag on a chore (road map 3.7, P3-04): icon + label + tone,
/// never colour alone.
///
/// Flags are things that are TRUE about an occurrence on top of its status:
/// nobody is assigned yet, the work is finished but not verified, a comment
/// asks for attention, the occurrence is only projected (not written yet), or
/// a swap request is open. They stack next to the [StatusChip], which keeps
/// carrying the status itself.
enum ChoreFlag {
  needsCover,
  awaitingVerification,
  needsAttention,
  planned,
  swapPending,
}

/// A pill for one [ChoreFlag].
class FlagChip extends StatelessWidget {
  const FlagChip({required this.flag, this.compact = false, super.key});

  final ChoreFlag flag;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final text = labelFor(flag, context.l10n);
    final tone = toneFor(flag, tokens);

    return Semantics(
      container: true,
      label: text,
      excludeSemantics: true,
      child: Container(
        constraints: const BoxConstraints(minHeight: 24),
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 10,
          vertical: compact ? 2 : 4,
        ),
        decoration: BoxDecoration(
          color: tone.container,
          borderRadius: BorderRadius.circular(tokens.radiusPill),
          border: Border.all(color: tone.foreground.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              iconFor(flag),
              size: compact ? 12 : 14,
              color: tone.foreground,
            ),
            SizedBox(width: compact ? 4 : 6),
            Flexible(
              child: Text(
                text,
                style: TextStyle(
                  color: tone.foreground,
                  fontSize: compact ? 11 : 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Localized label of [flag].
  static String labelFor(ChoreFlag flag, AppLocalizations l10n) =>
      switch (flag) {
        ChoreFlag.needsCover => l10n.choreFlagNeedsCover,
        ChoreFlag.awaitingVerification => l10n.choreFlagAwaitingVerification,
        ChoreFlag.needsAttention => l10n.choreFlagNeedsAttention,
        ChoreFlag.planned => l10n.choreFlagPlanned,
        ChoreFlag.swapPending => l10n.choreFlagSwapPending,
      };

  static IconData iconFor(ChoreFlag flag) => switch (flag) {
    ChoreFlag.needsCover => Icons.person_search_rounded,
    ChoreFlag.awaitingVerification => Icons.fact_check_outlined,
    ChoreFlag.needsAttention => Icons.priority_high_rounded,
    ChoreFlag.planned => Icons.auto_awesome_outlined,
    ChoreFlag.swapPending => Icons.swap_horiz_rounded,
  };

  /// The tone of [flag]: danger for attention, info for a state that waits on
  /// somebody, planned uses the neutral skipped pair (it is not real data yet).
  static FlagTone toneFor(ChoreFlag flag, AppTokens t) => switch (flag) {
    ChoreFlag.needsCover => FlagTone(t.warning, t.surfaceSunken),
    ChoreFlag.awaitingVerification => FlagTone(t.info, t.surfaceSunken),
    ChoreFlag.needsAttention => FlagTone(t.danger, t.statusOverdueContainer),
    ChoreFlag.planned => FlagTone(t.statusSkipped, t.statusSkippedContainer),
    ChoreFlag.swapPending => FlagTone(t.accent, t.surfaceSunken),
  };
}

/// Foreground and background of a [FlagChip].
@immutable
class FlagTone {
  const FlagTone(this.foreground, this.container);
  final Color foreground;
  final Color container;
}
