import 'dart:async';

import 'package:family_hub/app/routing/session_phase.dart';
import 'package:family_hub/app/routing/session_providers.dart';
import 'package:family_hub/features/auth/domain/app_user.dart';
import 'package:family_hub/features/auth/presentation/auth_providers.dart';
import 'package:family_hub/features/family/domain/membership.dart';
import 'package:family_hub/features/family/presentation/membership_providers.dart';
import 'package:family_hub/features/onboarding/presentation/profile_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _verified = AppUser(uid: 'u1', email: 'a@b.com', emailVerified: true);
const _unverified = AppUser(uid: 'u1', email: 'a@b.com', emailVerified: false);

/// Builds the phase from fake providers, as the roadmap asks ("unit-test every
/// rule with fake providers, one test per row").
Future<SessionPhase> _phase({
  required Stream<AppUser?> auth,
  Stream<bool>? hasProfile,
  Stream<Membership>? membership,
}) async {
  final container = ProviderContainer(
    overrides: [
      authStateProvider.overrideWith((ref) => auth),
      hasProfileProvider
          .overrideWith((ref) => hasProfile ?? Stream<bool>.value(false)),
      membershipProvider.overrideWith(
        (ref) => membership ?? Stream<Membership>.value(Membership.none),
      ),
    ],
  );
  addTearDown(container.dispose);
  container.listen(sessionPhaseProvider, (_, __) {});
  await pumpEventQueue();
  return container.read(sessionPhaseProvider);
}

Stream<Membership> _member(MembershipStatus status) => Stream.value(
      Membership(status: status, familyId: 'fam-1'),
    );

void main() {
  test('loading: the first auth event has not arrived', () async {
    final never = StreamController<AppUser?>();
    addTearDown(never.close);
    expect(await _phase(auth: never.stream), SessionPhase.loading);
  });

  test('failed: the auth stream errored before any value', () async {
    expect(
      await _phase(auth: Stream<AppUser?>.error(StateError('boom'))),
      SessionPhase.failed,
    );
  });

  test('signedOut: no user', () async {
    expect(await _phase(auth: Stream.value(null)), SessionPhase.signedOut);
  });

  test('needsVerification: signed in, e-mail unverified', () async {
    expect(
      await _phase(auth: Stream.value(_unverified)),
      SessionPhase.needsVerification,
    );
  });

  test('needsVerification wins even when a profile and family exist',
      () async {
    expect(
      await _phase(
        auth: Stream.value(_unverified),
        hasProfile: Stream.value(true),
        membership: _member(MembershipStatus.active),
      ),
      SessionPhase.needsVerification,
    );
  });

  test('loading: verified, profile read still pending', () async {
    final never = StreamController<bool>();
    addTearDown(never.close);
    expect(
      await _phase(auth: Stream.value(_verified), hasProfile: never.stream),
      SessionPhase.loading,
    );
  });

  test('failed: verified, profile read errored', () async {
    expect(
      await _phase(
        auth: Stream.value(_verified),
        hasProfile: Stream<bool>.error(StateError('boom')),
      ),
      SessionPhase.failed,
    );
  });

  test('needsProfile: verified, no profile document', () async {
    expect(
      await _phase(auth: Stream.value(_verified), hasProfile: Stream.value(false)),
      SessionPhase.needsProfile,
    );
  });

  test('needsFamily: profile, no membership', () async {
    expect(
      await _phase(
        auth: Stream.value(_verified),
        hasProfile: Stream.value(true),
        membership: _member(MembershipStatus.none),
      ),
      SessionPhase.needsFamily,
    );
  });

  test('pending: membership waits for approval', () async {
    expect(
      await _phase(
        auth: Stream.value(_verified),
        hasProfile: Stream.value(true),
        membership: _member(MembershipStatus.pending),
      ),
      SessionPhase.pending,
    );
  });

  test('disabled: membership was disabled', () async {
    expect(
      await _phase(
        auth: Stream.value(_verified),
        hasProfile: Stream.value(true),
        membership: _member(MembershipStatus.disabled),
      ),
      SessionPhase.disabled,
    );
  });

  test('active: approved member', () async {
    expect(
      await _phase(
        auth: Stream.value(_verified),
        hasProfile: Stream.value(true),
        membership: _member(MembershipStatus.active),
      ),
      SessionPhase.active,
    );
  });

  test('a signed-out user never opens a membership listener', () async {
    var membershipListened = false;
    final container = ProviderContainer(
      overrides: [
        authStateProvider.overrideWith((ref) => Stream<AppUser?>.value(null)),
        hasProfileProvider.overrideWith((ref) => Stream<bool>.value(false)),
        membershipProvider.overrideWith((ref) {
          membershipListened = true;
          return Stream<Membership>.value(Membership.none);
        }),
      ],
    );
    addTearDown(container.dispose);
    container.listen(sessionPhaseProvider, (_, __) {});
    await pumpEventQueue();
    expect(membershipListened, isFalse);
  });
}
