import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/features/auth/presentation/auth_routes.dart';
import 'package:family_hub/features/auth/presentation/controllers/sign_up_controller.dart';
import 'package:family_hub/features/auth/presentation/widgets/auth_email_field.dart';
import 'package:family_hub/features/auth/presentation/widgets/auth_error_text.dart';
import 'package:family_hub/features/auth/presentation/widgets/auth_password_field.dart';
import 'package:family_hub/features/auth/presentation/widgets/auth_scaffold.dart';
import 'package:family_hub/features/auth/presentation/widgets/auth_submit_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// `/signup`.
///
/// On success it navigates to `/verify-email`: a fresh account is unverified and
/// Step 7 requires the verification step to be explicit rather than implicit.
class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({this.onSignedUp, super.key});

  /// Called after a successful sign-up, for a standalone mount.
  final void Function()? onSignedUp;

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  /// True when [failure] is already rendered inline under its own field.
  bool _isFieldFailure(AppFailure failure) => failure is Validation;

  Future<void> _submit() async {
    await ref.read(signUpControllerProvider.notifier).run();
    if (!mounted) return;
    if (!ref.read(signUpControllerProvider).succeeded) return;

    widget.onSignedUp?.call();

    // Only navigate when a router is actually mounted; a standalone mount has
    // nothing to push to, and the callback above is the observable outcome.
    GoRouter.maybeOf(context)?.go(AuthRoutes.verifyEmail);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(signUpControllerProvider);
    final controller = ref.read(signUpControllerProvider.notifier);
    final confirmError = controller.passwordConfirmError();
    final busy = state.isSubmitting;

    return AuthScaffold(
      title: l10n.authSignUpTitle,
      subtitle: l10n.authSignUpSubtitle,
      children: [
        AuthEmailField(
          controller: _emailController,
          enabled: !busy,
          error: controller.emailError(),
          onChanged: controller.setEmail,
        ),
        const SizedBox(height: 16),
        AuthPasswordField(
          controller: _passwordController,
          enabled: !busy,
          error: controller.passwordError(),
          helperText: l10n.authPasswordTooShortHelper,
          autofillHints: const [AutofillHints.newPassword],
          onChanged: controller.setPassword,
        ),
        const SizedBox(height: 16),
        AuthPasswordField(
          controller: _confirmController,
          enabled: !busy,
          isLastField: true,
          labelText: l10n.authPasswordConfirmLabel,
          error: confirmError,
          autofillHints: const [AutofillHints.newPassword],
          onChanged: controller.setPasswordConfirm,
          onSubmitted: _submit,
        ),
        const SizedBox(height: 20),
        // A field-level problem is already shown inline under its field, so the
        // general error block would repeat the same sentence twice.  Only a
        // *form-level* failure (a backend error) belongs here.
        if (state.failure != null && !_isFieldFailure(state.failure!)) ...[
          AuthErrorText(failure: state.failure!),
          const SizedBox(height: 16),
        ],
        AuthSubmitButton(
          label: l10n.authCreateAccountAction,
          isSubmitting: busy,
          enabled: controller.canSubmit,
          onPressed: _submit,
        ),
        const SizedBox(height: 20),
        // Wrap, not Row: the two labels together exceed a phone width in Bangla
        // at 200% text scale and must reflow instead of overflowing.
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              l10n.authAlreadyHaveAccount,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            TextButton(
              onPressed: busy ? null : () => context.go(AuthRoutes.login),
              child: Text(l10n.authSignInAction),
            ),
          ],
        ),
      ],
    );
  }
}
