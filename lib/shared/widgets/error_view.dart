import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/shared/widgets/empty_state.dart';
import 'package:flutter/material.dart';

/// "Something went wrong" content with an optional retry action (Step 11).
///
/// Built on [EmptyState] on purpose: an error and an empty list are the same
/// layout problem, so they share one implementation, one scroll-safety
/// guarantee and one accessibility story (an icon *and* text, never colour
/// alone).
///
/// [title] defaults to the localized "Something went wrong", so an error screen
/// shows a heading without the caller repeating copy.  [onRetry] is optional: a
/// permanent failure (for example "you are not allowed to see this") has
/// nothing to retry, and then no button is drawn.
class ErrorView extends StatelessWidget {
  const ErrorView({
    required this.message,
    this.title,
    this.onRetry,
    this.retryLabel,
    this.icon,
    super.key,
  });

  /// Localized, already-resolved explanation of what went wrong.
  final String message;

  /// Optional heading; defaults to the localized generic error title.
  final String? title;

  /// Called when the retry button is pressed; no button when null.
  final VoidCallback? onRetry;

  /// Localized retry button label; defaults to the generic "Retry".
  final String? retryLabel;

  /// Overrides the default error icon.
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final retry = onRetry;
    final label =
        retry == null ? null : (retryLabel ?? context.l10n.actionRetry);

    return EmptyState(
      icon: icon ?? Icons.error_outline_rounded,
      title: title ?? context.l10n.errorViewTitle,
      message: message,
      actionLabel: label,
      onAction: retry,
    );
  }
}
