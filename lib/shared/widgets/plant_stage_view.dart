import 'package:flutter/material.dart';

class PlantStageView extends StatelessWidget {
  const PlantStageView({
    required this.painter,
    required this.reduced,
    required this.semanticLabel,
    this.child,
    this.size = 88,
    super.key,
  });

  final CustomPainter painter;
  final bool reduced;
  final String semanticLabel;
  final Widget? child;
  final double size;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label: semanticLabel,
    child: ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        child: CustomPaint(painter: reduced ? null : painter, child: child),
      ),
    ),
  );
}
