import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:flutter/material.dart';

/// A circular progress indicator painted from [AppTokens] (Step 11).
///
/// [value] is `0.0`–`1.0` for a determinate ring (clamped, so a caller cannot
/// paint outside the circle) or null for an indeterminate one whose duration is
/// unknown.  [center] is an optional short label such as "৭৫%"; the ring never
/// draws text itself, so it owns no copy.
///
/// Accessibility: when [semanticLabel] is given it replaces the platform's
/// generic announcement — include the value there ("৭৫% সম্পন্ন"), because the
/// indicator's own value semantics are excluded.
class ProgressRing extends StatelessWidget {
  const ProgressRing({
    this.value,
    this.size = 48,
    this.strokeWidth = 4,
    this.color,
    this.backgroundColor,
    this.center,
    this.semanticLabel,
    super.key,
  });

  /// Progress from 0.0 to 1.0, or null for an indeterminate ring.
  final double? value;

  /// Outer diameter, in logical pixels.
  final double size;

  /// Thickness of the ring.
  final double strokeWidth;

  /// Ring colour; defaults to the theme accent.
  final Color? color;

  /// Colour of the unfilled track; defaults to `surfaceSunken`.
  final Color? backgroundColor;

  /// Optional content in the middle (a percentage, a count, an icon).  It is
  /// clipped to the ring, so keep it short.
  final Widget? center;

  /// Localized screen-reader label.  Null leaves the platform's own
  /// announcement in place.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

    Widget ring = SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        // Reduced motion (H11): an indeterminate ring would spin forever, so it
        // is drawn as a static quarter ring instead.
        value:
            value?.clamp(0.0, 1.0) ??
            (MediaQuery.of(context).disableAnimations ? 0.25 : null),
        strokeWidth: strokeWidth,
        strokeCap: StrokeCap.round,
        color: color ?? t.accent,
        backgroundColor: backgroundColor ?? t.surfaceSunken,
      ),
    );

    final child = center;
    if (child != null) {
      ring = SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            ring,
            Padding(padding: EdgeInsets.all(strokeWidth * 2), child: child),
          ],
        ),
      );
    }

    final label = semanticLabel;
    if (label == null) return ring;
    return Semantics(
      container: true,
      label: label,
      child: ExcludeSemantics(child: ring),
    );
  }
}
