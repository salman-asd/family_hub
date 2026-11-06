import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:family_hub/features/chores/achievements/presentation/engagement_motion.dart';
import 'package:family_hub/features/chores/achievements/presentation/widgets/plant_painter.dart';
import 'package:flutter/material.dart';

class EngagementPlantView extends StatelessWidget {
  const EngagementPlantView({
    required this.stage,
    required this.semanticLabel,
    this.size = 88,
    super.key,
  });

  final int stage;
  final String semanticLabel;
  final double size;

  @override
  Widget build(BuildContext context) {
    PlantPainter painter(double growth) => PlantPainter(
      stage: stage,
      growth: growth,
      leaf: context.tokens.chart[2],
      stem: context.tokens.statusCompleted,
      pot: context.tokens.surfaceRaised,
      flower: context.tokens.chart[4],
    );
    final reduced = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      container: true,
      label: semanticLabel,
      child: ExcludeSemantics(
        child: SizedBox.square(
          dimension: size,
          child: reduced
              ? CustomPaint(painter: painter(1))
              : TweenAnimationBuilder<double>(
                  key: ValueKey(stage),
                  tween: Tween<double>(begin: 0, end: 1),
                  duration: engagementMotion(context),
                  builder: (context, growth, _) =>
                      CustomPaint(painter: painter(growth)),
                ),
        ),
      ),
    );
  }
}
