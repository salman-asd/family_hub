import 'dart:async';

import 'package:family_hub/app/theme/theme_controller.dart' hide unawaited;
import 'package:family_hub/core/localization/locale_controller.dart';
import 'package:family_hub/features/auth/presentation/auth_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Keeps theme and language in step with `users/{uid}.preferences`.
///
/// * At startup the **local** value wins (it is already on screen).
/// * After sign-in the **remote** value is applied once per sign-in.  If the
///   account has none yet, the local value is pushed up instead.
/// * Later local changes are pushed by the controllers themselves.
///
/// Watched from `FamilyHubApp` purely for its side effect.
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

  // Only start once the email is verified (H5): every write except the owner's
  // own profile is denied by the rules until then, so an early push would just
  // be rejected.
  ref.listen<String?>(
    authStateProvider.select((v) {
      final user = v.value;
      return user != null && user.emailVerified ? user.uid : null;
    }),
    (_, uid) => uid == null ? stop() : start(),
    fireImmediately: true,
  );
  ref.onDispose(stop);
});
