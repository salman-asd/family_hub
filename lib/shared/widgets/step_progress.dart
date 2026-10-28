import 'dart:math' as math;

import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:family_hub/core/localization/app_formatters.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:flutter/material.dart';

/// "3/5" with a determinate ring next to it (P3-04).
///
/// Used for a chore's subtasks. The ring animates from the previous value, but
/// not with reduced motion (`MediaQuery.disableAnimations`), and the number is
/// always shown as text, so a colour-blind or screen-reader user loses nothing.
class StepProgress extends StatelessWidget {
  const StepProgress({
    required this.done,
    required this.total,
    required this.formatters,
    this.size = 20,
    this.semanticLabel,
    super.key,
  });

  final int done;
  final int total;

  /// Supplies the digits (Bangla or ASCII) of the "3/5" text.
  final AppFormatters formatters;

  final double size;

  /// Overrides the announced text (defaults to the localized "3 of 5 done").
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final safeTotal = math.max(total, 0);
    final safeDone = done.clamp(0, safeTotal);
    final value = safeTotal == 0 ? 0.0 : safeDone / safeTotal;
    final label =
        semanticLabel ??
        context.l10n.stepProgressSemantic(
          formatters.number(safeDone),
          formatters.number(safeTotal),
        );

    return Semantics(
      label: label,
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: value),
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : tokens.durationMedium,
            curve: tokens.curveStandard,
            builder: (context, animated, _) {
              return SizedBox.square(
                dimension: size,
                child: CustomPaint(
                  painter: _RingPainter(
                    value: animated,
                    track: tokens.divider,
                    progress: value >= 1 ? tokens.success : tokens.accent,
                    stroke: math.max(2, size * 0.14),
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 6),
          Text(
            '${formatters.number(safeDone)}/${formatters.number(safeTotal)}',
            style: TextStyle(
              color: tokens.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.value,
    required this.track,
    required this.progress,
    required this.stroke,
  });

  final double value;
  final Color track;
  final Color progress;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final centre = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - stroke / 2;
    final trackPaint = Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    final progressPaint = Paint()
      ..color = progress
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(centre, radius, trackPaint);
    if (value <= 0) return;
    canvas.drawArc(
      Rect.fromCircle(center: centre, radius: radius),
      -math.pi / 2,
      2 * math.pi * value.clamp(0, 1),
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.value != value || old.progress != progress || old.track != track;
}
