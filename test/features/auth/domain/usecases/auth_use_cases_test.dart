import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/features/auth/domain/app_user.dart';
import 'package:family_hub/features/auth/domain/usecases/auth_use_cases.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/fake_auth_repository.dart';

void main() {
  late FakeAuthRepository repository;

  setUp(() => repository = FakeAuthRepository());
  tearDown(() => repository.dispose());

  group('SignUp', () {
    test(
      'validates locally and never calls the backend for a bad email',
      () async {
        final result = await SignUp(repository)(
          email: 'nope',
          password: 'longenough',
        );

        expect(result.failureOrNull, isA<Validation>());
        expect(
          repository.calls,
          isEmpty,
          reason: 'a bad form must not cost a round trip (Step 7)',
        );
      },
    );

    test(
      'validates locally and never calls the backend for a short password',
      () async {
        final result = await SignUp(repository)(
          email: 'a@b.co',
          password: 'short',
        );

        expect(
          result.failureOrNull,
          const Validation('password', 'password_too_short'),
        );
        expect(repository.calls, isEmpty);
      },
    );

    test('trims the email it sends to the backend', () async {
      await SignUp(repository)(email: '  a@b.co  ', password: 'longenough');
      expect(repository.lastEmail, 'a@b.co');
    });

    test('does not trim the password', () async {
      await SignUp(repository)(email: 'a@b.co', password: '  longenough  ');
      expect(repository.lastPassword, '  longenough  ');
    });

    test('returns the created (unverified) user', () async {
      final result = await SignUp(repository)(
        email: 'a@b.co',
        password: 'longenough',
      );

      expect(result.valueOrNull?.email, 'a@b.co');
      expect(result.valueOrNull?.emailVerified, isFalse);
    });

    test('passes a backend failure through unchanged', () async {
      repository.signUpFailure = const EmailAlreadyInUse();

      final result = await SignUp(repository)(
        email: 'a@b.co',
        password: 'longenough',
      );

      expect(result.failureOrNull, isA<EmailAlreadyInUse>());
    });
  });

  group('SignIn', () {
    test('sends the trimmed email and the raw password', () async {
      await SignIn(repository)(email: ' a@b.co ', password: ' longenough ');

      expect(repository.lastEmail, 'a@b.co');
      expect(repository.lastPassword, ' longenough ');
    });

    test('returns the signed-in user', () async {
      final result = await SignIn(repository)(
        email: 'a@b.co',
        password: 'longenough',
      );
      expect(result.valueOrNull?.email, 'a@b.co');
    });

    test('surfaces a wrong password as InvalidCredentials', () async {
      repository.signInFailure = const InvalidCredentials();

      final result = await SignIn(repository)(
        email: 'a@b.co',
        password: 'longenough',
      );

      expect(result.failureOrNull, isA<InvalidCredentials>());
    });

    test('surfaces an offline backend as Network', () async {
      repository.signInFailure = const Network();

      final result = await SignIn(repository)(
        email: 'a@b.co',
        password: 'longenough',
      );

      expect(result.failureOrNull, isA<Network>());
    });

    test('rejects an invalid email before touching the backend', () async {
      final result = await SignIn(repository)(
        email: 'bad',
        password: 'longenough',
      );

      expect(result.failureOrNull, isA<Validation>());
      expect(repository.calls, isEmpty);
    });
  });

  group('SignOut', () {
    test('delegates to the repository', () async {
      final result = await SignOut(repository)();
      expect(result.isSuccess, isTrue);
      expect(repository.calls, contains('signOut'));
    });

    test('passes a failure through', () async {
      repository.signOutFailure = const Network();
      final result = await SignOut(repository)();
      expect(result.failureOrNull, isA<Network>());
    });
  });

  group('SendPasswordReset', () {
    test('validates the email locally', () async {
      final result = await SendPasswordReset(repository)(email: 'bad');
      expect(result.failureOrNull, isA<Validation>());
      expect(repository.calls, isEmpty);
    });

    test('succeeds for a well-formed address', () async {
      final result = await SendPasswordReset(repository)(email: 'a@b.co');
      expect(result.isSuccess, isTrue);
      expect(repository.calls, contains('sendPasswordReset'));
    });

    test('succeeds even for an address with no account', () async {
      // Firebase deliberately succeeds here so the screen cannot be used to
      // enumerate registered emails.  The fake models the same contract: no
      // failure is programmed, so the call succeeds.
      final result = await SendPasswordReset(repository)(
        email: 'nobody@example.com',
      );
      expect(result.isSuccess, isTrue);
    });
  });

  group('SendEmailVerification', () {
    test('refuses when nobody is signed in', () async {
      final result = await SendEmailVerification(repository)(isSignedIn: false);

      expect(result.failureOrNull, isA<PermissionDenied>());
      expect(repository.calls, isEmpty);
    });

    test('delegates when signed in', () async {
      final result = await SendEmailVerification(repository)(isSignedIn: true);

      expect(result.isSuccess, isTrue);
      expect(repository.calls, contains('sendEmailVerification'));
    });

    test('passes a backend failure through', () async {
      repository.sendEmailVerificationFailure = const TooManyRequests();

      final result = await SendEmailVerification(repository)(isSignedIn: true);

      expect(result.failureOrNull, isA<TooManyRequests>());
    });
  });

  group('reloadUser (via the repository contract)', () {
    test('reports the verified flag after the inbox link is opened', () async {
      repository.signInAs(
        const AppUser(uid: 'u1', email: 'a@b.co', emailVerified: false),
      );

      final before = await repository.reloadUser();
      expect(before.valueOrNull?.emailVerified, isFalse);

      // The user taps the link in their inbox.
      repository.reloadVerified = true;

      final after = await repository.reloadUser();
      expect(after.valueOrNull?.emailVerified, isTrue);
    });

    test('forces an ID-token refresh on every reload (H5)', () async {
      repository.signInAs(
        const AppUser(uid: 'u1', email: 'a@b.co', emailVerified: false),
      );

      await repository.reloadUser();
      await repository.reloadUser();

      expect(repository.tokenRefreshes, 2);
    });

    test('does not refresh a token when nobody is signed in', () async {
      await repository.reloadUser();
      expect(repository.tokenRefreshes, 0);
    });
  });
}
