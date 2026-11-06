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
        // P4-23: the tile paints its ink on the nearest Material, so on a
        // background that is a plain ColoredBox the splash and the checked
        // strip disappear. Owning a transparent Material makes the widget safe
        // wherever it is placed.
        Material(
          type: MaterialType.transparency,
          child: SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(title),
            subtitle: subtitle == null ? null : Text(subtitle!),
            value: value,
            onChanged: onChanged,
          ),
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
