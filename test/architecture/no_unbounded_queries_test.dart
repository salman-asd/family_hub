import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// CLAUDE.md rule 11 (H12): in every `features/**/data/*.dart`, each expression
/// that starts with `.collection(` must contain `.limit(` before its `;`.
/// Single-document reads (`.doc(...)`) are not collections and are allowed.
void main() {
  test('every collection query in a data layer is bounded', () {
    final offenders = <String>[];
    for (final entity in Directory('lib/features').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final path = entity.path.replaceAll(r'\', '/');
      if (!path.contains('/data/')) continue;
      final text = entity.readAsStringSync();
      var from = 0;
      while (true) {
        final i = text.indexOf('.collection(', from);
        if (i < 0) break;
        final end = text.indexOf(';', i);
        final expression = text.substring(i, end < 0 ? text.length : end);
        if (!expression.contains('.limit(')) {
          final line = '\n'.allMatches(text.substring(0, i)).length + 1;
          offenders.add('$path:$line');
        }
        from = i + 1;
      }
    }
    expect(
      offenders,
      isEmpty,
      reason: 'Add .limit(...) to:\n${offenders.join('\n')}',
    );
  });

  test('the detector sees an unbounded query', () {
    const bad = "x.collection('a').snapshots();";
    const good = "x.collection('a').limit(5).snapshots();";
    expect(bad.contains('.limit('), isFalse);
    expect(good.contains('.limit('), isTrue);
  });
}
