import 'package:family_hub/app/routing/session_phase.dart';
import 'package:family_hub/app/routing/session_providers.dart';
import 'package:family_hub/core/utils/clock.dart';
import 'package:family_hub/core/utils/clock_provider.dart';
import 'package:family_hub/features/chores/achievements/domain/celebration_state.dart';
import 'package:family_hub/features/chores/achievements/presentation/celebration_controller.dart';
import 'package:family_hub/features/chores/achievements/presentation/celebration_orchestration.dart';
import 'package:family_hub/features/family/presentation/family_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// `app.dart` watches this hook from its own build method and the shared test
/// scope replaces it with `overrideWithValue(null)`, so its body had never run
/// under a widget test.  On a device a signed-out launch threw
/// "Providers are not allowed to modify other providers during their
/// initialization" and the app stopped on a red screen.
void main() {
  testWidgets(
    'a signed-out session builds the hook without editing the controller mid-build',
    (tester) async {
      ProviderContainer? container;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            clockProvider.overrideWithValue(
              FakeClock(DateTime.utc(2026, 11, 7, 9)),
            ),
            sessionPhaseProvider.overrideWithValue(SessionPhase.signedOut),
            currentUidProvider.overrideWithValue(null),
            currentFamilyIdProvider.overrideWithValue(null),
          ],
          child: MaterialApp(
            home: Consumer(
              builder: (context, ref, _) {
                container = ProviderScope.containerOf(context);
                ref.watch(celebrationOrchestrationProvider);
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(
        container!.read(celebrationControllerProvider),
        isA<CelebrationNone>(),
        reason:
            'a stale celebration must not survive into a signed-out session',
      );

      await tester.pump();

      expect(tester.takeException(), isNull);
    },
  );
}
