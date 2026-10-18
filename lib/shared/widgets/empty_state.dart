import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:flutter/material.dart';

/// Friendly "nothing here" content: an illustration slot, a title, a message
/// and an optional primary action.  Also used by gate and module placeholder screens.
///
/// Token-driven and scroll-safe: it centers on a tall screen and scrolls when
/// the text is large (200% font scale, long Bangla copy) instead of overflowing.
class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.title,
    this.message,
    this.icon,
    this.illustration,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final String title;
  final String? message;

  /// Simple icon shown when no [illustration] is given.
  final IconData? icon;

  /// Custom artwork; wins over [icon].
  final Widget? illustration;

  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final textTheme = Theme.of(context).textTheme;

    final art = illustration ??
        (icon == null
            ? null
            : Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: t.accentSoft,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 40, color: t.accentStrong),
              ));

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight.isFinite
                  ? (constraints.maxHeight - 48)
                      .clamp(0.0, double.infinity)
                      .toDouble()
                  : 0.0,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (art != null) ...[
                      ExcludeSemantics(child: art),
                      const SizedBox(height: 20),
                    ],
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: textTheme.titleLarge
                          ?.copyWith(color: t.textPrimary),
                    ),
                    if (message != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        message!,
                        textAlign: TextAlign.center,
                        style: textTheme.bodyMedium
                            ?.copyWith(color: t.textSecondary),
                      ),
                    ],
                    if (actionLabel != null && onAction != null) ...[
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: onAction,
                        child: Text(actionLabel!),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
