import 'package:flutter/material.dart';

/// Which way the hatch lines lean. Two directions so a day that is both
/// planned and has someone away shows a cross-hatch, and each meaning keeps
/// its own pattern (never colour alone, B.3).
enum HatchDirection {
  /// `/` - the day only holds planned chores (not written yet).
  rising,

  /// `\` - somebody is away that day.
  falling,
}

/// Diagonal hatch behind a day cell (P3-24, B.3).
///
/// Purely decorative: wrap it in `ExcludeSemantics` (the cell label already
/// says "planned" / "someone is away"). Thin lines at [spacing] dp, clipped to
/// the box it is painted in.
class HatchPainter extends CustomPainter {
  const HatchPainter({
    required this.colour,
    required this.directions,
    this.spacing = 7,
    this.strokeWidth = 1,
  });

  final Color colour;
  final Set<HatchDirection> directions;
  final double spacing;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    if (directions.isEmpty || size.isEmpty) return;
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    final paint = Paint()
      ..color = colour
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    if (directions.contains(HatchDirection.rising)) {
      for (var x = -size.height; x < size.width; x += spacing) {
        canvas.drawLine(
          Offset(x, size.height),
          Offset(x + size.height, 0),
          paint,
        );
      }
    }
    if (directions.contains(HatchDirection.falling)) {
      for (var x = -size.height; x < size.width; x += spacing) {
        canvas.drawLine(
          Offset(x, 0),
          Offset(x + size.height, size.height),
          paint,
        );
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(HatchPainter old) =>
      old.colour != colour ||
      old.spacing != spacing ||
      old.strokeWidth != strokeWidth ||
      old.directions.length != directions.length ||
      !old.directions.containsAll(directions);
}
