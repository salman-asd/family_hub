import 'dart:async';
import 'dart:developer' as developer;

import 'package:family_hub/app/app.dart';
import 'package:family_hub/app/flavor.dart';
import 'package:family_hub/app/theme/theme_controller.dart';
import 'package:family_hub/core/firebase/firebase_bootstrap.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

void _logError(Object error, StackTrace? stack) {
  developer.log(
    'Uncaught error',
    name: 'family_hub',
    error: error,
    stackTrace: stack,
    level: 1000,
  );
}

/// Single entry point for both flavors. Runs the app inside a ProviderScope
/// with zone, framework and platform error handlers that log uncaught errors.
///
/// [SharedPreferences] is loaded **before** [runApp] so that the theme
/// controller can read persisted values synchronously on the first frame —
/// no flash of the wrong theme.
///
/// Firebase is initialized with the flavor's options and Firestore offline
/// persistence enabled. Passing `--dart-define=USE_EMULATOR=true` connects
/// Auth and Firestore to local emulators.
Future<void> bootstrap(Flavor flavor) async {
  await runZonedGuarded<Future<void>>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.presentError(details);
        _logError(details.exception, details.stack);
      };
      PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
        _logError(error, stack);
        return true;
      };

      // Initialize Firebase and configure Firestore persistence + emulators.
      await initializeFirebase(flavor: flavor);

      // Pre-load SharedPreferences so ThemeController.build() can read it
      // synchronously — avoids a one-frame flash of the wrong theme.
      final prefs = await SharedPreferences.getInstance();

      runApp(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: FamilyHubApp(flavor: flavor),
        ),
      );
    },
    _logError,
  );
}
