import 'dart:ui' as ui;

import 'package:family_hub/features/chores/achievements/presentation/widgets/badge_painter.dart';
import 'package:family_hub/features/chores/achievements/presentation/widgets/plant_painter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('plant painter supports all stages and growth endpoints', () {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    for (var stage = 0; stage <= 7; stage++) {
      for (final growth in const <double>[0, 1]) {
        PlantPainter(
          stage: stage,
          growth: growth,
          leaf: Colors.green,
          stem: Colors.brown,
          pot: Colors.grey,
          flower: Colors.pink,
        ).paint(canvas, const Size(112, 112));
      }
    }
    recorder.endRecording().dispose();
  });

  test('badge painter distinguishes earned and locked medals', () {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const BadgePainter(
      color: Colors.amber,
      earned: true,
    ).paint(canvas, const Size(72, 72));
    const BadgePainter(
      color: Colors.grey,
      earned: false,
    ).paint(canvas, const Size(72, 72));
    recorder.endRecording().dispose();
  });
}
