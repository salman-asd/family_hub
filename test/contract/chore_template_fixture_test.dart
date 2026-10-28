import 'dart:convert';
import 'dart:io';

import 'package:family_hub/core/firebase/base_mapper.dart';
import 'package:family_hub/core/utils/clock.dart';
import 'package:family_hub/features/chores/templates/data/chore_template_mappers.dart';
import 'package:family_hub/features/chores/templates/domain/chore_template.dart';
import 'package:flutter_test/flutter_test.dart';

import '../features/chores/chores_test_helpers.dart';

/// P3-08: the JS fixture in `firebase/rules_test/support.mjs` and the Dart
/// mapper must describe the SAME document. The rules tests use the JS fixture
/// (readable, one field per line); the contract fixture uses the real mapper.
/// If one gains a field the other does not, this test fails - otherwise the
/// rules could pass in Node while the app writes a key the rules reject.
void main() {
  final meta = BaseMapper.createMetadata(
    uid: 'alice',
    clock: FakeClock(DateTime.utc(2026, 10, 24, 9)),
  );

  test('the JS fixture keys == ChoreTemplateMappers.toMap keys', () {
    final source = File('firebase/rules_test/support.mjs').readAsStringSync();
    final start = source.indexOf('export const choreTemplateDoc');
    expect(start, greaterThan(-1), reason: 'choreTemplateDoc not found');
    // The fixture's own map closes with a line that is exactly `  });`; the
    // nested `reminders` block closes deeper and must not end the scan.
    final close = RegExp(
      r'^  \}\);$',
      multiLine: true,
    ).firstMatch(source.substring(start));
    expect(close, isNotNull, reason: 'the fixture never closes');
    final body = source.substring(start, start + close!.start);
    // `key:` at the start of a line (nested maps are indented deeper).
    final jsKeys = RegExp(
      r'^ {4}([A-Za-z][A-Za-z0-9]*):',
      multiLine: true,
    ).allMatches(body).map((match) => match.group(1)!).toSet();
    // The fixture wraps its map in `...baseDoc(uid, { … })`, whose keys sit one
    // level deeper; `metadataToMap` writes exactly those.
    final spread = RegExp(
      r'^ {6}([A-Za-z][A-Za-z0-9]*):',
      multiLine: true,
    ).allMatches(body).map((match) => match.group(1)!).toSet();
    expect(jsKeys, isNotEmpty, reason: 'the parser found no keys');
    expect(spread, isNotEmpty, reason: 'the parser found no metadata keys');
    jsKeys.addAll(spread);

    final dartKeys = ChoreTemplateMappers.toMap(
      ChoreTemplate(id: 'tpl_1', draft: aTemplate()),
      meta,
    ).keys.toSet();

    expect(
      jsKeys.difference(dartKeys),
      isEmpty,
      reason: 'the JS fixture has keys the mapper never writes',
    );
    expect(
      dartKeys.difference(jsKeys),
      isEmpty,
      reason: 'the mapper writes keys the JS fixture lacks',
    );
    expect(
      spread.difference(jsKeys),
      isEmpty,
      reason: 'the metadata spread must stay inside the fixture',
    );
  });

  test('the generated contract fixture is the real mapper output', () {
    final file = File('firebase/rules_test/fixtures/chore_template.json');
    expect(file.existsSync(), isTrue);
    final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    final writes = json['writes'] as List<dynamic>;
    final template = writes.cast<Map<String, dynamic>>().firstWhere(
      (w) => '${w['path']}'.contains('/choreTemplates/'),
    );
    final data = (template['data'] as Map<String, dynamic>);
    expect(data['revision'], 1);
    expect(data['seedKey'], isNull);
    expect(data['recurrence'], isA<Map<String, dynamic>>());
    expect(
      (data['recurrence'] as Map<String, dynamic>)['kind'],
      'every_n_days',
    );
    expect(data['slots'], hasLength(2));
    expect(data['subtasks'], hasLength(2));
  });
}
