import 'dart:async';

import 'package:family_hub/core/utils/stream_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'emits only after every source has emitted, then on each change',
    () async {
      final a = StreamController<int>();
      final b = StreamController<int>();
      final c = StreamController<int>();
      final out = <String>[];
      final sub = combineLatest3<int, int, int, String>(
        a.stream,
        b.stream,
        c.stream,
        (x, y, z) => '$x$y$z',
      ).listen(out.add);

      a.add(1);
      b.add(2);
      await Future<void>.delayed(Duration.zero);
      expect(out, isEmpty);
      c.add(3);
      await Future<void>.delayed(Duration.zero);
      expect(out, ['123']);
      b.add(9);
      await Future<void>.delayed(Duration.zero);
      expect(out, ['123', '193']);

      await sub.cancel();
      expect(a.hasListener, isFalse);
      expect(b.hasListener, isFalse);
      expect(c.hasListener, isFalse);
      await a.close();
      await b.close();
      await c.close();
    },
  );

  test('forwards errors and closes when all sources are done', () async {
    final a = StreamController<int>();
    final errors = <Object>[];
    var done = false;
    combineLatest3<int, int, int, int>(
      a.stream,
      Stream<int>.value(1),
      Stream<int>.value(1),
      (x, y, z) => x + y + z,
    ).listen((_) {}, onError: errors.add, onDone: () => done = true);
    a.addError('boom');
    await a.close();
    await Future<void>.delayed(Duration.zero);
    expect(errors, ['boom']);
    expect(done, isTrue);
  });
}
