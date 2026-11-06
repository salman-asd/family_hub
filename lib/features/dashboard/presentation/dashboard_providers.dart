import 'dart:developer' as developer;

import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/core/permissions/permissions.dart';
import 'package:family_hub/core/utils/clock_provider.dart';
import 'package:family_hub/features/dashboard/domain/card_catalog.dart';
import 'package:family_hub/features/dashboard/domain/dashboard_card_spec.dart';
import 'package:family_hub/features/dashboard/domain/dashboard_policy.dart';
import 'package:family_hub/features/dashboard/domain/dashboard_policy_repository.dart';
import 'package:family_hub/features/dashboard/domain/dashboard_prefs.dart';
import 'package:family_hub/features/dashboard/domain/dashboard_prefs_repository.dart';
import 'package:family_hub/features/dashboard/domain/dashboard_resolver.dart';
import 'package:family_hub/features/dashboard/domain/greeting.dart';
import 'package:family_hub/features/dashboard/domain/usecases/save_dashboard_prefs.dart';
import 'package:family_hub/features/dashboard/domain/usecases/update_dashboard_policy.dart';
import 'package:family_hub/features/dashboard/presentation/resolved_dashboard_card.dart';
import 'package:family_hub/features/dashboard/presentation/widgets/approvals_card.dart';
import 'package:family_hub/features/dashboard/presentation/widgets/recent_activity_card.dart';
import 'package:family_hub/features/dashboard/presentation/widgets/upcoming_card.dart';
import 'package:family_hub/features/family/presentation/family_providers.dart';
import 'package:family_hub/features/family/presentation/permission_providers.dart';
import 'package:family_hub/modules/family_module.dart';
import 'package:family_hub/modules/module_providers.dart';
import 'package:family_hub/modules/module_visibility_providers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final dashboardPolicyRepositoryProvider = Provider<DashboardPolicyRepository>(
  (ref) => throw UnimplementedError(
    'dashboardPolicyRepositoryProvider must be overridden in bootstrap.dart.',
  ),
);

final dashboardPrefsStoreProvider = Provider<DashboardPrefsStore>(
  (ref) => throw UnimplementedError(
    'dashboardPrefsStoreProvider must be overridden in bootstrap.dart.',
  ),
);

final dashboardPrefsSyncProvider = Provider<DashboardPrefsSync>(
  (ref) => throw UnimplementedError(
    'dashboardPrefsSyncProvider must be overridden in bootstrap.dart.',
  ),
);

final dashboardPolicyProvider = StreamProvider.autoDispose
    .family<DashboardPolicy, String>((ref, familyId) {
      return ref.watch(dashboardPolicyRepositoryProvider).watchPolicy(familyId);
    });

final dashboardPrefsProvider =
    NotifierProvider<DashboardPrefsController, DashboardPrefs>(
      DashboardPrefsController.new,
    );

final updateDashboardPolicyProvider = Provider<UpdateDashboardPolicy>(
  (ref) => UpdateDashboardPolicy(
    families: ref.watch(familyRepositoryProvider),
    policies: ref.watch(dashboardPolicyRepositoryProvider),
    clock: ref.watch(clockProvider),
    newId: ref.watch(idGeneratorProvider),
  ),
);

final saveDashboardPrefsProvider = Provider<SaveDashboardPrefs>(
  (ref) => SaveDashboardPrefs(
    store: ref.watch(dashboardPrefsStoreProvider),
    sync: ref.watch(dashboardPrefsSyncProvider),
  ),
);

/// Preserves loading and stream errors for consumers instead of treating a
/// failed policy read as the family default.
final dashboardLayoutProvider = Provider<AsyncValue<DashboardLayout>>((ref) {
  final actor = ref.watch(currentActorProvider);
  if (actor == null || !actor.isActive) {
    return AsyncData<DashboardLayout>(
      DashboardLayout(
        visible: const [],
        optionalHidden: const [],
        required: const [],
      ),
    );
  }
  final familyId = ref.watch(currentFamilyIdProvider);
  if (familyId == null) {
    return AsyncData<DashboardLayout>(
      DashboardLayout(
        visible: const [],
        optionalHidden: const [],
        required: const [],
      ),
    );
  }

  final policy = ref.watch(dashboardPolicyProvider(familyId));
  final prefs = ref.watch(dashboardPrefsProvider);
  final modules = ref.watch(moduleFlagsProvider);
  final settings = ref.watch(permissionSettingsProvider);
  return policy.whenData(
    (value) => DashboardResolver.resolve(
      role: actor.role,
      policy: value,
      prefs: prefs,
      modulesEnabled: <String, bool>{
        'bazar': modules.isEnabled('bazar'),
        'chores': modules.isEnabled('chores'),
      },
      can: (permission) => permission == Permission.verifyChore
          ? PermissionPolicy.canVerifyOthers(actor, settings: settings)
          : PermissionPolicy.can(actor, permission, settings: settings),
    ),
  );
});

final dashboardCardsProvider =
    Provider<AsyncValue<List<ResolvedDashboardCard>>>((ref) {
      final layout = ref.watch(dashboardLayoutProvider);
      final modules = ref.watch(visibleModulesProvider);
      return layout.whenData((value) {
        final specs = <DashboardCardSpec<DashboardCardBuilder>>[
          ..._coreDashboardCardSpecs,
          for (final module in modules) ...module.dashboardCardSpecs,
        ];
        final byId = <String, DashboardCardSpec<DashboardCardBuilder>>{};
        for (final spec in specs) {
          if (CardCatalog.find(spec.id) == null) {
            _logSkippedCard(spec.id, 'not in CardCatalog');
            continue;
          }
          if (byId.containsKey(spec.id)) {
            _logSkippedCard(spec.id, 'duplicate card spec');
            continue;
          }
          byId[spec.id] = spec;
        }

        final cards = <ResolvedDashboardCard>[];
        for (final resolved in value.visible) {
          final spec = byId[resolved.definition.id];
          if (spec == null) {
            _logSkippedCard(resolved.definition.id, 'no card spec');
            continue;
          }
          cards.add(ResolvedDashboardCard(resolved: resolved, spec: spec));
        }
        return List<ResolvedDashboardCard>.unmodifiable(cards);
      });
    });

final dashboardGreetingProvider = Provider<Greeting>((ref) {
  final clock = ref.watch(clockProvider);
  final dateKeys = ref.watch(familyDateKeysProvider);
  return GreetingForTime.atMinutes(dateKeys.minutesOfDayOf(clock.nowUtc()));
});

final List<DashboardCardSpec<DashboardCardBuilder>> _coreDashboardCardSpecs =
    <DashboardCardSpec<DashboardCardBuilder>>[
      DashboardCardSpec<DashboardCardBuilder>(
        id: 'approvals',
        builder: (_, _) => const ApprovalsCard(),
      ),
      DashboardCardSpec<DashboardCardBuilder>(
        id: 'upcoming',
        builder: (_, _) => const UpcomingCard(),
      ),
      DashboardCardSpec<DashboardCardBuilder>(
        id: 'recent_activity',
        builder: (_, _) => const RecentActivityCard(),
      ),
    ];

void _logSkippedCard(String id, String reason) {
  if (!kDebugMode) return;
  developer.log(
    'Dashboard card "$id" skipped: $reason.',
    name: 'family_hub.dashboard',
  );
}

class DashboardPrefsController extends Notifier<DashboardPrefs> {
  @override
  DashboardPrefs build() {
    final uid = ref.watch(currentUidProvider);
    return uid == null
        ? DashboardPrefs.defaults
        : ref.watch(dashboardPrefsStoreProvider).load(uid);
  }

  Future<Result<void>> save(DashboardPrefs next) async {
    final uid = ref.read(currentUidProvider);
    if (uid == null) return const Failure<void>(NoCurrentUser());

    state = next;
    final result = await ref
        .read(saveDashboardPrefsProvider)
        .call(uid: uid, prefs: next);
    state = ref.read(dashboardPrefsStoreProvider).load(uid);
    return result;
  }

  Future<Result<void>> applyRemote(String uid, DashboardPrefs remote) async {
    if (ref.read(currentUidProvider) != uid) {
      return const Failure<void>(PermissionDenied());
    }
    final saved = await ref.read(dashboardPrefsStoreProvider).save(uid, remote);
    final failure = saved.failureOrNull;
    if (failure != null) return Failure<void>(failure);
    state = remote;
    return const Success<void>(null);
  }
}
