import 'package:family_hub/app/flavor.dart';
import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:family_hub/app/theme/dev_tokens_screen.dart';
import 'package:family_hub/app/theme/theme_builder.dart';
import 'package:family_hub/app/theme/theme_controller.dart';
import 'package:family_hub/app/theme/theme_prefs.dart';
import 'package:family_hub/core/localization/generated/app_localizations.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/features/auth/presentation/auth_routes.dart';
import 'package:family_hub/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:family_hub/features/auth/presentation/screens/login_screen.dart';
import 'package:family_hub/features/auth/presentation/screens/sign_up_screen.dart';
import 'package:family_hub/features/auth/presentation/screens/verify_email_screen.dart';
import 'package:family_hub/features/auth/presentation/screens/welcome_screen.dart';
import 'package:family_hub/features/settings/presentation/language_settings_screen.dart';
import 'package:family_hub/features/settings/presentation/theme_settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// App shell.  Step 8 will replace the ad-hoc GoRouter with the full route
/// table; for now only the placeholder home, /dev/tokens and /settings/theme
/// are wired.
class FamilyHubApp extends ConsumerWidget {
  const FamilyHubApp({required this.flavor, super.key});

  final Flavor flavor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(themeControllerProvider);
    final localePrefs = ref.watch(localeControllerProvider);
    final specs = resolveThemeSpecs(prefs);

    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => _HomeScreen(flavor: flavor),
        ),
        GoRoute(
          path: '/settings/theme',
          builder: (context, state) => const ThemeSettingsScreen(),
        ),
        GoRoute(
          path: '/settings/language',
          builder: (context, state) => const LanguageSettingsScreen(),
        ),
        GoRoute(
          path: '/dev/tokens',
          builder: (context, state) => const DevTokensScreen(),
        ),
        // ── Auth (Step 7) ────────────────────────────────────────────────────
        // Mounted here so the screens are reachable before Step 8 replaces the
        // ad-hoc router with the guarded one.  The paths come from [AuthRoutes]
        // so the two cannot drift.
        GoRoute(
          path: AuthRoutes.welcome,
          builder: (context, state) => const WelcomeScreen(),
        ),
        GoRoute(
          path: AuthRoutes.login,
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: AuthRoutes.signUp,
          builder: (context, state) => const SignUpScreen(),
        ),
        GoRoute(
          path: AuthRoutes.forgotPassword,
          builder: (context, state) => const ForgotPasswordScreen(),
        ),
        GoRoute(
          path: AuthRoutes.verifyEmail,
          builder: (context, state) => const VerifyEmailScreen(),
        ),
      ],
    );

    return MaterialApp.router(
      title: flavor.label,
      debugShowCheckedModeBanner: false,
      theme: buildThemeData(specs.light),
      darkTheme: buildThemeData(specs.dark),
      themeMode: prefs.themeMode,
      locale: localePrefs.locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    );
  }
}

// ── Placeholder home ──────────────────────────────────────────────────────────

class _HomeScreen extends ConsumerWidget {
  const _HomeScreen({required this.flavor});
  final Flavor flavor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final prefs = ref.watch(themeControllerProvider);
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.appName)),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              flavor.name,
              key: const Key('flavor_name'),
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(color: t.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              'Theme: ${prefs.themeId} · ${_modeLabel(prefs)}',
              style: TextStyle(color: t.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => context.push('/settings/theme'),
              child: Text(l10n.settingsThemeTitle),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => context.push('/settings/language'),
              child: Text(l10n.settingsLanguageTitle),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => context.push('/dev/tokens'),
              child: Text(l10n.homeViewThemeTokens),
            ),
          ],
        ),
      ),
    );
  }

  static String _modeLabel(ThemePrefs p) => switch (p.themeMode) {
        ThemeMode.system => 'system',
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
      };
}
