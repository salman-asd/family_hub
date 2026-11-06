import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:flutter/material.dart';

class FamilySettingsTile extends StatelessWidget {
  const FamilySettingsTile({
    required this.icon,
    required this.label,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Material(
      color: t.surface,
      borderRadius: BorderRadius.circular(t.radiusMd),
      child: InkWell(
        borderRadius: BorderRadius.circular(t.radiusMd),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(icon, color: t.accentStrong),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.bodyLarge
                        ?.copyWith(color: t.textPrimary),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: t.textSecondary,
                  textDirection: Directionality.of(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
