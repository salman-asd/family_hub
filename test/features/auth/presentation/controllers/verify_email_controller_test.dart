import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/features/auth/domain/app_user.dart';
import 'package:family_hub/features/auth/domain/auth_providers.dart';
import 'package:family_hub/features/auth/presentation/controllers/verify_email_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/fake_auth_repository.dart';

/// The VerifyEmail screen has two independent actions that share one busy flag,
/// and its most common outcome ("still not verified") is not an error.  These
/// tests pin that behaviour down because it is easy to "fix" into a red banner.
void main() {
  late FakeAuthRepository repository;
  late ProviderContainer container;

  const unverified = AppUser(uid: 'u1', email: 'a@b.co', emailVerified: false);

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

  VerifyEmailController controller() =>
      container.read(verifyEmailControllerProvider.notifier);

  VerifyEmailState state() => container.read(verifyEmailControllerProvider);

  /// Waits until the auth stream has delivered its first value to the provider.
  ///
  /// `authStateChanges()` emits the current user and then never closes, so
  /// `container.read(authStateProvider.future)` would hang forever.  Subscribing
  /// and draining the event loop is what the real app does implicitly when a
  /// widget watches the provider.
  Future<void> pumpAuthStream() async {
    container.listen(authStateProvider, (_, __) {}, fireImmediately: true);
    // Two turns: one for the broadcast stream to deliver, one for the
    // StreamProvider to publish the value into its AsyncData.
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
  }

  test('starts idle with no action recorded', () {
    expect(state().isSubmitting, isFalse);
    expect(state().failure, isNull);
    expect(state().action, isNull);
    expect(state().resendSucceeded, isFalse);
    expect(state().stillUnverified, isFalse);
  });

  group('checkVerified ("I have verified")', () {
    test('reports still-unverified as informational, not an error', () async {
      repository.signInAs(unverified);

      final verified = await controller().checkVerified();

      expect(verified, isFalse);
      expect(state().stillUnverified, isTrue);
      expect(
        state().failure,
        isNull,
        reason: 'pressing the button before opening the link is normal',
      );
      expect(state().action, VerifyAction.checkVerified);
      expect(repository.calls, contains('reloadUser'));
    });

    test('returns true once the address is verified', () async {
      repository.signInAs(unverified);
      repository.reloadVerified = true;

      final verified = await controller().checkVerified();

      expect(verified, isTrue);
      expect(controller().isVerified, isTrue);
      expect(state().stillUnverified, isFalse);
      expect(state().failure, isNull);
    });

    test('surfaces a network failure as an error', () async {
      repository.signInAs(unverified);
      repository.reloadUserFailure = const Network();

      final verified = await controller().checkVerified();

      expect(verified, isFalse);
      expect(state().failure, isA<Network>());
      expect(
        state().stillUnverified,
        isFalse,
        reason: 'a failed round trip is not the same as an unverified address',
      );
    });

    test('shows the busy state while in flight', () async {
      repository.signInAs(unverified);
      repository.hold = true;

      final future = controller().checkVerified();
      // Deterministic: wait until the call is genuinely parked in the fake
      // rather than guessing how many microtasks the chain needs.
      await repository.parked;

      expect(state().isSubmitting, isTrue);
      expect(state().action, VerifyAction.checkVerified);

      repository.release();
      await future;

      expect(state().isSubmitting, isFalse);
    });
  });

  group('resend', () {
    test('reports success and names the resend action', () async {
      repository.signInAs(unverified);
      // The signed-in flag the controller reads comes from the auth stream, so
      // the first event has to be consumed before the action runs.
      await pumpAuthStream();

      final ok = await controller().resend();

      expect(ok, isTrue);
      expect(state().resendSucceeded, isTrue);
      expect(state().action, VerifyAction.resend);
      expect(state().failure, isNull);
      expect(repository.calls, contains('sendEmailVerification'));
    });

    test('surfaces a throttling failure', () async {
      repository.signInAs(unverified);
      await pumpAuthStream();
      repository.sendEmailVerificationFailure = const TooManyRequests();

      final ok = await controller().resend();

      expect(ok, isFalse);
      expect(state().failure, isA<TooManyRequests>());
      expect(state().resendSucceeded, isFalse);
    });

    test('refuses when the user is signed out mid-screen', () async {
      // No user pushed onto the stream, so isSignedIn is false and the use case
      // rejects the call before the backend is touched.
      final ok = await controller().resend();

      expect(ok, isFalse);
      expect(state().failure, isA<PermissionDenied>());
      expect(repository.calls, isEmpty);
    });

    test('a later resend clears the previous banner', () async {
      repository.signInAs(unverified);
      await pumpAuthStream();
      await controller().resend();
      expect(state().resendSucceeded, isTrue);

      repository.sendEmailVerificationFailure = const Network();
      await controller().resend();

      expect(state().resendSucceeded, isFalse);
      expect(state().failure, isA<Network>());
    });
  });

  test('an earlier "still unverified" banner is cleared by a resend', () async {
    repository.signInAs(unverified);
    await pumpAuthStream();
    await controller().checkVerified();
    expect(state().stillUnverified, isTrue);

    await controller().resend();

    expect(state().stillUnverified, isFalse);
  });

  test('the two actions cannot both be in flight', () async {
    repository.signInAs(unverified);
    await pumpAuthStream();
    repository.hold = true;

    final first = controller().checkVerified();
    await repository.parked;

    // A resend while the reload is in flight is refused immediately by the
    // shared busy guard, so it must never reach the backend.
    final second = await controller().resend();
    expect(second, isFalse);
    expect(
      repository.calls.where((c) => c == 'sendEmailVerification'),
      isEmpty,
    );

    repository.release();
    await first;
  });
}
