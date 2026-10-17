import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/features/auth/presentation/auth_form_controller.dart';
import 'package:flutter/material.dart';

/// Shared email field for all four auth forms.
///
/// Responsibilities kept in one place so the four screens cannot drift:
///
/// * email keyboard type and autofill hints,
/// * `textInputAction.next` so the keyboard action key moves on,
/// * the localized inline error, resolved from an [AppFailure] — the screen
///   passes whatever the controller's validator returned.
class AuthEmailField extends StatelessWidget {
  const AuthEmailField({
    required this.controller,
    required this.onChanged,
    this.error,
    this.enabled = true,
    this.onSubmitted,
    this.autofocus = false,
    super.key,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  /// Inline error, or `null` when the field is acceptable.
  final AppFailure? error;

  final bool enabled;
  final VoidCallback? onSubmitted;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final failure = error;
    return TextField(
      controller: controller,
      enabled: enabled,
      autofocus: autofocus,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      autofillHints: const [AutofillHints.username, AutofillHints.email],
      onChanged: onChanged,
      onSubmitted: onSubmitted == null ? null : (_) => onSubmitted!(),
      decoration: InputDecoration(
        labelText: l10n.authEmailLabel,
        hintText: l10n.authEmailHint,
        prefixIcon: const Icon(Icons.alternate_email_rounded),
        errorText: failure == null
            ? null
            : l10n.authFailureMessage(authFailureCode(failure)),
      ),
    );
  }
}
