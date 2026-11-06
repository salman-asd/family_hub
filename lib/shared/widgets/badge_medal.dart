import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:flutter/material.dart';

class BadgeMedal extends StatelessWidget {
  const BadgeMedal({
    required this.label,
    required this.statusLabel,
    required this.icon,
    this.description,
    this.earned = true,
    super.key,
  });

  final String label;
  final String statusLabel;
  final IconData icon;
  final String? description;
  final bool earned;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final foreground = earned ? tokens.statusVerifiedOn : tokens.textSecondary;
    final background = earned
        ? tokens.statusVerifiedContainer
        : tokens.surfaceSunken;
    return Semantics(
      container: true,
      label: [
        label,
        statusLabel,
        if (description != null) description,
      ].join(', '),
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: background,
              shape: BoxShape.circle,
              border: Border.all(color: foreground, width: 2),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(icon, color: foreground, size: 28),
                PositionedDirectional(
                  bottom: 1,
                  end: 1,
                  child: Icon(
                    earned ? Icons.check_circle_rounded : Icons.lock_rounded,
                    color: foreground,
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 112),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: tokens.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (description != null)
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 160),
              child: Text(
                description!,
                textAlign: TextAlign.center,
                style: TextStyle(color: tokens.textSecondary),
              ),
            ),
          Text(
            statusLabel,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: tokens.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
