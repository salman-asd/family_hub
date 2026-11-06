import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:flutter/material.dart';

class SwitchTileWithReason extends StatelessWidget {
  const SwitchTileWithReason({
    required this.title,
    required this.value,
    this.subtitle,
    this.disabledReason,
    this.onChanged,
    super.key,
  });

  final String title;
  final bool value;
  final String? subtitle;
  final String? disabledReason;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final disabled = onChanged == null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(title),
          subtitle: subtitle == null ? null : Text(subtitle!),
          value: value,
          onChanged: onChanged,
        ),
        if (disabled && disabledReason != null)
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 16, bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.lock_outline_rounded,
                  size: 18,
                  color: tokens.textSecondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    disabledReason!,
                    style: TextStyle(color: tokens.textSecondary),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
