import 'package:family_hub/app/preference_sync.dart';
import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/features/dashboard/domain/dashboard_prefs.dart';
import 'package:family_hub/features/dashboard/domain/dashboard_prefs_repository.dart';
import 'package:family_hub/features/dashboard/presentation/dashboard_providers.dart';
import 'package:family_hub/features/family/presentation/family_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'local preferences seed an account with no remote dashboard value',
    () async {
      final local = DashboardPrefs(order: ['upcoming']);
      final store = _Store()..values['user'] = local;
      final sync = _Sync(null);
      final container = ProviderContainer(
        overrides: [
          currentUidProvider.overrideWithValue('user'),
          dashboardPrefsStoreProvider.overrideWithValue(store),
          dashboardPrefsSyncProvider.overrideWithValue(sync),
        ],
      );
      final subscription = container.listen(
        dashboardPreferenceSyncProvider,
        (_, _) {},
        fireImmediately: true,
      );
      addTearDown(() {
        subscription.close();
        container.dispose();
      });

      await Future<void>.delayed(Duration.zero);
      expect(sync.pushed, local);
    },
  );

  test(
    'the first remote snapshot replaces and persists the local layout',
    () async {
      final local = DashboardPrefs(order: ['upcoming']);
      final remote = DashboardPrefs(order: ['chores_today']);
      final store = _Store()..values['user'] = local;
      final sync = _Sync(remote);
      final container = ProviderContainer(
        overrides: [
          currentUidProvider.overrideWithValue('user'),
          dashboardPrefsStoreProvider.overrideWithValue(store),
          dashboardPrefsSyncProvider.overrideWithValue(sync),
        ],
      );
      final subscription = container.listen(
        dashboardPreferenceSyncProvider,
        (_, _) {},
        fireImmediately: true,
      );
      addTearDown(() {
        subscription.close();
        container.dispose();
      });

      await Future<void>.delayed(Duration.zero);
      expect(container.read(dashboardPrefsProvider), remote);
      expect(store.values['user'], remote);
      expect(sync.pushed, isNull);
    },
  );
}

final class _Store implements DashboardPrefsStore {
  final Map<String, DashboardPrefs> values = <String, DashboardPrefs>{};

  @override
  DashboardPrefs load(String uid) => values[uid] ?? DashboardPrefs.defaults;

  @override
  Future<Result<void>> save(String uid, DashboardPrefs prefs) async {
    values[uid] = prefs;
    return const Success<void>(null);
  }
}

final class _Sync implements DashboardPrefsSync {
  _Sync(this.remote);

  final DashboardPrefs? remote;
  DashboardPrefs? pushed;

  @override
  Future<Result<void>> push(String uid, DashboardPrefs prefs) async {
    pushed = prefs;
    return const Success<void>(null);
  }

  @override
  Stream<DashboardPrefs?> watch(String uid) =>
      Stream<DashboardPrefs?>.value(remote);
}
