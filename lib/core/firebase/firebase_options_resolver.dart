import 'package:family_hub/app/flavor.dart';
import 'package:family_hub/core/firebase/firebase_options_dev.dart';
import 'package:family_hub/core/firebase/firebase_options_prod.dart';
import 'package:firebase_core/firebase_core.dart';

/// Resolves the correct [FirebaseOptions] for the given [Flavor] and current platform.
FirebaseOptions firebaseOptionsForFlavor(Flavor flavor) {
  switch (flavor) {
    case Flavor.dev:
      return DevFirebaseOptions.currentPlatform;
    case Flavor.prod:
      return ProdFirebaseOptions.currentPlatform;
  }
}
