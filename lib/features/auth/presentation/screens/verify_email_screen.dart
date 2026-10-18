import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/features/auth/presentation/auth_providers.dart';
import 'package:family_hub/features/auth/presentation/auth_routes.dart';
import 'package:family_hub/features/auth/presentation/auth_form_controller.dart';
import 'package:family_hub/features/auth/presentation/controllers/verify_email_controller.dart';
import 'package:family_hub/features/auth/presentation/widgets/auth_error_text.dart';
import 'package:family_hub/features/auth/presentation/widgets/auth_scaffold.dart';
import 'package:family_hub/features/auth/presentation/widgets/auth_submit_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// `/verify-email`.
///
/// Three actions, in the order a real user meets them:
///
/// 1. open the link in the email (outside the app),
/// 2. press **"I have verified"**, which calls `reloadUser`,
/// 3. if the mail never arrived, press **"Send the email again"**.
///
/// The most common outcome of step 2 is "still not verified" — that is an
/// *informational* state, so it is rendered as a neutral banner, not an error.
/// Only a failed round trip gets error styling.
class VerifyEmailScreen extends ConsumerWidget {
  const VerifyEmailScreen({this.onVerified, this.onSignedOut, super.key});

  /// Called when the address is confirmed verified, for a standalone mount.
  final void Function()? onVerified;

  /// Called after the user signs out from this screen, for a standalone mount.
  final void Function()? onSignedOut;

  /// Signs out and leaves, then reports it through [onSignedOut].
  ///
  /// The auth stream fires first, so with the router mounted the guard would
  /// already send the user to `/welcome`; the explicit navigation is the
  /// fallback for a standalone mount, exactly as [LoginScreen] does after a
  /// successful sign-in.
  Future<void> _signOutAndLeave(BuildContext context, WidgetRef ref) async {
    await ref.read(signOutProvider).call();
    if (!context.mounted) return;
    onSignedOut?.call();
    // Only navigate when a router is mounted; on a standalone mount the
    // callback above is the observable outcome.
    GoRouter.maybeOf(context)?.go(AuthRoutes.welcome);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final t = context.tokens;

    final user = ref.watch(authStateProvider).value;
    final verify = ref.watch(verifyEmailControllerProvider);
    final controller = ref.read(verifyEmailControllerProvider.notifier);
    final busy = verify.isSubmitting;
    final email = user?.email ?? '';

    return AuthScaffold(
      title: l10n.authVerifyEmailTitle,
      showBackButton: false,
      children: [
        Text(
          l10n.authVerifyEmailMessage(email),
          style: TextStyle(color: t.textPrimary, fontSize: 15, height: 1.5),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.authUsingAccount(email),
          style: TextStyle(color: t.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 24),

        // ── Informational states (never error styling) ──────────────────────
        if (verify.resendSucceeded) ...[
          AuthInfoBanner(
            message: l10n.authEmailVerificationSent,
            icon: Icons.mark_email_read_outlined,
            tone: AuthInfoTone.success,
          ),
          const SizedBox(height: 16),
        ],
        if (verify.stillUnverified) ...[
          AuthInfoBanner(
            message: l10n.authVerifyEmailStillUnverified,
            icon: Icons.hourglass_empty_rounded,
            tone: AuthInfoTone.warning,
          ),
          const SizedBox(height: 16),
        ],

        // ── Real failure ────────────────────────────────────────────────────
        if (verify.failure != null) ...[
          AuthErrorText(failure: verify.failure!),
          const SizedBox(height: 16),
        ],

        AuthSubmitButton(
          label: l10n.authVerifyEmailIHaveVerified,
          isSubmitting: busy && verify.action == VerifyAction.checkVerified,
          onPressed: () async {
            final verified = await controller.checkVerified();
            if (verified) onVerified?.call();
          },
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: busy ? null : controller.resend,
          child: busy && verify.action == VerifyAction.resend
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.authVerifyEmailResend),
        ),
        const SizedBox(height: 20),
        TextButton(
          onPressed: busy ? null : () => _signOutAndLeave(context, ref),
          child: Text(l10n.authVerifyEmailSignOutInstead),
        ),
      ],
    );
  }
}
