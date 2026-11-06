import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/features/dashboard/domain/dashboard_refresh.dart';
import 'package:family_hub/features/dashboard/domain/greeting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GreetingForTime', () {
    test('selects the day part at its boundaries', () {
      expect(GreetingForTime.atMinutes(0), Greeting.morning);
      expect(GreetingForTime.atMinutes(11 * 60 + 59), Greeting.morning);
      expect(GreetingForTime.atMinutes(12 * 60), Greeting.afternoon);
      expect(GreetingForTime.atMinutes(17 * 60 + 59), Greeting.afternoon);
      expect(GreetingForTime.atMinutes(18 * 60), Greeting.evening);
      expect(GreetingForTime.atMinutes(23 * 60 + 59), Greeting.evening);
    });

    test('rejects a time outside the day', () {
      expect(() => GreetingForTime.atMinutes(-1), throwsRangeError);
      expect(() => GreetingForTime.atMinutes(24 * 60), throwsRangeError);
    });
  });

  test(
    'dashboard refresh preserves order and returns ensure failure',
    () async {
      final calls = <String>[];
      const failure = Network();

      final result = await const DashboardRefresh().run(
        ensureOccurrences: () async {
          calls.add('ensure');
          return failure;
        },
        invalidateOneShotProviders: () => calls.add('invalidate'),
        replanReminders: () async => calls.add('reminders'),
        syncMemberStats: () async => calls.add('stats'),
      );

      expect(result, same(failure));
      expect(calls, ['ensure', 'invalidate', 'reminders', 'stats']);
    },
  );
}
