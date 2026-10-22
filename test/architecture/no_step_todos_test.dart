import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// CLAUDE.md rule 23: no step TODO marker may survive its step (H8).
void main() {
  // Built from pieces so this file does not match itself: the marker is only
  // assembled at runtime, never written verbatim on a source line.
  const todo = 'TODO';
  final marker = RegExp(
    '$todo'
    r'\(step-',
  );

  test('the detector matches a step TODO', () {
    expect(marker.hasMatch('// $todo(step-9): throwaway'), isTrue);
    expect(marker.hasMatch('// TODO: later'), isFalse);
  });

  test('no step TODO marker in lib/ or test/', () {
    final found = <String>[];
    for (final root in ['lib', 'test']) {
      final dir = Directory(root);
      if (!dir.existsSync()) continue;
      for (final file
          in dir
              .listSync(recursive: true)
              .whereType<File>()
              .where((f) => f.path.endsWith('.dart'))) {
        final lines = file.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          if (marker.hasMatch(lines[i])) {
            found.add('${file.path.replaceAll(r'\', '/')}:${i + 1}');
          }
        }
      }
    }
    expect(found, isEmpty);
  });
}
