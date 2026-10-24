import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:family_hub/core/localization/generated/app_localizations.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// How far along a limit is.  Lives here because `shared/` must not import a
/// feature; budgets map their own level onto it.
enum ProgressLevel { ok, warning, exceeded }

/// A horizontal progress bar for a limit (budget, target) that never relies on
/// colour: the level is also an icon and a word, and an overflow tick shows when
/// the value passes 100 %.
///
/// [basisPoints] is the share of the limit in hundredths of a percent
/// (8000 = 80 %); `null` means there is no limit, which draws an empty track
/// and the "No limit set" label.
class ProgressBarStatus extends ConsumerWidget {
  const ProgressBarStatus({
    required this.basisPoints,
    required this.level,
    required this.label,
    this.trailing,
    super.key,
  });

  final int? basisPoints;
  final ProgressLevel level;

  /// What is being measured, e.g. "Vegetables".
  final String label;

  /// Optional right-hand text, e.g. "৳ 450 left".
  final String? trailing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final t = context.tokens;
    final bp = basisPoints;
    final barColor = _barColor(t);
    final textColor = _textColor(t);
    final levelText = bp == null ? l10n.progressLevelNoLimit : _word(l10n);
    final percentText = bp == null
        ? null
        : ref.watch(appFormattersProvider).number(bp ~/ 100);
    final fill = bp == null ? 0.0 : (bp / 10000).clamp(0.0, 1.0);
    final over = bp != null && bp > 10000;

    return Semantics(
      container: true,
      label: percentText == null
          ? '$label: $levelText'
          : l10n.progressBarSemantics(label, percentText, levelText),
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                Text(
                  trailing!,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: t.textSecondary),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 10,
            child: Stack(
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: t.surfaceSunken,
                      borderRadius: BorderRadius.circular(t.radiusPill),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: FractionallySizedBox(
                    alignment: AlignmentDirectional.centerStart,
                    widthFactor: fill,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: barColor,
                        borderRadius: BorderRadius.circular(t.radiusPill),
                      ),
                    ),
                  ),
                ),
                if (over)
                  PositionedDirectional(
                    end: 0,
                    top: 0,
                    bottom: 0,
                    child: Container(width: 3, color: t.surface),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(_icon(bp), size: 16, color: textColor),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  percentText == null ? levelText : '$percentText% · $levelText',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Fills use the status colours; text and icon use the matching "on" colours,
  // which are the ones the theme tests already check for contrast.
  Color _barColor(AppTokens t) => switch (level) {
    ProgressLevel.ok => t.statusCompleted,
    ProgressLevel.warning => t.statusInProgress,
    ProgressLevel.exceeded => t.statusOverdue,
  };

  Color _textColor(AppTokens t) => switch (level) {
    ProgressLevel.ok => t.statusCompletedOn,
    ProgressLevel.warning => t.statusInProgressOn,
    ProgressLevel.exceeded => t.statusOverdueOn,
  };

  IconData _icon(int? bp) {
    if (bp == null) return Icons.remove_circle_outline_rounded;
    return switch (level) {
      ProgressLevel.ok => Icons.check_circle_outline_rounded,
      ProgressLevel.warning => Icons.warning_amber_rounded,
      ProgressLevel.exceeded => Icons.error_outline_rounded,
    };
  }

  String _word(AppLocalizations l10n) => switch (level) {
    ProgressLevel.ok => l10n.progressLevelOk,
    ProgressLevel.warning => l10n.progressLevelWarning,
    ProgressLevel.exceeded => l10n.progressLevelExceeded,
  };
}
