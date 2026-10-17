import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/features/auth/presentation/auth_routes.dart';
import 'package:family_hub/features/auth/presentation/controllers/login_controller.dart';
import 'package:family_hub/features/auth/presentation/widgets/auth_email_field.dart';
import 'package:family_hub/features/auth/presentation/widgets/auth_error_text.dart';
import 'package:family_hub/features/auth/presentation/widgets/auth_password_field.dart';
import 'package:family_hub/features/auth/presentation/widgets/auth_scaffold.dart';
import 'package:family_hub/features/auth/presentation/widgets/auth_submit_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// `/login`.
///
/// The screen is a [ConsumerStatefulWidget] only because it owns two
/// [TextEditingController]s and a [GlobalKey<FormState>]; all *state* lives in
/// [LoginController], so widget tests can drive the flow without typing.
///
/// On success it does **not** navigate itself: the Step 8 router watches the
/// auth stream and redirects.  When this screen is mounted without a router
/// redirect (a widget test, or the path being used as the only route), it calls
/// [onSignedIn] so a host can react.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({this.onSignedIn, super.key});

  /// Called after a successful sign-in.  Optional so the widget works standalone
  /// in tests and galleries.
  final void Function()? onSignedIn;

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final user = await ref.read(loginControllerProvider.notifier).run();
    if (!mounted) return;
    if (user == null) return;

    widget.onSignedIn?.call();

    // With the full router mounted the Step 8 auth guard already redirects; the
    // explicit navigation is only the fallback for a standalone mount (a widget
    // test or a gallery).  `GoRouter.maybeOf` returns null when no router is in
    // the tree, which is exactly when there is nothing to redirect.
    GoRouter.maybeOf(context)?.go(AuthRoutes.welcome);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(loginControllerProvider);
    final controller = ref.read(loginControllerProvider.notifier);

    return AuthScaffold(
      title: l10n.authSignInTitle,
      subtitle: l10n.authSignInSubtitle,
      children: [
        AuthEmailField(
          controller: _emailController,
          enabled: !state.isSubmitting,
          error: controller.emailError(),
          onChanged: controller.setEmail,
          onSubmitted: () => FocusScope.of(context).nextFocus(),
        ),
        const SizedBox(height: 16),
        AuthPasswordField(
          controller: _passwordController,
          enabled: !state.isSubmitting,
          isLastField: true,
          error: controller.passwordError(),
          onChanged: controller.setPassword,
          onSubmitted: _submit,
        ),
        const SizedBox(height: 8),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton(
            onPressed: state.isSubmitting
                ? null
                : () => context.go(AuthRoutes.forgotPassword),
            child: Text(l10n.authForgotPassword),
          ),
        ),
        const SizedBox(height: 16),
        // A field-level problem is already shown inline under its field, so the
        // general error block would repeat the same sentence twice.  Only a
        // backend failure belongs here.
        if (state.failure != null && state.failure is! Validation) ...[
          AuthErrorText(failure: state.failure!),
          const SizedBox(height: 16),
        ],
        AuthSubmitButton(
          label: l10n.authSignInAction,
          isSubmitting: state.isSubmitting,
          enabled: controller.canSubmit,
          onPressed: _submit,
        ),
        const SizedBox(height: 20),
        // Wrap, not Row: "No account yet? + Create an account" is longer than
        // a phone width in Bangla at 200% text scale and must reflow.
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              l10n.authNoAccountYet,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            TextButton(
              onPressed: state.isSubmitting
                  ? null
                  : () => context.go(AuthRoutes.signUp),
              child: Text(l10n.authCreateAccountAction),
            ),
          ],
        ),
      ],
    );
  }
}
