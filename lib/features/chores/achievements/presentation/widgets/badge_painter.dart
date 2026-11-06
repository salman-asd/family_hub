import 'dart:math' as math;

import 'package:flutter/material.dart';

class BadgePainter extends CustomPainter {
  const BadgePainter({required this.color, required this.earned});

  final Color color;
  final bool earned;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, 30);
    final radius = 34.0;
    final path = Path();
    for (var point = 0; point < 24; point++) {
      final angle = point * math.pi / 12 - math.pi / 2;
      final distance = point.isEven ? radius : radius * .9;
      final position = center.translate(
        math.cos(angle) * distance,
        math.sin(angle) * distance,
      );
      if (point == 0) {
        path.moveTo(position.dx, position.dy);
      } else {
        path.lineTo(position.dx, position.dy);
      }
    }
    path.close();
    canvas.drawPath(
      path,
      Paint()
        ..color = color.withValues(alpha: earned ? .16 : .08)
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(BadgePainter oldDelegate) =>
      color != oldDelegate.color || earned != oldDelegate.earned;
}
