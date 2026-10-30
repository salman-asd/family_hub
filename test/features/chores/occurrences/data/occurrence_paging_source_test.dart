import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// B-09 guard: the Firestore query itself cannot run without an emulator, so
/// this reads the repository source and pins the two properties that make the
/// paging safe: a TOTAL order (`dateKey`, then document id) and a cursor that
/// is a DOCUMENT, never a field value.
void main() {
  final source = File(
    'lib/features/chores/occurrences/data/firestore_occurrence_repository.dart',
  ).readAsStringSync();

  test('every one-shot read orders by dateKey and then by document id', () {
    final orders = RegExp(
      r"\.orderBy\('dateKey'\)\s*\.orderBy\(FieldPath\.documentId\)",
    ).allMatches(source).length;
    // _rangeQuery (live month, ids, list) and listByTemplate.
    expect(orders, 2);
  });

  test('paging resumes after a document, not after a field value', () {
    expect(source, contains('startAfterDocument('));
    expect(source, isNot(contains('.startAfter(')));
    expect(source, isNot(contains("get('dateKey')")));
  });

  test('the page limit is applied once, from one constant', () {
    expect(RegExp(r'limit: kOccurrencePageSize').allMatches(source).length, 2);
  });
}
