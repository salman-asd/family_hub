import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// CLAUDE.md rules 61 and 67 (P4-01, ADR 0015 and 0020): each notification
/// plugin is confined to its adapter, so a widget, a use case or the planner
/// can never call a plugin directly.
///
/// * `flutter_local_notifications` only in `local_notifications_scheduler.dart`
///   and `notification_channels.dart`;
/// * `firebase_messaging` only in `push_messaging_service.dart`;
/// * `android_intent_plus` in at most ONE file, inside
///   `lib/core/notifications/data/`.
///
/// The test scans `lib/` only: a test may import a plugin to mock it.
void main() {
  const adapterDir = 'lib/core/notifications/data/';
  const localAdapters = <String>{
    '${adapterDir}local_notifications_scheduler.dart',
    '${adapterDir}notification_channels.dart',
  };
  const pushAdapters = <String>{'${adapterDir}push_messaging_service.dart'};

  final directive = RegExp(
    r"""^\s*(?:import|export)\s+['"]package:([a-z0-9_]+)/""",
  );

  /// package name -> the files that import or export it.
  Map<String, Set<String>> importers(Map<String, List<String>> sources) {
    final found = <String, Set<String>>{};
    sources.forEach((file, lines) {
      for (final line in lines) {
        final match = directive.firstMatch(line);
        if (match == null) continue;
        found.putIfAbsent(match.group(1)!, () => <String>{}).add(file);
      }
    });
    return found;
  }

  /// The importers of [package] that are not in [allowed], sorted.
  List<String> outside(
    Map<String, Set<String>> found,
    String package,
    Set<String> allowed,
  ) {
    final files = <String>[
      for (final file in found[package] ?? const <String>{})
        if (!allowed.contains(file)) file,
    ]..sort();
    return files;
  }

  Map<String, List<String>> readLib() => {
    for (final entity in Directory('lib').listSync(recursive: true))
      if (entity is File && entity.path.endsWith('.dart'))
        entity.path.replaceAll(r'\', '/'): entity.readAsLinesSync(),
  };

  test('the detector finds imports and exports, and ignores comments', () {
    final found = importers({
      'lib/a.dart': <String>[
        "import 'package:firebase_messaging/firebase_messaging.dart';",
        "export 'package:android_intent_plus/android_intent.dart';",
        "// import 'package:flutter_local_notifications/x.dart';",
        "import 'package:flutter/material.dart';",
      ],
    });
    expect(found['firebase_messaging'], <String>{'lib/a.dart'});
    expect(found['android_intent_plus'], <String>{'lib/a.dart'});
    expect(found.containsKey('flutter_local_notifications'), isFalse);
  });

  test('the detector reports a file outside the adapter', () {
    final found = importers({
      '${adapterDir}push_messaging_service.dart': <String>[
        "import 'package:firebase_messaging/firebase_messaging.dart';",
      ],
      'lib/features/notifications/presentation/some_screen.dart': <String>[
        "import 'package:firebase_messaging/firebase_messaging.dart';",
      ],
    });
    expect(outside(found, 'firebase_messaging', pushAdapters), <String>[
      'lib/features/notifications/presentation/some_screen.dart',
    ]);
  });

  test('flutter_local_notifications is imported only by its two adapters', () {
    final stray = outside(
      importers(readLib()),
      'flutter_local_notifications',
      localAdapters,
    );
    expect(
      stray,
      isEmpty,
      reason:
          'Only local_notifications_scheduler.dart and '
          'notification_channels.dart may import flutter_local_notifications:'
          '\n${stray.join('\n')}',
    );
  });

  test('firebase_messaging is imported only by push_messaging_service', () {
    final stray = outside(
      importers(readLib()),
      'firebase_messaging',
      pushAdapters,
    );
    expect(
      stray,
      isEmpty,
      reason:
          'Only push_messaging_service.dart may import firebase_messaging:'
          '\n${stray.join('\n')}',
    );
  });

  test('android_intent_plus is imported by at most one adapter file', () {
    final files =
        (importers(readLib())['android_intent_plus'] ?? <String>{}).toList()
          ..sort();
    expect(
      files.length,
      lessThanOrEqualTo(1),
      reason: 'Only one file may import android_intent_plus: $files',
    );
    for (final file in files) {
      expect(
        file.startsWith(adapterDir),
        isTrue,
        reason: '$file must live in $adapterDir',
      );
    }
  });
}
