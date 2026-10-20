import 'dart:async';

import 'package:family_hub/core/firebase/sync_status.dart';
import 'package:family_hub/core/firebase/tx_runner.dart';
import 'package:family_hub/core/utils/clock.dart';
import 'package:family_hub/core/utils/clock_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('PendingWriteCounter counts while running and also on failure', () async {
    final counter = PendingWriteCounter();
    final gate = Completer<void>();
    final run = counter.track(() => gate.future);
    expect(counter.value, 1);
    gate.complete();
    await run;
    expect(counter.value, 0);

    await expectLater(
      counter.track<void>(() async => throw StateError('x')),
      throwsStateError,
    );
    expect(counter.value, 0);
  });

  test('FakeTxRunner exposes pending writes while a commit is held', () async {
    final tx = FakeTxRunner();
    final gate = Completer<void>();
    tx.holdNextCommit = gate.future;

    final done = tx.runBatch((b) => b.set('a/b', {'v': 1}));
    await Future<void>.delayed(Duration.zero);
    expect(tx.pendingWrites.value, 1);
    expect(tx.store, isEmpty, reason: 'not applied until acknowledged');

    gate.complete();
    await done;
    expect(tx.pendingWrites.value, 0);
    expect(tx.store['a/b'], {'v': 1});
  });

  testWidgets('pending > 10 s is reported as offline; draining clears it',
      (tester) async {
    final counter = PendingWriteCounter();
    final clock = FakeClock(DateTime.utc(2026, 10, 18, 9));
    final container = ProviderContainer(
      overrides: [
        pendingWriteCounterProvider.overrideWithValue(counter),
        clockProvider.overrideWithValue(clock),
      ],
    );
    addTearDown(container.dispose);
    container.listen(syncStatusProvider, (_, __) {});

    expect(container.read(syncStatusProvider), const SyncStatus());

    counter.value = 2;
    var status = container.read(syncStatusProvider);
    expect(status.pendingWrites, 2);
    expect(status.isOffline, isFalse, reason: 'normal short sync is not offline');

    await tester.pump(const Duration(seconds: 11));
    status = container.read(syncStatusProvider);
    expect(status.isOffline, isTrue);
    expect(status.pendingWrites, 2);

    counter.value = 0;
    expect(container.read(syncStatusProvider), const SyncStatus());
  });

  testWidgets('a write acknowledged within the grace period never shows offline',
      (tester) async {
    final counter = PendingWriteCounter();
    final container = ProviderContainer(
      overrides: [pendingWriteCounterProvider.overrideWithValue(counter)],
    );
    addTearDown(container.dispose);
    container.listen(syncStatusProvider, (_, __) {});

    counter.value = 1;
    await tester.pump(const Duration(seconds: 3));
    counter.value = 0;
    await tester.pump(const Duration(seconds: 20));
    expect(container.read(syncStatusProvider), const SyncStatus());
  });
}
