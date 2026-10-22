import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:family_hub/app/flavor.dart';
import 'package:family_hub/core/firebase/cache_wipe.dart';
import 'package:family_hub/core/firebase/firebase_options_resolver.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Initializes Firebase, Firestore persistence, and emulator routing.
///
/// [prefs] (H9): when the "wipe on next start" flag is raised, the on-disk
/// Firestore cache is cleared here, BEFORE anything reads or writes Firestore.
Future<void> initializeFirebase({
  required Flavor flavor,
  bool? useEmulator,
  SharedPreferences? prefs,
}) async {
  final shouldEmulate =
      useEmulator ??
      const bool.fromEnvironment('USE_EMULATOR', defaultValue: false);

  if (Firebase.apps.isEmpty) {
    final options = firebaseOptionsForFlavor(flavor);
    assertFirebaseConfigured(flavor, options, useEmulator: shouldEmulate);
    await Firebase.initializeApp(options: options);
  }

  // Configure Firestore offline persistence (enabled by default on mobile platforms,
  // explicit settings ensure persistence is active).
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );

  if (shouldEmulate) {
    final host = defaultTargetPlatform == TargetPlatform.android
        ? '10.0.2.2'
        : '127.0.0.1';

    FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
    await FirebaseAuth.instance.useAuthEmulator(host, 9099);
  }

  if (prefs != null) {
    await CacheWipe.wipeIfRequested(
      prefs,
      FirebaseFirestore.instance.clearPersistence,
    );
  }
}
