import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:flutter/material.dart';

enum DeliveryMode { normal, push }

class DeliveryModeTile extends StatelessWidget {
  const DeliveryModeTile({
    required this.title,
    required this.mode,
    required this.normalLabel,
    required this.pushLabel,
    required this.onChanged,
    this.recommended = false,
    this.recommendedLabel,
    this.locked = false,
    this.lockedReason,
    super.key,
  });

  final String title;
  final DeliveryMode mode;
  final String normalLabel;
  final String pushLabel;
  final ValueChanged<DeliveryMode> onChanged;
  final bool recommended;
  final String? recommendedLabel;
  final bool locked;
  final String? lockedReason;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              title,
              style: TextStyle(
                color: tokens.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (recommended && recommendedLabel != null)
              Chip(
                avatar: Icon(
                  Icons.recommend_outlined,
                  size: 18,
                  color: tokens.accentStrong,
                ),
                label: Text(recommendedLabel!),
              ),
            if (locked)
              Icon(Icons.lock_outline_rounded, color: tokens.textSecondary),
          ],
        ),
        const SizedBox(height: 8),
        SegmentedButton<DeliveryMode>(
          segments: [
            ButtonSegment(
              value: DeliveryMode.normal,
              label: Text(normalLabel),
              icon: const Icon(Icons.notifications_none_rounded),
            ),
            ButtonSegment(
              value: DeliveryMode.push,
              label: Text(pushLabel),
              icon: const Icon(Icons.notifications_active_outlined),
            ),
          ],
          selected: {mode},
          onSelectionChanged: locked
              ? null
              : (selection) => onChanged(selection.first),
        ),
        if (locked && lockedReason != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              lockedReason!,
              style: TextStyle(color: tokens.textSecondary),
            ),
          ),
      ],
    );
  }
}
