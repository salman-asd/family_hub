import 'package:family_hub/app/flavor.dart';
import 'package:family_hub/core/firebase/firebase_options_dev.dart';
import 'package:family_hub/core/firebase/firebase_options_prod.dart';
import 'package:family_hub/core/firebase/firebase_options_resolver.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FirebaseOptions', () {
    test('both flavors resolve to the one Firebase project', () {
      expect(DevFirebaseOptions.projectId, 'familyhub-app-ai');
      expect(ProdFirebaseOptions.projectId, 'familyhub-app-ai');
    });

    test('resolver returns platform options for each flavor', () {
      final devOptions = firebaseOptionsForFlavor(Flavor.dev);
      expect(devOptions.projectId, 'familyhub-app-ai');

      final prodOptions = firebaseOptionsForFlavor(Flavor.prod);
      expect(prodOptions.projectId, 'familyhub-app-ai');
    });
  });

  group('placeholder guard', () {
    const placeholder = FirebaseOptions(
      apiKey: 'AIzaSy-dev-android-placeholder-key',
      appId: '1:1:android:devplaceholder00001',
      messagingSenderId: '1',
      projectId: 'familyhub-app-ai',
    );
    const real = FirebaseOptions(
      apiKey: 'AIzaSyRealLookingKey',
      appId: '1:1:android:abc123',
      messagingSenderId: '1',
      projectId: 'familyhub-app-ai',
    );

    test('detects placeholder credentials', () {
      expect(hasPlaceholderCredentials(placeholder), isTrue);
      expect(hasPlaceholderCredentials(real), isFalse);
    });

    test('throws for placeholders unless the emulator is used', () {
      expect(
        () => assertFirebaseConfigured(
          Flavor.prod,
          placeholder,
          useEmulator: false,
        ),
        throwsA(isA<FirebaseNotConfiguredException>()),
      );
      expect(
        () => assertFirebaseConfigured(
          Flavor.prod,
          placeholder,
          useEmulator: true,
        ),
        returnsNormally,
      );
      expect(
        () => assertFirebaseConfigured(Flavor.dev, real, useEmulator: false),
        returnsNormally,
      );
    });
  });
}
