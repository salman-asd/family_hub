import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:flutter/material.dart';

class BellButton extends StatelessWidget {
  const BellButton({
    required this.semanticLabel,
    required this.count,
    required this.countText,
    required this.overflowText,
    required this.onPressed,
    this.tooltip,
    super.key,
  });

  final String semanticLabel;
  final int count;
  final String countText;
  final String overflowText;
  final VoidCallback onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final badgeText = count > 9 ? overflowText : countText;
    return Semantics(
      button: true,
      label: semanticLabel,
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        icon: Stack(
          clipBehavior: Clip.none,
          children: [
            const Icon(Icons.notifications_outlined),
            if (count > 0)
              Positioned(
                top: -7,
                right: -9,
                child: ExcludeSemantics(
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 18),
                    height: 18,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: tokens.danger,
                      borderRadius: BorderRadius.circular(tokens.radiusPill),
                    ),
                    child: Text(
                      badgeText,
                      style: TextStyle(
                        color: tokens.textOnAccent,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
