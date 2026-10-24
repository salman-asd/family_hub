import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:flutter/material.dart';

/// What a [PermissionGate] does when the viewer may not use the action.
enum PermissionGateMode {
  /// The action is not rendered at all.
  hide,

  /// The action stays visible but cannot be used, with an explanation.
  disable,
}

/// Shows or enables [child] only when [allowed] is true (Step 10).
///
/// The gate never decides anything itself: the caller asks
/// `PermissionPolicy.can(...)` (or reads its own `Role`) and passes the answer
/// in.  That keeps one matrix in the whole app, and keeps the widget free of
/// Firebase and of feature imports.
///
/// Accessibility (rule 13): a blocked action is announced to assistive
/// technology, the reason is an icon *plus* a localized label (never colour
/// alone), and the child keeps its own size and 48dp targets.
class PermissionGate extends StatelessWidget {
  const PermissionGate({
    required this.allowed,
    required this.child,
    this.mode = PermissionGateMode.hide,
    this.deniedMessage,
    super.key,
  });

  /// Whether the viewer may use the action.
  final bool allowed;

  /// The action itself.
  final Widget child;

  final PermissionGateMode mode;

  /// Already-localized explanation, shown in [PermissionGateMode.disable].
  ///
  /// Passed in rather than looked up so the widget owns no copy and no ARB key
  /// is needed just to render a gate.
  final String? deniedMessage;

  /// Dimming applied to a blocked action; low enough to read as "not now",
  /// high enough to stay legible.
  static const double disabledOpacity = 0.4;

  @override
  Widget build(BuildContext context) {
    if (allowed) return child;
    if (mode == PermissionGateMode.hide) return const SizedBox.shrink();

    final tokens = context.tokens;
    final blocked = Opacity(
      opacity: disabledOpacity,
      child: IgnorePointer(child: ExcludeSemantics(child: child)),
    );

    final message = deniedMessage;
    if (message == null) {
      return Semantics(container: true, enabled: false, child: blocked);
    }

    // excludeSemantics: the message is announced once, from this node.  The
    // child copy of it would otherwise be merged in and read twice.
    return Semantics(
      container: true,
      enabled: false,
      label: message,
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          blocked,
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_outline, size: 16, color: tokens.textSecondary),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    message,
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: tokens.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
