import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/features/auth/data/auth_failure_mapper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';

/// Every backend code Step 7 names must map to a specific [AppFailure].
///
/// The roadmap lists: invalid-credential, user-not-found, email-already-in-use,
/// weak-password, network-request-failed, too-many-requests, "anything else ->
/// Unknown".  The extra rows below cover codes the SDK still emits from older
/// flows, so a device on an older Firebase Auth build behaves the same.
void main() {
  FirebaseAuthException errorWith(String code) =>
      FirebaseAuthException(code: code);

  group('mapFirebaseAuthException', () {
    test('invalid-credential -> InvalidCredentials', () {
      expect(
        mapFirebaseAuthException(errorWith('invalid-credential')),
        isA<InvalidCredentials>(),
      );
    });

    test('invalid-login-credentials -> InvalidCredentials', () {
      expect(
        mapFirebaseAuthException(errorWith('invalid-login-credentials')),
        isA<InvalidCredentials>(),
      );
    });

    test('wrong-password -> InvalidCredentials', () {
      // The pre-5.x code for the same situation; Firebase still emits it from
      // some flows, and it must not fall through to a generic message.
      expect(
        mapFirebaseAuthException(errorWith('wrong-password')),
        isA<InvalidCredentials>(),
      );
    });

    test('user-not-found -> UserNotFound', () {
      expect(
        mapFirebaseAuthException(errorWith('user-not-found')),
        isA<UserNotFound>(),
      );
    });

    test('email-already-in-use -> EmailAlreadyInUse', () {
      expect(
        mapFirebaseAuthException(errorWith('email-already-in-use')),
        isA<EmailAlreadyInUse>(),
      );
    });

    test('weak-password -> WeakPassword', () {
      expect(
        mapFirebaseAuthException(errorWith('weak-password')),
        isA<WeakPassword>(),
      );
    });

    test('network-request-failed -> Network', () {
      expect(
        mapFirebaseAuthException(errorWith('network-request-failed')),
        isA<Network>(),
      );
    });

    test('too-many-requests -> TooManyRequests', () {
      expect(
        mapFirebaseAuthException(errorWith('too-many-requests')),
        isA<TooManyRequests>(),
      );
    });

    test('user-disabled -> UserDisabled', () {
      expect(
        mapFirebaseAuthException(errorWith('user-disabled')),
        isA<UserDisabled>(),
      );
    });

    test('requires-recent-login -> RequiresRecentLogin', () {
      expect(
        mapFirebaseAuthException(errorWith('requires-recent-login')),
        isA<RequiresRecentLogin>(),
      );
    });

    test('invalid-email -> InvalidEmail', () {
      expect(
        mapFirebaseAuthException(errorWith('invalid-email')),
        isA<InvalidEmail>(),
      );
    });

    test('an unknown code -> Unknown carrying the cause', () {
      final error = errorWith('something-brand-new');
      final mapped = mapFirebaseAuthException(error);

      expect(mapped, isA<Unknown>());
      // The cause is preserved so logs and crash reports keep the raw code.
      expect((mapped as Unknown).cause, same(error));
    });

    test('transport codes all collapse to Network', () {
      for (final code in [
        'network-request-failed',
        'internal-error',
        'timeout',
      ]) {
        expect(
          mapFirebaseAuthException(errorWith(code)),
          isA<Network>(),
          reason: '$code should be a Network failure',
        );
      }
    });
  });
}
