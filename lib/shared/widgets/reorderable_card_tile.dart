import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

class ReorderableCardTile extends StatelessWidget {
  const ReorderableCardTile({
    required this.index,
    required this.title,
    required this.dragLabel,
    required this.moveUpLabel,
    required this.moveDownLabel,
    this.value,
    this.onChanged,
    this.locked = false,
    this.lockedReason,
    this.onMoveUp,
    this.onMoveDown,
    super.key,
  });

  final int index;
  final String title;
  final String dragLabel;
  final String moveUpLabel;
  final String moveDownLabel;
  final bool? value;
  final ValueChanged<bool>? onChanged;
  final bool locked;
  final String? lockedReason;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final actions = <CustomSemanticsAction, VoidCallback>{};
    final moveUp = onMoveUp;
    final moveDown = onMoveDown;
    if (moveUp != null) {
      actions[CustomSemanticsAction(label: moveUpLabel)] = moveUp;
    }
    if (moveDown != null) {
      actions[CustomSemanticsAction(label: moveDownLabel)] = moveDown;
    }
    return Semantics(
      container: true,
      customSemanticsActions: actions,
      child: Material(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(tokens.radiusMd),
        child: Padding(
          padding: const EdgeInsetsDirectional.only(start: 4, end: 4),
          child: Row(
            children: [
              ReorderableDragStartListener(
                index: index,
                child: Semantics(
                  button: true,
                  label: dragLabel,
                  child: const SizedBox(
                    width: 48,
                    height: 48,
                    child: Icon(Icons.drag_handle_rounded),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: TextStyle(color: tokens.textPrimary)),
                      if (lockedReason != null)
                        Text(
                          lockedReason!,
                          style: TextStyle(color: tokens.textSecondary),
                        ),
                    ],
                  ),
                ),
              ),
              IconButton(
                tooltip: moveUpLabel,
                onPressed: onMoveUp,
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                icon: const Icon(Icons.arrow_upward_rounded),
              ),
              IconButton(
                tooltip: moveDownLabel,
                onPressed: onMoveDown,
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                icon: const Icon(Icons.arrow_downward_rounded),
              ),
              if (locked)
                Icon(Icons.lock_outline_rounded, color: tokens.textSecondary)
              else if (value != null)
                Switch(value: value!, onChanged: onChanged),
            ],
          ),
        ),
      ),
    );
  }
}
