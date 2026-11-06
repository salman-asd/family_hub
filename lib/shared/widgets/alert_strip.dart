import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:flutter/material.dart';

enum AlertStripTone { info, success, warning, danger }

class AlertStrip extends StatelessWidget {
  const AlertStrip({
    required this.title,
    required this.message,
    required this.tone,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final String title;
  final String message;
  final AlertStripTone tone;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final (foreground, background, icon) = switch (tone) {
      AlertStripTone.info => (
        tokens.info,
        tokens.surfaceSunken,
        Icons.info_outline_rounded,
      ),
      AlertStripTone.success => (
        tokens.statusCompletedOn,
        tokens.statusCompletedContainer,
        Icons.check_circle_outline_rounded,
      ),
      AlertStripTone.warning => (
        tokens.statusOverdueOn,
        tokens.statusOverdueContainer,
        Icons.warning_amber_rounded,
      ),
      AlertStripTone.danger => (
        tokens.statusOverdueOn,
        tokens.statusOverdueContainer,
        Icons.error_outline_rounded,
      ),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(tokens.radiusMd),
        border: Border.all(color: foreground.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: foreground),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: foreground,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(message, style: TextStyle(color: tokens.textPrimary)),
                if (actionLabel != null && onAction != null)
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton(
                      onPressed: onAction,
                      child: Text(actionLabel!),
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
