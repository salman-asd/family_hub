import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:flutter/material.dart';

/// The standard raised container used across the app: token surfaces, token
/// shape radius and token elevation — no raw colors, no hard-coded radii.
class AppCard extends StatelessWidget {
  const AppCard({
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
    this.color,
    this.raised = false,
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;

  /// Optional token color override (e.g. [AppTokens.surfaceSunken]).
  final Color? color;

  /// Uses the elevated surface + elevation2 when true.
  final bool raised;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final surface = color ?? (raised ? t.surfaceRaised : t.surface);
    final shadows = raised ? t.elevation2 : t.elevation1;

    final content = Padding(padding: padding, child: child);

    return Padding(
      padding: margin,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(t.radiusMd),
          boxShadow: onTap == null ? shadows : null,
        ),
        child: onTap == null
            ? content
            : Material(
                color: surface,
                borderRadius: BorderRadius.circular(t.radiusMd),
                elevation: 0,
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(t.radiusMd),
                  child: content,
                ),
              ),
      ),
    );
  }
}
