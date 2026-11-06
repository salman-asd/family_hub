import 'dart:async';

import 'package:family_hub/features/chores/achievements/presentation/stats_sync_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'stats sync controller serializes and coalesces overlapping triggers',
    () async {
      final firstRun = Completer<void>();
      final secondRunStarted = Completer<void>();
      final secondRun = Completer<void>();
      var calls = 0;
      var activeCalls = 0;
      var maximumActiveCalls = 0;
      final controller = StatsSyncController(
        sync: () async {
          calls++;
          activeCalls++;
          if (activeCalls > maximumActiveCalls) {
            maximumActiveCalls = activeCalls;
          }
          try {
            if (calls == 1) {
              await firstRun.future;
            } else {
              secondRunStarted.complete();
              await secondRun.future;
            }
          } finally {
            activeCalls--;
          }
        },
        onError: (error, stackTrace) => fail('$error\n$stackTrace'),
      );
      final now = DateTime.utc(2026, 11, 1);

      controller.onResumed(now);
      await Future<void>.delayed(Duration.zero);
      controller.onResumed(now.add(const Duration(minutes: 11)));
      controller.onResumed(now.add(const Duration(minutes: 22)));

      firstRun.complete();
      await secondRunStarted.future;
      expect(calls, 2);
      expect(maximumActiveCalls, 1);

      secondRun.complete();
      await Future<void>.delayed(Duration.zero);
      controller.dispose();

      expect(calls, 2);
      expect(activeCalls, 0);
    },
  );
}
