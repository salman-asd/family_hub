import 'dart:math' as math;

import 'package:flutter/material.dart';

final class ConfettiPainter extends CustomPainter {
  ConfettiPainter({
    required this.seed,
    required this.progress,
    required Iterable<Color> colors,
  }) : colors = List<Color>.unmodifiable(colors),
       _particles = _makeParticles(seed);

  static const int particleCount = 48;

  final int seed;
  final double progress;
  final List<Color> colors;
  final List<_Particle> _particles;

  @override
  void paint(Canvas canvas, Size size) {
    if (colors.isEmpty || size.isEmpty) return;

    final visibleProgress = progress.clamp(0, 1).toDouble();
    for (var index = 0; index < _particles.length; index++) {
      final particle = _particles[index];
      if (visibleProgress <= particle.delay) continue;
      final travel = ((visibleProgress - particle.delay) / (1 - particle.delay))
          .clamp(0, 1)
          .toDouble();
      final x =
          particle.startX * size.width +
          math.sin(travel * math.pi * 2 + particle.phase) *
              particle.drift *
              size.width;
      final y = (travel * 1.22 - 0.12) * size.height;
      final paint = Paint()..color = colors[index % colors.length];

      canvas
        ..save()
        ..translate(x, y)
        ..rotate(travel * math.pi * 2 + particle.phase);
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: particle.width,
          height: particle.height,
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant ConfettiPainter oldDelegate) =>
      seed != oldDelegate.seed ||
      progress != oldDelegate.progress ||
      !_sameColors(colors, oldDelegate.colors);

  static List<_Particle> _makeParticles(int seed) {
    final random = math.Random(seed);
    return List<_Particle>.unmodifiable(
      List<_Particle>.generate(
        particleCount,
        (_) => _Particle(
          startX: random.nextDouble(),
          delay: random.nextDouble() * 0.45,
          phase: random.nextDouble() * math.pi * 2,
          drift: 0.025 + random.nextDouble() * 0.075,
          width: 3 + random.nextDouble() * 4,
          height: 5 + random.nextDouble() * 5,
        ),
      ),
    );
  }

  static bool _sameColors(List<Color> first, List<Color> second) {
    if (first.length != second.length) return false;
    for (var index = 0; index < first.length; index++) {
      if (first[index] != second[index]) return false;
    }
    return true;
  }
}

final class _Particle {
  const _Particle({
    required this.startX,
    required this.delay,
    required this.phase,
    required this.drift,
    required this.width,
    required this.height,
  });

  final double startX;
  final double delay;
  final double phase;
  final double drift;
  final double width;
  final double height;
}
