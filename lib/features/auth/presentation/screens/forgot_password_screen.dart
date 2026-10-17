import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/features/auth/presentation/auth_routes.dart';
import 'package:family_hub/features/auth/presentation/controllers/forgot_password_controller.dart';
import 'package:family_hub/features/auth/presentation/widgets/auth_email_field.dart';
import 'package:family_hub/features/auth/presentation/widgets/auth_error_text.dart';
import 'package:family_hub/features/auth/presentation/widgets/auth_scaffold.dart';
import 'package:family_hub/features/auth/presentation/widgets/auth_submit_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// `/forgot-password`.
///
/// Two visual states in one screen: the form, and — after a successful send —
/// a confirmation panel naming the address.
///
/// The confirmation copy says "a reset link was sent", never "your account
/// exists".  Firebase returns success for unknown addresses on purpose so this
/// screen cannot be used to discover which emails are registered.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    await ref.read(forgotPasswordControllerProvider.notifier).run();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final t = context.tokens;
    final state = ref.watch(forgotPasswordControllerProvider);
    final controller = ref.read(forgotPasswordControllerProvider.notifier);

    if (state.succeeded) {
      return AuthScaffold(
        title: l10n.authForgotPasswordSentTitle,
        children: [
          Text(
            l10n.authForgotPasswordSentMessage(controller.email.trim()),
            style: TextStyle(color: t.textPrimary, fontSize: 15, height: 1.5),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => context.go(AuthRoutes.login),
            child: Text(l10n.actionBack),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: controller.reset,
            child: Text(l10n.authForgotPasswordSend),
          ),
        ],
      );
    }

    return AuthScaffold(
      title: l10n.authForgotPasswordTitle,
      subtitle: l10n.authForgotPasswordSubtitle,
      children: [
        AuthEmailField(
          controller: _emailController,
          enabled: !state.isSubmitting,
          error: controller.emailError(),
          onChanged: controller.setEmail,
          onSubmitted: _submit,
        ),
        const SizedBox(height: 20),
        // The email error is already inline under the field; only a backend
        // failure belongs in the general error block.
        if (state.failure != null && state.failure is! Validation) ...[
          AuthErrorText(failure: state.failure!),
          const SizedBox(height: 16),
        ],
        AuthSubmitButton(
          label: l10n.authForgotPasswordSend,
          isSubmitting: state.isSubmitting,
          enabled: controller.canSubmit,
          onPressed: _submit,
        ),
      ],
    );
  }
}
