import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:flutter/material.dart';

/// How a [ProgressBarStatus] should read: within plan, nearing the limit, or
/// over it.  It lives here (not in a feature) so `shared/` stays independent.
enum ProgressLevel { ok, warning, exceeded }

/// A horizontal progress bar with an icon, a label and a colour (P2-12).
///
/// [basisPoints] is an integer percentage in basis points (`10000` = 100%),
/// so no `double` reaches the UI for a money/budget comparison.  The fill is
/// clamped at 100% and an overflow tick marks that the value is above the
/// limit; the icon and the label say the same thing, so status is never
/// conveyed by colour alone (CLAUDE.md rule 13).
///
/// `null` means "no limit configured": no bar is drawn, only the label row.
class ProgressBarStatus extends StatelessWidget {
  const ProgressBarStatus({
    required this.level,
    required this.label,
    this.basisPoints,
    this.trailing,
    super.key,
  });

  /// Percentage of the limit, in basis points (10000 = 100%).
  final int? basisPoints;

  final ProgressLevel level;

  /// Localized caption ("Monthly budget", "No limit", …).
  final String label;

  /// Optional localized value shown on the trailing edge ("৮৪%").
  final String? trailing;

  /// The fill rectangle, exposed for the clamp test.
  static const Key fillKey = ValueKey('progressBarFill');

  /// The overflow marker, drawn only above 100%.
  static const Key overflowKey = ValueKey('progressBarOverflowTick');

  /// Fraction of the track to fill, always inside `0.0 … 1.0`.
  static double fractionFor(int? basisPoints) =>
      ((basisPoints ?? 0) / 10000).clamp(0.0, 1.0).toDouble();

  bool get _overflowed => (basisPoints ?? 0) > 10000;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final textTheme = Theme.of(context).textTheme;
    final foreground = _foreground(t);
    final value = trailing;
    final words = value == null ? label : '$label $value';

    return Semantics(
      container: true,
      label: words,
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_icon, size: 18, color: foreground),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: textTheme.bodyMedium?.copyWith(color: t.textPrimary),
                ),
              ),
              if (value != null) ...[
                const SizedBox(width: 8),
                Text(
                  value,
                  style: textTheme.bodySmall?.copyWith(
                    color: t.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
          if (basisPoints != null) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(t.radiusPill),
              child: SizedBox(
                height: 10,
                child: Stack(
                  children: [
                    Positioned.fill(child: ColoredBox(color: t.surfaceSunken)),
                    FractionallySizedBox(
                      key: fillKey,
                      alignment: Alignment.centerLeft,
                      widthFactor: fractionFor(basisPoints),
                      heightFactor: 1,
                      child: ColoredBox(color: foreground),
                    ),
                    if (_overflowed)
                      Positioned(
                        key: overflowKey,
                        top: 0,
                        bottom: 0,
                        right: 0,
                        child: SizedBox(
                          width: 3,
                          child: ColoredBox(color: foreground),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  IconData get _icon => switch (level) {
    ProgressLevel.ok => Icons.check_circle_outline_rounded,
    ProgressLevel.warning => Icons.warning_amber_rounded,
    ProgressLevel.exceeded => Icons.error_outline_rounded,
  };

  Color _foreground(AppTokens t) => switch (level) {
    ProgressLevel.ok => t.success,
    ProgressLevel.warning => t.warning,
    ProgressLevel.exceeded => t.danger,
  };
}
