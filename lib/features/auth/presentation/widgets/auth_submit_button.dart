import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:flutter/material.dart';

/// Submit button that shows a spinner and disables itself while a request is in
/// flight — the "button disabled and spinner while loading" requirement of
/// Step 7.
///
/// The spinner carries a semantic label so the loading state is never conveyed
/// by the animation alone.
class AuthSubmitButton extends StatelessWidget {
  const AuthSubmitButton({
    required this.label,
    required this.onPressed,
    required this.isSubmitting,
    this.enabled = true,
    super.key,
  });

  final String label;
  final VoidCallback onPressed;
  final bool isSubmitting;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final canPress = enabled && !isSubmitting;

    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: canPress ? onPressed : null,
        child: isSubmitting
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: t.textOnAccent,
                  semanticsLabel: context.l10n.loadingGeneric,
                ),
              )
            : Text(label),
      ),
    );
  }
}
