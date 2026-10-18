import 'package:family_hub/app/routing/app_routes.dart';
import 'package:family_hub/app/routing/redirect_rules.dart';
import 'package:family_hub/app/routing/session_phase.dart';
import 'package:flutter_test/flutter_test.dart';

/// One row = one case of the roadmap Step 8 redirect table.
typedef _Row = (SessionPhase phase, String location, String? expected);

void main() {
  const rows = <_Row>[
    // ── loading / failed: everything waits on /splash ─────────────────────
    (SessionPhase.loading, '/home', '/splash'),
    (SessionPhase.loading, '/welcome', '/splash'),
    (SessionPhase.loading, '/splash', null),
    (SessionPhase.failed, '/bazar', '/splash'),
    (SessionPhase.failed, '/splash', null),

    // ── not signed in -> /welcome ─────────────────────────────────────────
    (SessionPhase.signedOut, '/splash', '/welcome'),
    (SessionPhase.signedOut, '/home', '/welcome'),
    (SessionPhase.signedOut, '/', '/welcome'),
    (SessionPhase.signedOut, '/welcome', null),
    (SessionPhase.signedOut, '/login', null),
    (SessionPhase.signedOut, '/signup', null),
    (SessionPhase.signedOut, '/forgot-password', null),
    (SessionPhase.signedOut, '/verify-email', '/welcome'),
    (SessionPhase.signedOut, '/pending', '/welcome'),

    // ── signed in, e-mail unverified -> /verify-email ─────────────────────
    (SessionPhase.needsVerification, '/welcome', '/verify-email'),
    (SessionPhase.needsVerification, '/login', '/verify-email'),
    (SessionPhase.needsVerification, '/home', '/verify-email'),
    (SessionPhase.needsVerification, '/verify-email', null),

    // ── no user profile -> /profile-setup ─────────────────────────────────
    (SessionPhase.needsProfile, '/splash', '/profile-setup'),
    (SessionPhase.needsProfile, '/home', '/profile-setup'),
    (SessionPhase.needsProfile, '/family-choice', '/profile-setup'),
    (SessionPhase.needsProfile, '/profile-setup', null),

    // ── no family membership -> /family-choice ────────────────────────────
    (SessionPhase.needsFamily, '/profile-setup', '/family-choice'),
    (SessionPhase.needsFamily, '/home', '/family-choice'),
    (SessionPhase.needsFamily, '/family-choice', null),
    (SessionPhase.needsFamily, '/family-choice/create', null),
    (SessionPhase.needsFamily, '/family-choice/join', null),

    // ── membership pending -> /pending ────────────────────────────────────
    (SessionPhase.pending, '/home', '/pending'),
    (SessionPhase.pending, '/family-choice', '/pending'),
    (SessionPhase.pending, '/pending', null),

    // ── membership disabled -> /disabled ──────────────────────────────────
    (SessionPhase.disabled, '/home', '/disabled'),
    (SessionPhase.disabled, '/pending', '/disabled'),
    (SessionPhase.disabled, '/disabled', null),

    // ── active -> /home; gate screens bounce home, the rest is free ───────
    (SessionPhase.active, '/splash', '/home'),
    (SessionPhase.active, '/', '/home'),
    (SessionPhase.active, '/welcome', '/home'),
    (SessionPhase.active, '/login', '/home'),
    (SessionPhase.active, '/verify-email', '/home'),
    (SessionPhase.active, '/profile-setup', '/home'),
    (SessionPhase.active, '/family-choice', '/home'),
    (SessionPhase.active, '/pending', '/home'),
    (SessionPhase.active, '/disabled', '/home'),
    (SessionPhase.active, '/home', null),
    (SessionPhase.active, '/chores', null),
    (SessionPhase.active, '/bazar', null),
    (SessionPhase.active, '/family', null),

    // ── deep links never bypass a gate ────────────────────────────────────
    (SessionPhase.signedOut, '/bazar', '/welcome'),
    (SessionPhase.signedOut, '/chores?day=2026-10-17', '/welcome'),
    (SessionPhase.needsVerification, '/family', '/verify-email'),
    (SessionPhase.pending, '/chores', '/pending'),
    (SessionPhase.disabled, '/bazar', '/disabled'),
    (SessionPhase.active, '/bazar?month=2026-10', null),
    (SessionPhase.active, '/chores/', null),

    // ── local preference screens are open in every phase but loading ──────
    (SessionPhase.signedOut, '/settings/theme', null),
    (SessionPhase.signedOut, '/settings/language', null),
    (SessionPhase.needsVerification, '/settings/language', null),
    (SessionPhase.pending, '/settings/theme', null),
    (SessionPhase.active, '/settings/theme', null),
    (SessionPhase.active, '/dev/tokens', null),
    (SessionPhase.loading, '/settings/theme', '/splash'),
  ];

  for (final (phase, location, expected) in rows) {
    test('${phase.name}: $location -> ${expected ?? 'stays'}', () {
      expect(
        resolveRedirect(phase: phase, location: location),
        expected,
      );
    });
  }

  test('every phase has a home route and that route is never redirected', () {
    for (final phase in SessionPhase.values) {
      final home = homeRouteFor(phase);
      expect(
        resolveRedirect(phase: phase, location: home),
        isNull,
        reason: '$phase home route $home must be stable',
      );
    }
  });

  test('every phase is covered by at least one row', () {
    final covered = {for (final r in rows) r.$1};
    expect(covered, SessionPhase.values.toSet());
  });

  test('AppRoutes.gates contains every onboarding route', () {
    expect(
      AppRoutes.gates,
      containsAll(<String>[
        AppRoutes.splash,
        AppRoutes.welcome,
        AppRoutes.verifyEmail,
        AppRoutes.profileSetup,
        AppRoutes.familyChoice,
        AppRoutes.pending,
        AppRoutes.disabled,
      ]),
    );
  });
}
