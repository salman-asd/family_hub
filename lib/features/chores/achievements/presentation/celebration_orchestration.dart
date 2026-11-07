import 'dart:async';
import 'dart:developer' as developer;

import 'package:family_hub/app/routing/session_phase.dart';
import 'package:family_hub/app/routing/session_providers.dart';
import 'package:family_hub/core/utils/clock_provider.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/features/chores/achievements/presentation/celebration_controller.dart';
import 'package:family_hub/features/chores/achievements/presentation/engagement_providers.dart';
import 'package:family_hub/features/chores/availability/presentation/availability_index_provider.dart';
import 'package:family_hub/features/chores/availability/presentation/availability_providers.dart';
import 'package:family_hub/features/chores/occurrences/presentation/occurrence_providers.dart';
import 'package:family_hub/features/family/presentation/family_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final celebrationTodayProvider = StreamProvider.autoDispose<DateKey>((
  ref,
) async* {
  final clock = ref.watch(clockProvider);
  final dateKeys = ref.watch(familyDateKeysProvider);
  while (true) {
    final now = clock.nowUtc();
    final today = dateKeys.dateKeyOf(now);
    yield today;
    await Future<void>.delayed(
      dateKeys.instantOf(today.addDays(1), 0).difference(now),
    );
  }
});

final celebrationOrchestrationProvider = Provider<void>((ref) {
  final phase = ref.watch(sessionPhaseProvider);
  final familyId = ref.watch(currentFamilyIdProvider);
  final memberId = ref.watch(currentUidProvider);
  if (phase != SessionPhase.active || familyId == null || memberId == null) {
    // `app.dart` watches this provider from its build method, and Riverpod 3
    // refuses a provider that notifies another one while it is still building.
    // The notifier is captured now because `ref` may be gone by the time the
    // microtask runs.
    final controller = ref.read(celebrationControllerProvider.notifier);
    unawaited(Future<void>.microtask(controller.reset));
    return;
  }

  final todayState = ref.watch(celebrationTodayProvider);
  if (!todayState.hasValue) return;
  final today = todayState.requireValue;
  final settings = ref.watch(engagementSettingsProvider(familyId));
  final month = ref.watch(monthOccurrencesProvider(today.monthKey));
  final stats = ref.watch(memberStatsProvider(memberId));
  final absences = ref.watch(availabilityProvider);
  if (!settings.hasValue ||
      !month.hasValue ||
      month.requireValue.truncated ||
      !stats.hasValue ||
      !absences.hasValue) {
    return;
  }

  unawaited(
    ref
        .read(celebrationControllerProvider.notifier)
        .observe(
          familyId: familyId,
          memberId: memberId,
          today: today,
          settings: settings.requireValue,
          monthItems: month.requireValue.items,
          stats: stats.requireValue,
          availability: ref.watch(availabilityIndexProvider),
        )
        .catchError((Object error, StackTrace stackTrace) {
          developer.log(
            'Chore celebration observation failed',
            name: 'family_hub',
            error: error,
            stackTrace: stackTrace,
            level: 1000,
          );
        }),
  );
});
