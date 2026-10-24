import 'package:family_hub/app/routing/app_routes.dart';
import 'package:family_hub/app/routing/session_phase.dart';

/// The route a user in [phase] belongs on.
String homeRouteFor(SessionPhase phase) => switch (phase) {
  SessionPhase.loading || SessionPhase.failed => AppRoutes.splash,
  SessionPhase.signedOut => AppRoutes.welcome,
  SessionPhase.needsVerification => AppRoutes.verifyEmail,
  SessionPhase.needsProfile => AppRoutes.profileSetup,
  SessionPhase.needsFamily => AppRoutes.familyChoice,
  SessionPhase.pending => AppRoutes.pending,
  SessionPhase.disabled => AppRoutes.disabled,
  SessionPhase.active => AppRoutes.home,
};

/// Pure redirect decision: no Flutter, no Riverpod, no I/O.
///
/// Returns the path to redirect to, or `null` to let [location] stand.  One
/// branch per row of the Step 8 table:
///
/// | phase                | allowed locations                      | otherwise     |
/// | -------------------- | -------------------------------------- | ------------- |
/// | loading / failed     | /splash                                | /splash       |
/// | signedOut            | /welcome /login /signup /forgot-password | /welcome    |
/// | needsVerification    | /verify-email                          | /verify-email |
/// | needsProfile         | /profile-setup                         | /profile-setup|
/// | needsFamily          | /family-choice (and sub-paths)         | /family-choice|
/// | pending              | /pending                               | /pending      |
/// | disabled             | /disabled                              | /disabled     |
/// | active               | everything except the gate screens     | /home         |
///
/// The local preference screens ([AppRoutes.alwaysOpen]) are reachable in every
/// phase except `loading`, because they touch no account data.
///
/// Deep links: a link to `/bazar` opened while signed out resolves to
/// `/welcome`; the guard never lets a deep link bypass a gate.  The original
/// location is not remembered (a deliberate simplification).
String? resolveRedirect({
  required SessionPhase phase,
  required String location,
}) {
  final path = _pathOf(location);

  if (phase == SessionPhase.loading || phase == SessionPhase.failed) {
    return path == AppRoutes.splash ? null : AppRoutes.splash;
  }

  if (AppRoutes.alwaysOpen.contains(path)) return null;

  switch (phase) {
    case SessionPhase.signedOut:
      return AppRoutes.publicAuth.contains(path) ? null : AppRoutes.welcome;
    case SessionPhase.needsVerification:
      return path == AppRoutes.verifyEmail ? null : AppRoutes.verifyEmail;
    case SessionPhase.needsProfile:
      return path == AppRoutes.profileSetup ? null : AppRoutes.profileSetup;
    case SessionPhase.needsFamily:
      return _isWithin(path, AppRoutes.familyChoice)
          ? null
          : AppRoutes.familyChoice;
    case SessionPhase.pending:
      return path == AppRoutes.pending ? null : AppRoutes.pending;
    case SessionPhase.disabled:
      return path == AppRoutes.disabled ? null : AppRoutes.disabled;
    case SessionPhase.active:
      return (path == '/' || _isGate(path)) ? AppRoutes.home : null;
    case SessionPhase.loading:
    case SessionPhase.failed:
      return null; // Handled above; keeps the switch exhaustive.
  }
}

/// `/a/b?x=1#y` -> `/a/b`, trailing slash removed (except for the root).
String _pathOf(String location) {
  final uri = Uri.tryParse(location);
  var path = uri?.path ?? location;
  if (path.length > 1 && path.endsWith('/')) {
    path = path.substring(0, path.length - 1);
  }
  return path.isEmpty ? '/' : path;
}

bool _isWithin(String path, String base) =>
    path == base || path.startsWith('$base/');

bool _isGate(String path) => AppRoutes.gates.any((g) => _isWithin(path, g));
