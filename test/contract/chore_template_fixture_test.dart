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
    final keys = _jsFixtureKeys();
    expect(keys, isNotEmpty, reason: 'the parser found no keys');

    final dartKeys = ChoreTemplateMappers.toMap(
      ChoreTemplate(id: 'tpl_1', draft: aTemplate()),
      meta,
    ).keys.toSet();

    expect(
      keys.difference(dartKeys),
      isEmpty,
      reason: 'the JS fixture has keys the mapper never writes',
    );
    expect(
      dartKeys.difference(keys),
      isEmpty,
      reason: 'the mapper writes keys the JS fixture lacks',
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
    final data = template['data'] as Map<String, dynamic>;
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

/// Keys written directly in the `choreTemplateDoc` map (4-space indent), plus
/// the `...baseDoc(uid, { … })` spread one level deeper (that is
/// `metadataToMap`). Nested value maps (`recurrence`, `slots`, `reminders`)
/// are deeper still and are not collected.
Set<String> _jsFixtureKeys() {
  final source = File('firebase/rules_test/support.mjs').readAsStringSync();
  final lines = const LineSplitter().convert(source);
  final start = lines.indexWhere(
    (line) => line.contains('export const choreTemplateDoc'),
  );
  expect(start, greaterThan(-1), reason: 'choreTemplateDoc not found');

  final keys = <String>{};
  for (var i = start + 1; i < lines.length; i++) {
    final line = lines[i];
    if (line.trim() == '});') break; // the fixture's own map ends here
    // The document keys sit 4 spaces deep inside `...baseDoc(uid, { … })`.
    // Nested VALUE maps (`reminders`) are deeper; their keys are not document
    // keys and must not be collected.
    final match = RegExp(r'^ {4}([A-Za-z][A-Za-z0-9]*):').firstMatch(line);
    if (match != null) keys.add(match.group(1)!);
  }
  // ...baseDoc(uid, { … }) supplies BaseMapper.metadataToMap's keys.
  keys.addAll(const <String>[
    'createdAt',
    'createdBy',
    'updatedAt',
    'updatedBy',
    'schemaVersion',
  ]);
  return keys;
}
