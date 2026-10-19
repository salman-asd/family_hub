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

/// True when [options] still carry the scaffold placeholder keys/app ids that
/// `flutterfire configure` is meant to replace.
bool hasPlaceholderCredentials(FirebaseOptions options) {
  return options.apiKey.contains('placeholder') ||
      options.appId.contains('placeholder');
}

/// Thrown at startup when a real (non-emulator) run would use placeholder keys.
class FirebaseNotConfiguredException implements Exception {
  const FirebaseNotConfiguredException(this.flavor);

  final Flavor flavor;

  @override
  String toString() =>
      'Firebase is not configured for the ${flavor.name} flavor: the options '
      'still contain placeholder keys. Run `flutterfire configure` for '
      'project familyhub-${flavor.name} (see firebase/README.md).';
}

/// Fails fast on placeholder credentials unless running against the emulator.
void assertFirebaseConfigured(
  Flavor flavor,
  FirebaseOptions options, {
  required bool useEmulator,
}) {
  if (!useEmulator && hasPlaceholderCredentials(options)) {
    throw FirebaseNotConfiguredException(flavor);
  }
}
