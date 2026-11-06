import 'package:flutter/material.dart';

class ConfettiView extends StatelessWidget {
  const ConfettiView({
    required this.painter,
    required this.reduced,
    this.child,
    this.semanticLabel,
    super.key,
  });

  final CustomPainter painter;
  final bool reduced;
  final Widget? child;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final view = CustomPaint(painter: reduced ? null : painter, child: child);
    final label = semanticLabel;
    return label == null
        ? view
        : Semantics(
            container: true,
            label: label,
            child: ExcludeSemantics(child: view),
          );
  }
}
