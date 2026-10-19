import 'package:family_hub/core/firebase/doc_state.dart';
import 'package:family_hub/core/firebase/doc_watch.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('docStateOf', () {
    test('exists -> Present, even from the cache', () {
      for (final cache in [true, false]) {
        expect(
          docStateOf(exists: true, isFromCache: cache, data: {'a': 1}),
          const DocPresent<Map<String, dynamic>>({'a': 1}),
        );
      }
    });

    test('missing + from cache -> Unknown (NOT absent)', () {
      expect(
        docStateOf(exists: false, isFromCache: true, data: null),
        const DocUnknown<Map<String, dynamic>>(),
      );
    });

    test('missing + confirmed by the server -> Absent', () {
      expect(
        docStateOf(exists: false, isFromCache: false, data: null),
        const DocAbsent<Map<String, dynamic>>(),
      );
    });
  });

  group('knownOnly', () {
    test('drops Unknown, maps Absent to null and Present to the data', () async {
      final out = await knownOnly(
        Stream.fromIterable(<DocState<Map<String, dynamic>>>[
          const DocUnknown(),
          const DocAbsent(),
          const DocUnknown(),
          const DocPresent({'x': 1}),
        ]),
      ).toList();
      expect(out, [
        null,
        {'x': 1},
      ]);
    });

    test('a stream that is only Unknown never emits (session stays loading)',
        () async {
      final out = await knownOnly(
        Stream.fromIterable(<DocState<Map<String, dynamic>>>[
          const DocUnknown(),
          const DocUnknown(),
        ]),
      ).toList();
      expect(out, isEmpty);
    });
  });
}
