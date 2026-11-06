import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:flutter/material.dart';

class ActivityTile extends StatelessWidget {
  const ActivityTile({
    required this.title,
    required this.subtitle,
    this.leading,
    this.timeLabel,
    this.onTap,
    super.key,
  });

  final String title;
  final String subtitle;
  final Widget? leading;
  final String? timeLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Semantics(
      container: true,
      button: onTap != null,
      label: [title, subtitle, if (timeLabel != null) timeLabel].join(', '),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(tokens.radiusMd),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (leading != null) ...[
                ExcludeSemantics(child: leading!),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: tokens.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(color: tokens.textSecondary),
                    ),
                  ],
                ),
              ),
              if (timeLabel != null) ...[
                const SizedBox(width: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 96),
                  child: Text(
                    timeLabel!,
                    textAlign: TextAlign.end,
                    style: TextStyle(color: tokens.textSecondary),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
