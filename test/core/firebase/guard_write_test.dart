import 'dart:async';

import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/firebase/firestore_guard.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const quick = Duration(milliseconds: 20);

  test('a commit that completes in time is a plain success', () async {
    var committed = false;
    final result = await guardWrite(() async => committed = true, ackWait: quick);
    expect(result.isSuccess, isTrue);
    expect(committed, isTrue);
  });

  test('an unacknowledged commit is QUEUED: success, and it is not cancelled',
      () async {
    final gate = Completer<void>();
    var finished = false;
    final result = await guardWrite(
      () async {
        await gate.future;
        finished = true;
      },
      ackWait: quick,
    );
    expect(result.isSuccess, isTrue);
    expect(finished, isFalse);

    gate.complete();
    await Future<void>.delayed(Duration.zero);
    expect(finished, isTrue, reason: 'the write keeps running in the background');
  });

  test('a queued write that the server later rejects does not throw', () async {
    final gate = Completer<void>();
    final result = await guardWrite(() => gate.future, ackWait: quick);
    expect(result.isSuccess, isTrue);
    gate.completeError(StateError('permission-denied'));
    await Future<void>.delayed(Duration.zero); // logged, not an unhandled error
  });

  test('requireServer: a failed probe is Network and nothing is written',
      () async {
    var commits = 0;
    final result = await guardWrite(
      () async => commits++,
      probe: () async => false,
      ackWait: quick,
    );
    expect(result.failureOrNull, const Network());
    expect(commits, 0);
  });

  test('requireServer: a passing probe lets the commit run', () async {
    var commits = 0;
    final result = await guardWrite(
      () async => commits++,
      probe: () async => true,
      ackWait: quick,
    );
    expect(result.isSuccess, isTrue);
    expect(commits, 1);
  });

  test('an error thrown by the commit becomes a failure', () async {
    final result = await guardWrite(
      () async => throw StateError('boom'),
      ackWait: quick,
    );
    expect(result.failureOrNull, isA<Unknown>());
  });
}
