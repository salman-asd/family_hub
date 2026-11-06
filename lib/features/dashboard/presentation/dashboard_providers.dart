import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/core/permissions/permissions.dart';
import 'package:family_hub/core/utils/clock_provider.dart';
import 'package:family_hub/features/dashboard/domain/dashboard_policy.dart';
import 'package:family_hub/features/dashboard/domain/dashboard_policy_repository.dart';
import 'package:family_hub/features/dashboard/domain/dashboard_prefs.dart';
import 'package:family_hub/features/dashboard/domain/dashboard_prefs_repository.dart';
import 'package:family_hub/features/dashboard/domain/dashboard_resolver.dart';
import 'package:family_hub/features/dashboard/domain/usecases/save_dashboard_prefs.dart';
import 'package:family_hub/features/dashboard/domain/usecases/update_dashboard_policy.dart';
import 'package:family_hub/features/family/presentation/family_providers.dart';
import 'package:family_hub/features/family/presentation/permission_providers.dart';
import 'package:family_hub/modules/module_providers.dart';
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
