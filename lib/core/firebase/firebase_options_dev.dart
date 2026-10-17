import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for the `dev` flavor.
///
/// Generated / structured for Firebase project `familyhub-dev`.
/// Replace placeholder API keys and app IDs when the live Firebase project
/// is provisioned with FlutterFire CLI.
class DevFirebaseOptions {
  static const String projectId = 'familyhub-dev';

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DevFirebaseOptions have not been configured for linux.',
        );
      default:
        throw UnsupportedError(
          'DevFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSy-dev-web-placeholder-key',
    appId: '1:100000000001:web:devplaceholder00001',
    messagingSenderId: '100000000001',
    projectId: projectId,
    authDomain: '$projectId.firebaseapp.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSy-dev-android-placeholder-key',
    appId: '1:100000000001:android:devplaceholder00001',
    messagingSenderId: '100000000001',
    projectId: projectId,
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSy-dev-ios-placeholder-key',
    appId: '1:100000000001:ios:devplaceholder00001',
    messagingSenderId: '100000000001',
    projectId: projectId,
    iosBundleId: 'com.familyhub.familyHub.dev',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSy-dev-macos-placeholder-key',
    appId: '1:100000000001:ios:devplaceholder00001',
    messagingSenderId: '100000000001',
    projectId: projectId,
    iosBundleId: 'com.familyhub.familyHub.dev',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSy-dev-windows-placeholder-key',
    appId: '1:100000000001:web:devplaceholder00001',
    messagingSenderId: '100000000001',
    projectId: projectId,
    authDomain: '$projectId.firebaseapp.com',
  );
}
