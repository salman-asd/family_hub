import 'dart:async';
import 'dart:developer' as developer;

import 'package:family_hub/app/theme/theme_controller.dart' hide unawaited;
import 'package:family_hub/core/localization/locale_controller.dart';
import 'package:family_hub/features/auth/presentation/auth_providers.dart';
import 'package:family_hub/features/dashboard/presentation/dashboard_providers.dart';
import 'package:family_hub/features/dashboard/domain/dashboard_prefs.dart';
import 'package:family_hub/features/family/presentation/family_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Keeps theme and language in step with `users/{uid}.preferences`.
///
/// Local preferences are available immediately. After a verified sign-in the
/// remote value is applied once; if the account has none yet, the local value
/// is pushed up instead.
final preferenceSyncProvider = Provider<void>((ref) {
  StreamSubscription<Object?>? themeSub;
  StreamSubscription<Object?>? localeSub;

  void stop() {
    unawaited(themeSub?.cancel());
    unawaited(localeSub?.cancel());
    themeSub = null;
    localeSub = null;
  }

  void start() {
    stop();
    var themeApplied = false;
    var localeApplied = false;

    themeSub = ref.read(themePreferenceSyncProvider).watch().listen((remote) {
      if (themeApplied) return;
      themeApplied = true;
      if (remote == null) {
        unawaited(
          ref
              .read(themePreferenceSyncProvider)
              .push(ref.read(themeControllerProvider)),
        );
      } else {
        unawaited(
          ref.read(themeControllerProvider.notifier).applyRemote(remote),
        );
      }
    });

    localeSub = ref.read(localePreferenceSyncProvider).watch().listen((remote) {
      if (localeApplied) return;
      localeApplied = true;
      if (remote == null) {
        unawaited(
          ref
              .read(localePreferenceSyncProvider)
              .push(ref.read(localeControllerProvider)),
        );
      } else {
        unawaited(
          ref.read(localeControllerProvider.notifier).applyRemote(remote),
        );
      }
    });
  }

  // The existing theme/locale adapters require verified email for their
  // writes. Dashboard preferences use the owner-only users/{uid} rule.
  ref.listen<String?>(
    authStateProvider.select((value) {
      final user = value.value;
      return user != null && user.emailVerified ? user.uid : null;
    }),
    (_, uid) => uid == null ? stop() : start(),
    fireImmediately: true,
  );
  ref.onDispose(stop);
});

/// Applies dashboard preferences once for each signed-in user. Local state is
/// keyed by uid and therefore remains visible while the first remote snapshot
/// is loading.
final dashboardPreferenceSyncProvider = Provider<void>((ref) {
  StreamSubscription<DashboardPrefs?>? subscription;
  var disposed = false;

  void stop() {
    unawaited(subscription?.cancel());
    subscription = null;
  }

  void start(String? uid) {
    stop();
    if (uid == null) return;

    var applied = false;
    final sync = ref.read(dashboardPrefsSyncProvider);
    subscription = sync.watch(uid).listen(
      (remote) {
        if (disposed || applied || ref.read(currentUidProvider) != uid) return;
        applied = true;
        unawaited(subscription?.cancel());
        subscription = null;

        if (remote == null) {
          unawaited(
            sync.push(uid, ref.read(dashboardPrefsProvider)).then((result) {
              _logFailure(result.failureOrNull, 'seed');
            }),
          );
        } else {
          unawaited(
            ref
                .read(dashboardPrefsProvider.notifier)
                .applyRemote(uid, remote)
                .then((result) {
                  _logFailure(result.failureOrNull, 'apply remote');
                }),
          );
        }
      },
      onError: (Object error, StackTrace stack) => developer.log(
        'Could not read dashboard preferences',
        name: 'family_hub',
        error: error,
        stackTrace: stack,
        level: 1000,
      ),
    );
  }

  ref.listen<String?>(
    currentUidProvider,
    (_, uid) => start(uid),
    fireImmediately: true,
  );
  ref.onDispose(() {
    disposed = true;
    stop();
  });
});

void _logFailure(Object? failure, String action) {
  if (failure == null) return;
  developer.log(
    'Could not $action dashboard preferences',
    name: 'family_hub',
    error: failure,
    level: 1000,
  );
}
