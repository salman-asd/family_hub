import 'package:family_hub/features/auth/presentation/auth_routes.dart';

/// Every route path of the app, declared once.
///
/// Auth paths live in [AuthRoutes] (next to their screens) and are re-exposed
/// here so the router and its redirect rules read from a single place.
abstract final class AppRoutes {
  // ── Bootstrapping ─────────────────────────────────────────────────────────
  static const String splash = '/splash';

  // ── Auth (signed out / unverified) ────────────────────────────────────────
  static const String welcome = AuthRoutes.welcome;
  static const String login = AuthRoutes.login;
  static const String signUp = AuthRoutes.signUp;
  static const String forgotPassword = AuthRoutes.forgotPassword;
  static const String verifyEmail = AuthRoutes.verifyEmail;

  // ── Onboarding gates (signed in, not yet in a family) ─────────────────────
  static const String profileSetup = '/profile-setup';
  static const String familyChoice = '/family-choice';
  static const String pending = '/pending';
  static const String disabled = '/disabled';

  // ── Shell tabs ────────────────────────────────────────────────────────────
  static const String home = '/home';
  static const String chores = '/chores';
  static const String bazar = '/bazar';
  static const String family = '/family';

  // ── Onboarding sub-routes ─────────────────────────────────────────────────
  static const String createFamily = '/family-choice/create';
  static const String joinFamily = '/family-choice/join';

  // ── Family tab sub-routes ─────────────────────────────────────────────────
  static const String familyMembers = '/family/members';
  static const String familyMemberPattern = '/family/members/:uid';
  static String memberProfile(String uid) => '/family/members/$uid';
  static const String familyInvitations = '/family/invitations';
  static const String familyRoles = '/family/roles';
  static const String familySettings = '/family/settings';
  static const String profileEdit = '/family/profile';

  // ── Settings (full-screen, outside the shell) ─────────────────────────────
  static const String settingsTheme = '/settings/theme';
  static const String settingsLanguage = '/settings/language';

  // ── Developer tools (dev flavor only) ─────────────────────────────────────
  static const String devTokens = '/dev/tokens';

  /// Routes a signed-out visitor may open.
  static const Set<String> publicAuth = {
    welcome,
    login,
    signUp,
    forgotPassword,
  };

  /// Gate screens that only make sense before a member is active.  An active
  /// member who lands on one (stale deep link) is sent home.
  static const Set<String> gates = {
    splash,
    welcome,
    login,
    signUp,
    forgotPassword,
    verifyEmail,
    profileSetup,
    familyChoice,
    pending,
    disabled,
  };

  /// Local-only preference screens: no account data, so they stay reachable in
  /// every phase (a user can switch language before signing in).
  static const Set<String> alwaysOpen = {
    settingsTheme,
    settingsLanguage,
    devTokens,
  };
}
