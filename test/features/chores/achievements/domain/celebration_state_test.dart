import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/features/chores/achievements/domain/celebration_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final today = DateKey(2026, 11, 6);
  final sessionStart = DateTime.utc(2026, 11, 6, 8);

  CelebrationInput input({
    int done = 3,
    int total = 3,
    Duration? age = const Duration(minutes: 10),
    bool sawIncomplete = false,
    DateKey? localDate,
    DateKey? statsDate,
    bool engagement = true,
    bool celebration = true,
  }) => CelebrationInput(
    todayKey: today,
    mineToday: MineToday(
      done: done,
      total: total,
      lastCompletedAt: age == null ? null : sessionStart.add(age),
    ),
    sessionStartedAt: sessionStart,
    sawIncompleteThisSession: sawIncomplete,
    lastCelebratedLocal: localDate,
    lastCelebratedStats: statsDate,
    engagementEnabled: engagement,
    celebrationEnabled: celebration,
    nowMinusLastCompletion: age,
  );

  test('celebration state table covers cold starts, transitions and guards', () {
    final cases =
        <({String name, CelebrationInput input, CelebrationDecision expected})>[
          (
            name: 'last of three completes in this session',
            input: input(sawIncomplete: true, age: const Duration(hours: 3)),
            expected: CelebrationDecision.celebrate,
          ),
          (
            name: 'cold start completed ten minutes ago',
            input: input(),
            expected: CelebrationDecision.celebrate,
          ),
          (
            name: 'cold start completed five hours ago',
            input: input(age: const Duration(hours: 5)),
            expected: CelebrationDecision.quietDone,
          ),
          (
            name: 'local device already celebrated today',
            input: input(localDate: today, sawIncomplete: true),
            expected: CelebrationDecision.none,
          ),
          (
            name: 'another device already celebrated today',
            input: input(statsDate: today),
            expected: CelebrationDecision.quietDone,
          ),
          (
            name: 'zero chores',
            input: input(done: 0, total: 0),
            expected: CelebrationDecision.none,
          ),
          (
            name: 'incomplete chores',
            input: input(done: 2, total: 3, sawIncomplete: true),
            expected: CelebrationDecision.none,
          ),
          (
            name: 'engagement disabled',
            input: input(engagement: false),
            expected: CelebrationDecision.none,
          ),
          (
            name: 'celebration setting disabled',
            input: input(celebration: false),
            expected: CelebrationDecision.none,
          ),
          (
            name: 'exactly thirty minutes is recent',
            input: input(age: CelebrationEngine.recentCompletionWindow),
            expected: CelebrationDecision.celebrate,
          ),
          (
            name: 'just over thirty minutes is quiet',
            input: input(
              age:
                  CelebrationEngine.recentCompletionWindow +
                  const Duration(microseconds: 1),
            ),
            expected: CelebrationDecision.quietDone,
          ),
          (
            name:
                'a completion observed after an incomplete state is celebrated',
            input: input(age: const Duration(days: 1), sawIncomplete: true),
            expected: CelebrationDecision.celebrate,
          ),
          (
            name: 'no completion timestamp is quiet on cold start',
            input: input(age: null),
            expected: CelebrationDecision.quietDone,
          ),
          (
            name: 'future completion time is not treated as recent',
            input: input(age: const Duration(seconds: -1)),
            expected: CelebrationDecision.quietDone,
          ),
          (
            name: 'older local date does not suppress today',
            input: input(localDate: today.addDays(-1)),
            expected: CelebrationDecision.celebrate,
          ),
          (
            name: 'older stats date does not suppress today',
            input: input(statsDate: today.addDays(-1)),
            expected: CelebrationDecision.celebrate,
          ),
          (
            name: 'stats date suppresses animation even after incomplete state',
            input: input(statsDate: today, sawIncomplete: true),
            expected: CelebrationDecision.quietDone,
          ),
          (
            name: 'local date takes precedence over incomplete state',
            input: input(localDate: today, sawIncomplete: true),
            expected: CelebrationDecision.none,
          ),
          (
            name: 'no chores while celebration setting is off',
            input: input(done: 0, total: 0, celebration: false),
            expected: CelebrationDecision.none,
          ),
          (
            name: 'a partial list cannot celebrate',
            input: input(done: 1, total: 2, age: Duration.zero),
            expected: CelebrationDecision.none,
          ),
          (
            name: 'an empty list never becomes quiet done',
            input: input(done: 0, total: 0, age: const Duration(hours: 5)),
            expected: CelebrationDecision.none,
          ),
        ];

    for (final row in cases) {
      expect(
        CelebrationEngine.decide(row.input),
        row.expected,
        reason: row.name,
      );
    }
  });

  test('new family day uses a different celebration key', () {
    expect(today.addDays(1), isNot(today));
  });
}
