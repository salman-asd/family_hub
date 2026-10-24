import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/features/auth/domain/app_user.dart';
import 'package:family_hub/features/auth/domain/usecases/auth_use_cases.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/fake_auth_repository.dart';

void main() {
  late FakeAuthRepository repo;
  setUp(() {
    repo = FakeAuthRepository(
      signedInAs: const AppUser(
        uid: 'u1',
        email: 'a@b.com',
        emailVerified: true,
      ),
    );
  });
  tearDown(() => repo.dispose());

  group('ChangePassword', () {
    test('re-authenticates, then sets the new password', () async {
      final r = await ChangePassword(repo)(
        currentPassword: 'oldpassword',
        newPassword: 'newpassword1',
      );
      expect(r.isSuccess, isTrue);
      expect(repo.calls, ['reauthenticate', 'changePassword']);
      expect(repo.lastNewPassword, 'newpassword1');
    });

    test('a short new password is rejected before any backend call', () async {
      final r = await ChangePassword(repo)(
        currentPassword: 'oldpassword',
        newPassword: 'short',
      );
      expect(r.failureOrNull, isA<Validation>());
      expect(repo.calls, isEmpty);
    });

    test('the same password is rejected', () async {
      final r = await ChangePassword(repo)(
        currentPassword: 'samepassword',
        newPassword: 'samepassword',
      );
      expect(
        (r.failureOrNull! as Validation).code,
        ChangePassword.codeSameAsCurrent,
      );
      expect(repo.calls, isEmpty);
    });

    test('a wrong current password stops before changing anything', () async {
      repo.reauthenticateFailure = const InvalidCredentials();
      final r = await ChangePassword(repo)(
        currentPassword: 'wrongpass1',
        newPassword: 'newpassword1',
      );
      expect(r.failureOrNull, isA<InvalidCredentials>());
      expect(repo.calls, ['reauthenticate']);
      expect(repo.lastNewPassword, isNull);
    });

    test('an empty current password is a validation failure', () async {
      final r = await ChangePassword(repo)(
        currentPassword: '',
        newPassword: 'newpassword1',
      );
      expect(r.failureOrNull, isA<Validation>());
    });
  });

  group('ReauthenticateWithPassword', () {
    test('empty password is rejected locally', () async {
      final r = await ReauthenticateWithPassword(repo)(password: '');
      expect(r.failureOrNull, isA<Validation>());
      expect(repo.calls, isEmpty);
    });

    test('delegates to the repository', () async {
      final r = await ReauthenticateWithPassword(repo)(password: 'pass1234');
      expect(r.isSuccess, isTrue);
      expect(repo.calls, ['reauthenticate']);
    });
  });

  group('SignOut hook', () {
    test('runs afterSignOut only when sign-out succeeded', () async {
      var ran = 0;
      final ok = await SignOut(repo, afterSignOut: () async => ran++)();
      expect(ok.isSuccess, isTrue);
      expect(ran, 1);

      repo.signOutFailure = const Network();
      final bad = await SignOut(repo, afterSignOut: () async => ran++)();
      expect(bad.isFailure, isTrue);
      expect(ran, 1);
    });
  });
}
