import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for the `prod` flavor.
///
/// Generated / structured for Firebase project `familyhub-prod`.
/// Replace placeholder API keys and app IDs when the live Firebase project
/// is provisioned with FlutterFire CLI.
class ProdFirebaseOptions {
  static const String projectId = 'familyhub-prod';

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
          'ProdFirebaseOptions have not been configured for linux.',
        );
      default:
        throw UnsupportedError(
          'ProdFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSy-prod-web-placeholder-key',
    appId: '1:200000000002:web:prodplaceholder00002',
    messagingSenderId: '200000000002',
    projectId: projectId,
    authDomain: '$projectId.firebaseapp.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSy-prod-android-placeholder-key',
    appId: '1:200000000002:android:prodplaceholder00002',
    messagingSenderId: '200000000002',
    projectId: projectId,
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSy-prod-ios-placeholder-key',
    appId: '1:200000000002:ios:prodplaceholder00002',
    messagingSenderId: '200000000002',
    projectId: projectId,
    iosBundleId: 'com.familyhub.familyHub',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSy-prod-macos-placeholder-key',
    appId: '1:200000000002:ios:prodplaceholder00002',
    messagingSenderId: '200000000002',
    projectId: projectId,
    iosBundleId: 'com.familyhub.familyHub',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSy-prod-windows-placeholder-key',
    appId: '1:200000000002:web:prodplaceholder00002',
    messagingSenderId: '200000000002',
    projectId: projectId,
    authDomain: '$projectId.firebaseapp.com',
  );
}
