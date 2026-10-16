import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Scans every .dart file under lib/ (excluding lib/app/theme/) and fails if
/// the pattern `Color(0x` appears. This enforces the rule that raw color
/// literals must only appear inside theme files.
void main() {
  test('no raw Color(0x...) literals outside lib/app/theme/', () async {
    final libDir = Directory('lib');
    final themeDir = Directory('lib/app/theme');

    expect(libDir.existsSync(), isTrue, reason: 'lib/ directory not found');

    final violations = <String>[];

    await for (final entity in libDir.list(recursive: true)) {
      if (entity is! File) continue;
      if (!entity.path.endsWith('.dart')) continue;

      // Normalize slashes for cross-platform comparison
      final normalized = entity.path.replaceAll(r'\', '/');

      // Allow raw Color inside the theme directory
      if (normalized.startsWith(themeDir.path.replaceAll(r'\', '/'))) {
        continue;
      }

      final lines = entity.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        // Match Color(0x...) — hex literal colors
        if (line.contains('Color(0x')) {
          violations.add('${entity.path}:${i + 1}: $line');
        }
      }
    }

    if (violations.isNotEmpty) {
      fail(
        'Raw Color(0x...) found outside lib/app/theme/.\n'
        'Move these to a token file and reference via context.tokens:\n'
        '${violations.join('\n')}',
      );
    }
  });
}

