import 'package:family_hub/app/flavor.dart';
import 'package:family_hub/core/firebase/firebase_options_dev.dart';
import 'package:family_hub/core/firebase/firebase_options_prod.dart';
import 'package:family_hub/core/firebase/firebase_options_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FirebaseOptions', () {
    test('dev and prod options have distinct project IDs', () {
      expect(DevFirebaseOptions.projectId, 'familyhub-dev');
      expect(ProdFirebaseOptions.projectId, 'familyhub-prod');
    });

    test('resolver returns platform options for each flavor', () {
      final devOptions = firebaseOptionsForFlavor(Flavor.dev);
      expect(devOptions.projectId, 'familyhub-dev');

      final prodOptions = firebaseOptionsForFlavor(Flavor.prod);
      expect(prodOptions.projectId, 'familyhub-prod');
    });
  });
}
