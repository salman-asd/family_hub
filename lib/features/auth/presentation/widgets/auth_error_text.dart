import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/features/auth/presentation/auth_form_controller.dart';
import 'package:flutter/material.dart';

/// The one place an [AppFailure] becomes user-visible text.
///
/// A screen never inspects failure subtypes: it hands the failure here and gets
/// localized copy back.  That keeps the mapping in a single widget instead of
/// repeated `switch` statements across five screens, and it is what makes
/// "every [AppFailure] shown as a localized message" (Step 7) true by
/// construction rather than by discipline.
class AuthErrorText extends StatelessWidget {
  const AuthErrorText({required this.failure, super.key});

  final AppFailure failure;

  @override
  Widget build(BuildContext context) {
    final code = authFailureCode(failure);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.error_outline_rounded,
          size: 18,
          color: context.tokens.danger,
          semanticLabel: context.l10n.errorUnknown,
        ),
        const SizedBox(width: 8),
        // Flexible rather than a bare Text: a long Bangla sentence at a large
        // text scale must wrap instead of overflowing the row.
        Expanded(
          child: Text(
            context.l10n.authFailureMessage(code),
            style: TextStyle(color: context.tokens.danger, fontSize: 13),
            softWrap: true,
          ),
        ),
      ],
    );
  }
}

/// Informational banner (never an error): used for "still unverified" and
/// "email sent" confirmations.
class AuthInfoBanner extends StatelessWidget {
  const AuthInfoBanner({
    required this.message,
    this.icon = Icons.info_outline_rounded,
    this.tone = AuthInfoTone.neutral,
    super.key,
  });

  final String message;
  final IconData icon;
  final AuthInfoTone tone;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final (background, foreground) = switch (tone) {
      AuthInfoTone.neutral => (t.surfaceSunken, t.textPrimary),
      AuthInfoTone.success => (t.statusVerifiedContainer, t.statusVerifiedOn),
      AuthInfoTone.warning => (
          t.statusInProgressContainer,
          t.statusInProgressOn
        ),
    };

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(t.radiusMd),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: foreground),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: foreground, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tone for [AuthInfoBanner] — status is never conveyed by colour alone, so each
/// tone also comes with its own icon and message.
enum AuthInfoTone { neutral, success, warning }
