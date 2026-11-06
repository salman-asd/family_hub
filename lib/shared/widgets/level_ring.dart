import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:family_hub/shared/widgets/progress_ring.dart';
import 'package:flutter/material.dart';

class LevelRing extends StatelessWidget {
  const LevelRing({
    required this.level,
    required this.levelLabel,
    required this.progress,
    required this.progressLabel,
    this.size = 64,
    super.key,
  });

  final int level;
  final String levelLabel;
  final double progress;
  final String progressLabel;
  final double size;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return ProgressRing(
      value: progress,
      size: size,
      color: tokens.accent,
      backgroundColor: tokens.surfaceSunken,
      semanticLabel: '$levelLabel, $progressLabel',
      center: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          '$level',
          style: TextStyle(
            color: tokens.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
