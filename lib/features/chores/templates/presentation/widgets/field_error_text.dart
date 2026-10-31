import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:flutter/material.dart';

/// One inline validation message under the field it belongs to (P3-16).
class FieldErrorText extends StatelessWidget {
  const FieldErrorText({required this.message, super.key});

  /// Already localized; null draws nothing.
  final String? message;

  @override
  Widget build(BuildContext context) {
    final text = message;
    if (text == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 6, left: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 16,
            color: context.tokens.danger,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              text,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: context.tokens.danger),
            ),
          ),
        ],
      ),
    );
  }
}
