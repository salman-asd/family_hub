import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/features/auth/presentation/auth_routes.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// `/welcome` — the first thing an unauthenticated user sees.
///
/// Deliberately minimal: one value statement, a primary action and a secondary
/// action.  Navigation uses the paths from [AuthRoutes], so Step 8's router only
/// has to mount these screens at those paths.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: t.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.home_outlined,
                    size: 64,
                    color: t.accent,
                    semanticLabel: l10n.appName,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    l10n.authWelcomeHeadline,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: t.textPrimary,
                      fontSize: 26,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.authWelcomeMessage,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: t.textSecondary,
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 40),
                  FilledButton(
                    onPressed: () => context.go(AuthRoutes.login),
                    child: Text(l10n.authGetStarted),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => context.go(AuthRoutes.signUp),
                    child: Text(l10n.authCreateAccountAction),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
