import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/features/auth/domain/auth_providers.dart';
import 'package:family_hub/features/auth/presentation/controllers/forgot_password_controller.dart';
import 'package:family_hub/features/auth/presentation/controllers/login_controller.dart';
import 'package:family_hub/features/auth/presentation/controllers/sign_up_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/fake_auth_repository.dart';

void main() {
  late FakeAuthRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = FakeAuthRepository();
    container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
    );
  });

  tearDown(() async {
    container.dispose();
    await repository.dispose();
  });

  group('LoginController', () {
    LoginController controller() =>
        container.read(loginControllerProvider.notifier);

    test('starts idle and cannot submit while empty', () {
      expect(container.read(loginControllerProvider).isIdle, isTrue);
      expect(controller().canSubmit, isFalse);
    });

    test('reports inline errors per field without a round trip', () {
      controller()
        ..setEmail('bad')
        ..setPassword('short');

      expect(controller().emailError(), isA<Validation>());
      expect(controller().passwordError(), isA<Validation>());
      expect(repository.calls, isEmpty);
    });

    test('submits a valid form and flips succeeded', () async {
      controller()
        ..setEmail('a@b.co')
        ..setPassword('longenough');

      expect(controller().canSubmit, isTrue);

      final user = await controller().run();

      expect(user?.email, 'a@b.co');
      expect(container.read(loginControllerProvider).succeeded, isTrue);
      expect(container.read(loginControllerProvider).failure, isNull);
    });

    test('a wrong password ends in InvalidCredentials with no value', () async {
      repository.signInFailure = const InvalidCredentials();

      controller()
        ..setEmail('a@b.co')
        ..setPassword('longenough');

      final user = await controller().run();

      expect(user, isNull);
      expect(
        container.read(loginControllerProvider).failure,
        isA<InvalidCredentials>(),
      );
      expect(container.read(loginControllerProvider).isSubmitting, isFalse);
    });

    test('sets isSubmitting while in flight, then clears it', () async {
      repository.hold = true;

      controller()
        ..setEmail('a@b.co')
        ..setPassword('longenough');

      final future = controller().run();
      await repository.parked;

      expect(container.read(loginControllerProvider).isSubmitting, isTrue);

      repository.release();
      await future;

      expect(container.read(loginControllerProvider).isSubmitting, isFalse);
    });

    test('editing a field clears a stale server error', () async {
      repository.signInFailure = const InvalidCredentials();

      controller()
        ..setEmail('a@b.co')
        ..setPassword('longenough');
      await controller().run();
      expect(container.read(loginControllerProvider).failure, isNotNull);

      controller().setPassword('longenough2');

      expect(container.read(loginControllerProvider).failure, isNull);
    });

    test('cannot submit with an incomplete form', () async {
      controller().setEmail('a@b.co');

      final user = await controller().run();

      expect(user, isNull);
      expect(container.read(loginControllerProvider).failure, isNotNull);
      expect(repository.calls, isEmpty);
    });
  });

  group('SignUpController', () {
    SignUpController controller() =>
        container.read(signUpControllerProvider.notifier);

    test('flags a mismatched confirmation locally', () {
      controller()
        ..setEmail('a@b.co')
        ..setPassword('longenough')
        ..setPasswordConfirm('different');

      expect(
        controller().passwordConfirmError(),
        const Validation(
          SignUpController.fieldPasswordConfirm,
          SignUpController.codePasswordMismatch,
        ),
      );
    });

    test('requires the confirmation to be filled in', () {
      controller()
        ..setEmail('a@b.co')
        ..setPassword('longenough');

      expect(controller().passwordConfirmError(), isA<Validation>());
    });

    test('never reaches the backend with a mismatched confirmation', () async {
      controller()
        ..setEmail('a@b.co')
        ..setPassword('longenough')
        ..setPasswordConfirm('different');

      await controller().run();

      expect(repository.calls, isEmpty);
      expect(
        container.read(signUpControllerProvider).failure,
        isA<Validation>(),
      );
    });

    test('creates an account with a matching confirmation', () async {
      controller()
        ..setEmail('a@b.co')
        ..setPassword('longenough')
        ..setPasswordConfirm('longenough');

      await controller().run();

      expect(container.read(signUpControllerProvider).succeeded, isTrue);
      expect(repository.calls, contains('signUp'));
    });
  });

  group('ForgotPasswordController', () {
    ForgotPasswordController controller() =>
        container.read(forgotPasswordControllerProvider.notifier);

    test('succeeds for a well-formed address', () async {
      controller().setEmail('a@b.co');

      await controller().run();

      expect(
        container.read(forgotPasswordControllerProvider).succeeded,
        isTrue,
      );
    });

    test('reset() returns the screen to the form', () async {
      controller().setEmail('a@b.co');
      await controller().run();
      expect(
        container.read(forgotPasswordControllerProvider).succeeded,
        isTrue,
      );

      controller().reset();

      expect(
        container.read(forgotPasswordControllerProvider).succeeded,
        isFalse,
      );
    });

    test('does not reach the backend for a malformed address', () async {
      controller().setEmail('bad');

      await controller().run();

      expect(repository.calls, isEmpty);
      expect(
        container.read(forgotPasswordControllerProvider).failure,
        isA<Validation>(),
      );
    });
  });
}
