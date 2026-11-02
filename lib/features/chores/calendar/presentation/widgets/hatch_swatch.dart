import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:family_hub/app/theme/heat_ramp.dart';
import 'package:family_hub/features/chores/calendar/presentation/painters/hatch_painter.dart';
import 'package:flutter/material.dart';

/// A small square filled with the hatch of a day cell, for the legend and the
/// gallery. Decorative (the row next to it says what it means).
class HatchSwatch extends StatelessWidget {
  const HatchSwatch({required this.directions, this.size = 28, super.key});

  final Set<HatchDirection> directions;
  final double size;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final radius = BorderRadius.circular(t.radiusSm);
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: t.divider),
          ),
          child: ClipRRect(
            borderRadius: radius,
            child: CustomPaint(
              painter: HatchPainter(
                colour: HeatRamp.hatchLine(t, t.background),
                directions: directions,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
