import 'dart:async';

import 'package:family_hub/core/utils/stream_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('follows the newest inner stream and cancels the old one', () async {
    final source = StreamController<int>();
    final inner = <int, StreamController<String>>{
      1: StreamController<String>(),
      2: StreamController<String>(),
    };
    final out = <String>[];
    final sub = switchMap<int, String>(
      source.stream,
      (v) => inner[v]!.stream,
    ).listen(out.add);

    source.add(1);
    await pumpEventQueue();
    inner[1]!.add('a1');
    await pumpEventQueue();

    source.add(2);
    await pumpEventQueue();
    inner[1]!.add('late-from-old'); // must be ignored
    inner[2]!.add('b1');
    await pumpEventQueue();

    expect(out, ['a1', 'b1']);
    expect(inner[1]!.hasListener, isFalse);
    expect(inner[2]!.hasListener, isTrue);

    await sub.cancel();
    expect(inner[2]!.hasListener, isFalse);
    await source.close();
    await inner[1]!.close();
    await inner[2]!.close();
  });

  test(
    'completes when the source and the last inner stream are done',
    () async {
      final source = StreamController<int>();
      final done = Completer<void>();
      final out = <int>[];
      switchMap<int, int>(
        source.stream,
        (v) => Stream.value(v * 10),
      ).listen(out.add, onDone: done.complete);
      source
        ..add(1)
        ..add(2);
      await source.close();
      await done.future;
      expect(out.last, 20);
    },
  );

  test('errors from the source are forwarded', () async {
    final source = StreamController<int>();
    final errors = <Object>[];
    switchMap<int, int>(
      source.stream,
      Stream.value,
    ).listen((_) {}, onError: errors.add);
    source.addError('boom');
    await pumpEventQueue();
    expect(errors, ['boom']);
    await source.close();
  });
}
