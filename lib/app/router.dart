import 'package:family_hub/app/flavor.dart';
import 'package:family_hub/app/gallery/dev_gallery_screen.dart';
import 'package:family_hub/app/routing/app_routes.dart';
import 'package:family_hub/app/routing/not_found_screen.dart';
import 'package:family_hub/app/routing/redirect_rules.dart';
import 'package:family_hub/app/routing/session_phase.dart';
import 'package:family_hub/app/routing/session_providers.dart';
import 'package:family_hub/app/routing/splash_screen.dart';
import 'package:family_hub/app/shell/app_shell.dart';
import 'package:family_hub/app/theme/dev_tokens_screen.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:family_hub/features/auth/presentation/screens/login_screen.dart';
import 'package:family_hub/features/auth/presentation/screens/sign_up_screen.dart';
import 'package:family_hub/features/auth/presentation/screens/verify_email_screen.dart';
import 'package:family_hub/features/auth/presentation/screens/welcome_screen.dart';
import 'package:family_hub/features/dashboard/presentation/home_screen.dart';
import 'package:family_hub/features/family/presentation/family_screen.dart';
import 'package:family_hub/features/family/presentation/screens/create_family_screen.dart';
import 'package:family_hub/features/family/presentation/screens/family_choice_screen.dart';
import 'package:family_hub/features/family/presentation/screens/family_settings_screen.dart';
import 'package:family_hub/features/family/presentation/screens/invitations_screen.dart';
import 'package:family_hub/features/family/presentation/screens/join_family_screen.dart';
import 'package:family_hub/features/family/presentation/screens/member_profile_screen.dart';
import 'package:family_hub/features/family/presentation/screens/members_screen.dart';
import 'package:family_hub/features/family/presentation/screens/pending_screen.dart';
import 'package:family_hub/features/family/presentation/screens/relationships_screen.dart';
import 'package:family_hub/features/family/presentation/screens/roles_screen.dart';
import 'package:family_hub/features/onboarding/presentation/screens/profile_setup_screen.dart';
import 'package:family_hub/features/settings/presentation/language_settings_screen.dart';
import 'package:family_hub/features/settings/presentation/security_screen.dart';
import 'package:family_hub/features/settings/presentation/theme_settings_screen.dart';
import 'package:family_hub/modules/family_module.dart';
import 'package:family_hub/modules/module_visibility_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// One tab: what the bar shows and the routes of its navigation branch.
class _Tab {
  const _Tab(this.destination, this.routes);

  final ShellDestination destination;
  final List<RouteBase> routes;
}

/// Remembers where the user was, so that rebuilding the router (only when the
/// set of enabled modules changes) does not throw them back to the start.
class _LocationMemo {
  String? value;
}

final _locationMemoProvider = Provider<_LocationMemo>((ref) => _LocationMemo());

/// The app's [GoRouter].
///
/// * **Guards** — `redirect` asks `resolveRedirect` (pure, unit-tested) where the
///   current session phase allows the user to be.  `refreshListenable` fires on
///   every phase change, so signing in, verifying e-mail, being approved or
///   disabled moves the user immediately, with no screen-level navigation.
/// * **Shell** — a `StatefulShellRoute.indexedStack`: Home, then one branch per
///   *visible* module, then Family.  Disabled modules have no branch, no tab and
///   their paths redirect to `/home`.
/// * **Structure vs. state** — the provider rebuilds the router only when the
///   set of enabled modules changes (a rare settings action), not on every auth
///   or membership event.
final routerProvider = Provider<GoRouter>((ref) {
  final flavor = ref.watch(flavorProvider);

  // Rebuild only when the *set* of enabled modules changes.
  ref.watch(
    visibleModulesProvider.select((m) => m.map((e) => e.id).join(',')),
  );
  final enabled = ref.read(visibleModulesProvider);
  final disabled = ref.read(hiddenModulesProvider);

  final memo = ref.read(_locationMemoProvider);
  final refresh = ValueNotifier<int>(0);
  ref.listen<SessionPhase>(sessionPhaseProvider, (_, __) => refresh.value++);

  final tabs = <_Tab>[
    _Tab(
      ShellDestination(
        id: 'home',
        icon: Icons.home_outlined,
        selectedIcon: Icons.home_rounded,
        label: (context) => context.l10n.navHome,
      ),
      [
        GoRoute(
          path: AppRoutes.home,
          builder: (context, state) => const HomeScreen(),
        ),
      ],
    ),
    for (final module in enabled) _moduleTab(module),
    _Tab(
      ShellDestination(
        id: 'family',
        icon: Icons.groups_outlined,
        selectedIcon: Icons.groups_rounded,
        label: (context) => context.l10n.navFamily,
      ),
      [
        GoRoute(
          path: AppRoutes.family,
          builder: (context, state) => const FamilyScreen(),
          routes: [
            GoRoute(
              path: 'members',
              builder: (context, state) => const MembersScreen(),
              routes: [
                GoRoute(
                  path: ':uid',
                  builder: (context, state) => MemberProfileScreen(
                    uid: state.pathParameters['uid'] ?? '',
                  ),
                ),
              ],
            ),
            GoRoute(
              path: 'invitations',
              builder: (context, state) => const InvitationsScreen(),
            ),
            GoRoute(
              path: 'roles',
              builder: (context, state) => const RolesScreen(),
            ),
            GoRoute(
              path: 'settings',
              builder: (context, state) => const FamilySettingsScreen(),
            ),
            GoRoute(
              path: 'relationships',
              builder: (context, state) => const RelationshipsScreen(),
            ),
            GoRoute(
              path: 'profile',
              builder: (context, state) =>
                  const ProfileSetupScreen(editing: true),
            ),
          ],
        ),
      ],
    ),
  ];

  final router = GoRouter(
    initialLocation: memo.value ?? AppRoutes.splash,
    refreshListenable: refresh,
    errorBuilder: (context, state) => const NotFoundScreen(),
    redirect: (context, state) {
      final location = state.uri.toString();
      final phase = ref.read(sessionPhaseProvider);

      final guard = resolveRedirect(phase: phase, location: location);
      if (guard != null) return guard;

      // A deep link into a module the family switched off goes home.
      if (phase == SessionPhase.active) {
        final path = state.uri.path;
        for (final module in disabled) {
          final base = module.basePath;
          if (path == base || path.startsWith('$base/')) return AppRoutes.home;
        }
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),

      // ── Auth ────────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.welcome,
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.signUp,
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.verifyEmail,
        builder: (context, state) => const VerifyEmailScreen(),
      ),

      // ── Onboarding gates ────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.profileSetup,
        builder: (context, state) => const ProfileSetupScreen(),
      ),
      GoRoute(
        path: AppRoutes.familyChoice,
        builder: (context, state) => const FamilyChoiceScreen(),
        routes: [
          GoRoute(
            path: 'create',
            builder: (context, state) => const CreateFamilyScreen(),
          ),
          GoRoute(
            path: 'join',
            builder: (context, state) => const JoinFamilyScreen(),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.pending,
        builder: (context, state) => const PendingScreen(),
      ),
      GoRoute(
        path: AppRoutes.disabled,
        builder: (context, state) => const DisabledScreen(),
      ),

      // ── Settings: full screen, above the shell ──────────────────────────
      GoRoute(
        path: AppRoutes.settingsTheme,
        builder: (context, state) => const ThemeSettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.settingsLanguage,
        builder: (context, state) => const LanguageSettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.settingsSecurity,
        builder: (context, state) => const SecurityScreen(),
      ),
      if (flavor == Flavor.dev)
        GoRoute(
          path: AppRoutes.devTokens,
          builder: (context, state) => const DevTokensScreen(),
        ),
      if (flavor == Flavor.dev)
        GoRoute(
          path: AppRoutes.devGallery,
          builder: (context, state) => const DevGalleryScreen(),
        ),

      // ── The shell ───────────────────────────────────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => AppShell(
          navigationShell: navigationShell,
          destinations: [for (final t in tabs) t.destination],
        ),
        branches: [
          for (final t in tabs) StatefulShellBranch(routes: t.routes),
        ],
      ),
    ],
  );

  void remember() {
    memo.value = router.routeInformationProvider.value.uri.toString();
  }

  router.routeInformationProvider.addListener(remember);

  ref.onDispose(() {
    router.routeInformationProvider.removeListener(remember);
    router.dispose();
    refresh.dispose();
  });
  return router;
});

_Tab _moduleTab(FamilyModule module) => _Tab(
      ShellDestination(
        id: module.id,
        icon: module.icon,
        selectedIcon: module.selectedIcon,
        label: (context) => module.label(context.l10n),
      ),
      module.routes,
    );
