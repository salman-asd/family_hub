import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:flutter/material.dart';

enum DiagnosticStatus { neutral, success, warning, failure }

class DiagnosticRow extends StatelessWidget {
  const DiagnosticRow({
    required this.label,
    required this.value,
    required this.statusLabel,
    this.status = DiagnosticStatus.neutral,
    super.key,
  });

  final String label;
  final String value;
  final DiagnosticStatus status;
  final String statusLabel;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final (icon, color) = switch (status) {
      DiagnosticStatus.neutral => (Icons.circle_outlined, tokens.textSecondary),
      DiagnosticStatus.success => (
        Icons.check_circle_outline_rounded,
        tokens.success,
      ),
      DiagnosticStatus.warning => (Icons.warning_amber_rounded, tokens.warning),
      DiagnosticStatus.failure => (Icons.error_outline_rounded, tokens.danger),
    };
    return Semantics(
      container: true,
      label: '$label, $value, $statusLabel',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(label, style: TextStyle(color: tokens.textPrimary)),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                '$value · $statusLabel',
                textAlign: TextAlign.end,
                style: TextStyle(color: tokens.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
