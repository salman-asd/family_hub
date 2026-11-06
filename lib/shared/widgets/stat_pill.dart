import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:flutter/material.dart';

enum StatPillTone { neutral, positive, attention }

class StatPill extends StatelessWidget {
  const StatPill({
    required this.label,
    required this.value,
    required this.icon,
    this.tone = StatPillTone.neutral,
    super.key,
  });

  final String label;
  final String value;
  final IconData icon;
  final StatPillTone tone;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final (foreground, background) = switch (tone) {
      StatPillTone.neutral => (tokens.accentStrong, tokens.accentSoft),
      StatPillTone.positive => (
        tokens.statusCompletedOn,
        tokens.statusCompletedContainer,
      ),
      StatPillTone.attention => (
        tokens.statusOverdueOn,
        tokens.statusOverdueContainer,
      ),
    };
    return Semantics(
      container: true,
      label: '$label, $value',
      excludeSemantics: true,
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(tokens.radiusPill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: foreground, size: 18),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                '$label: $value',
                style: TextStyle(
                  color: foreground,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
