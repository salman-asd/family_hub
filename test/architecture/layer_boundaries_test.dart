import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Enforces the layer table of CLAUDE.md:
///
/// * `domain/` imports no Flutter, Riverpod, router or Firebase package;
/// * `presentation/`, `shared/` and `modules/` import no Firebase package and no
///   `data/` folder;
/// * `lib/app/` may only touch `data/` and Firebase from `bootstrap.dart` (the
///   composition root) and from the Firebase option files.
void main() {
  final domainForbidden = RegExp(
    r"""^\s*(?:import|export)\s+['"]package:(flutter|flutter_riverpod|riverpod|go_router|firebase_[a-z_]+|cloud_firestore)/""",
  );
  final firebaseImport = RegExp(
    r"""^\s*(?:import|export)\s+['"]package:(firebase_[a-z_]+|cloud_firestore)/""",
  );
  final dataImport = RegExp(
    r"""^\s*(?:import|export)\s+['"]package:family_hub/(?:[a-z_/]+/)?data/""",
  );

  Iterable<File> dartFiles(String root) {
    final dir = Directory(root);
    if (!dir.existsSync()) return const [];
    return dir
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'));
  }

  String norm(File f) => f.path.replaceAll(r'\', '/');

  List<String> offenders(
    Iterable<File> files,
    RegExp pattern, {
    bool Function(String path)? skip,
  }) {
    final found = <String>[];
    for (final file in files) {
      final path = norm(file);
      if (skip != null && skip(path)) continue;
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (pattern.hasMatch(lines[i])) found.add('$path:${i + 1}');
      }
    }
    return found;
  }

  test('the detectors recognise forbidden imports', () {
    expect(
      domainForbidden.hasMatch("import 'package:flutter/material.dart';"),
      isTrue,
    );
    expect(
      domainForbidden
          .hasMatch("import 'package:flutter_riverpod/flutter_riverpod.dart';"),
      isTrue,
    );
    expect(
      domainForbidden.hasMatch("import 'package:family_hub/core/errors/x.dart';"),
      isFalse,
    );
    expect(
      dataImport.hasMatch(
        "import 'package:family_hub/features/auth/data/x.dart';",
      ),
      isTrue,
    );
  });

  test('domain/ folders are pure Dart', () {
    final bad = offenders(
      dartFiles('lib/features').where((f) => norm(f).contains('/domain/')),
      domainForbidden,
    );
    expect(bad, isEmpty, reason: 'domain must not import Flutter/Firebase');
  });

  test('presentation/, shared/ and modules/ never touch Firebase or data/', () {
    final files = [
      ...dartFiles('lib/features').where((f) => norm(f).contains('/presentation/')),
      ...dartFiles('lib/shared'),
      ...dartFiles('lib/modules'),
    ];
    expect(offenders(files, firebaseImport), isEmpty);
    expect(offenders(files, dataImport), isEmpty);
  });

  test('lib/app/ reaches data/ and Firebase only through bootstrap.dart', () {
    bool skip(String p) => p.endsWith('lib/app/bootstrap.dart');
    final files = dartFiles('lib/app');
    expect(offenders(files, firebaseImport, skip: skip), isEmpty);
    expect(offenders(files, dataImport, skip: skip), isEmpty);
  });
}
