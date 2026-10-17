import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/features/auth/presentation/auth_form_controller.dart';
import 'package:flutter/material.dart';

/// Shared password field with a show/hide toggle.
///
/// The toggle is an [IconButton] whose semantic label changes with the state, so
/// a screen reader announces "Show password" / "Hide password" instead of a bare
/// "button".
class AuthPasswordField extends StatefulWidget {
  const AuthPasswordField({
    required this.controller,
    required this.onChanged,
    this.error,
    this.enabled = true,
    this.isLastField = false,
    this.onSubmitted,
    this.helperText,
    this.autofillHints = const [AutofillHints.password],
    this.labelText,
    super.key,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  /// Inline error, or `null` when the field is acceptable.
  final AppFailure? error;

  final bool enabled;

  /// When true the keyboard shows a "done" action instead of "next".
  final bool isLastField;

  final VoidCallback? onSubmitted;
  final String? helperText;
  final List<String> autofillHints;

  /// Overrides the label (used by the confirmation field on SignUp).
  final String? labelText;

  @override
  State<AuthPasswordField> createState() => _AuthPasswordFieldState();
}

class _AuthPasswordFieldState extends State<AuthPasswordField> {
  bool _obscured = true;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final failure = widget.error;

    return TextField(
      controller: widget.controller,
      enabled: widget.enabled,
      obscureText: _obscured,
      keyboardType: TextInputType.visiblePassword,
      textInputAction:
          widget.isLastField ? TextInputAction.done : TextInputAction.next,
      autofillHints: widget.autofillHints,
      onChanged: widget.onChanged,
      onSubmitted:
          widget.onSubmitted == null ? null : (_) => widget.onSubmitted!(),
      decoration: InputDecoration(
        labelText: widget.labelText ?? l10n.authPasswordLabel,
        hintText: l10n.authPasswordHint,
        helperText: widget.helperText,
        prefixIcon: const Icon(Icons.lock_outline_rounded),
        suffixIcon: IconButton(
          onPressed: widget.enabled
              ? () => setState(() => _obscured = !_obscured)
              : null,
          icon: Icon(
            _obscured
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            semanticLabel:
                _obscured ? l10n.authShowPassword : l10n.authHidePassword,
          ),
        ),
        errorText: failure == null
            ? null
            : l10n.authFailureMessage(authFailureCode(failure)),
      ),
    );
  }
}
