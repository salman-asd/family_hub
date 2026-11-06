import 'package:family_hub/app/preference_sync.dart';
import 'package:family_hub/app/push_hook.dart';
import 'package:family_hub/features/chores/achievements/presentation/celebration_orchestration.dart';
import 'package:family_hub/features/chores/achievements/presentation/engagement_providers.dart';
import 'package:family_hub/features/dashboard/presentation/dashboard_providers.dart';
import 'package:family_hub/features/dashboard/presentation/resolved_dashboard_card.dart';
import 'package:family_hub/features/notifications/presentation/inbox_foreground_bridge_provider.dart';
import 'package:family_hub/features/notifications/presentation/lifecycle_observer.dart';
import 'package:family_hub/features/notifications/presentation/reminder_providers.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Widget appTestSideEffectScope({required Widget child}) => ProviderScope(
  overrides: [
    preferenceSyncProvider.overrideWithValue(null),
    dashboardPreferenceSyncProvider.overrideWithValue(null),
    dashboardCardsProvider.overrideWithValue(
      const AsyncData<List<ResolvedDashboardCard>>([]),
    ),
    reminderOrchestrationProvider.overrideWithValue(null),
    reminderLifecycleObserverProvider.overrideWithValue(
      ReminderLifecycleObserver(onResumed: () {}),
    ),
    pushOrchestrationProvider.overrideWithValue(null),
    foregroundNotificationBridgeProvider.overrideWithValue(null),
    statsSyncOrchestrationProvider.overrideWithValue(null),
    celebrationOrchestrationProvider.overrideWithValue(null),
  ],
  child: child,
);
