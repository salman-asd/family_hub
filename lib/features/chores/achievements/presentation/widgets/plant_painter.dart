import 'dart:math' as math;

import 'package:flutter/material.dart';

class PlantPainter extends CustomPainter {
  const PlantPainter({
    required this.stage,
    required this.growth,
    required this.leaf,
    required this.stem,
    required this.pot,
    required this.flower,
  }) : assert(stage >= 0 && stage <= 7),
       assert(growth >= 0 && growth <= 1);

  final int stage;
  final double growth;
  final Color leaf;
  final Color stem;
  final Color pot;
  final Color flower;

  @override
  void paint(Canvas canvas, Size size) {
    final unit = math.min(size.width, size.height) / 100;
    final origin = Offset(size.width / 2, size.height * .82);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.2 * unit;

    final potPaint = Paint()..color = pot;
    final potPath = Path()
      ..moveTo(origin.dx - 25 * unit, origin.dy)
      ..lineTo(origin.dx + 25 * unit, origin.dy)
      ..lineTo(origin.dx + 18 * unit, origin.dy + 17 * unit)
      ..lineTo(origin.dx - 18 * unit, origin.dy + 17 * unit)
      ..close();
    canvas.drawPath(potPath, potPaint);
    canvas.drawLine(
      Offset(origin.dx - 26 * unit, origin.dy),
      Offset(origin.dx + 26 * unit, origin.dy),
      Paint()
        ..color = stem
        ..strokeWidth = 4 * unit
        ..strokeCap = StrokeCap.round,
    );

    final stemTop = origin.translate(0, -58 * unit);
    canvas.save();
    canvas.translate(origin.dx, origin.dy);
    canvas.scale(1, growth);
    canvas.translate(-origin.dx, -origin.dy);
    canvas.drawLine(
      origin.translate(0, -2 * unit),
      stemTop,
      paint..color = stem,
    );
    final leafCount = stage == 0 ? 0 : stage + 1;
    for (var index = 0; index < leafCount; index++) {
      final side = index.isEven ? -1.0 : 1.0;
      final fraction = (index ~/ 2 + 1) / ((leafCount + 1) / 2);
      final y = origin.dy - (13 + 36 * fraction) * unit;
      final start = Offset(origin.dx, y);
      final end = Offset(
        origin.dx + side * (13 + 5 * fraction) * unit,
        y - 7 * unit,
      );
      final path = Path()
        ..moveTo(start.dx, start.dy)
        ..quadraticBezierTo(
          start.dx + side * 8 * unit,
          start.dy - 13 * unit,
          end.dx,
          end.dy,
        )
        ..quadraticBezierTo(
          start.dx + side * 8 * unit,
          start.dy + 2 * unit,
          start.dx,
          start.dy,
        );
      canvas.drawPath(path, Paint()..color = leaf);
      canvas.drawLine(start, end, paint..color = stem);
    }

    if (stage >= 5) {
      final center = stemTop.translate(0, -5 * unit);
      for (var petal = 0; petal < 5; petal++) {
        final angle = petal * math.pi * 2 / 5;
        canvas.drawCircle(
          center.translate(
            math.cos(angle) * 5 * unit,
            math.sin(angle) * 5 * unit,
          ),
          3 * unit,
          Paint()..color = flower,
        );
      }
      canvas.drawCircle(center, 2 * unit, Paint()..color = pot);
    }

    if (stage >= 7) {
      for (final side in const <double>[-1, 1]) {
        canvas.drawCircle(
          Offset(origin.dx + side * 20 * unit, origin.dy - 30 * unit),
          4 * unit,
          Paint()..color = flower,
        );
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(PlantPainter oldDelegate) =>
      stage != oldDelegate.stage ||
      growth != oldDelegate.growth ||
      leaf != oldDelegate.leaf ||
      stem != oldDelegate.stem ||
      pot != oldDelegate.pot ||
      flower != oldDelegate.flower;
}
