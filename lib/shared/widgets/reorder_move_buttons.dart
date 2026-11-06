import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

/// Rule 71 says a drag must have a non-drag way round it, and TalkBack cannot
/// drag at all. Every `ReorderableListView` row can end its handle with these
/// two buttons: they move the row for a pointer and expose the same two
/// commands as custom semantics actions for a screen reader.
///
/// The caller passes a null callback for a direction the row cannot move in -
/// the top row has no "move up" - so the button stays visible and disabled
/// instead of making the row jump sideways.
class ReorderMoveButtons extends StatelessWidget {
  const ReorderMoveButtons({
    required this.index,
    this.onMoveUp,
    this.onMoveDown,
    super.key,
  });

  /// The row's position, used to key the buttons and to label them for TalkBack.
  final int index;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (onMoveUp == null && onMoveDown == null) {
      return const SizedBox.shrink();
    }
    final actions = <CustomSemanticsAction, VoidCallback>{};
    final moveUp = onMoveUp;
    final moveDown = onMoveDown;
    if (moveUp != null) {
      actions[CustomSemanticsAction(label: l10n.actionMoveUp)] = moveUp;
    }
    if (moveDown != null) {
      actions[CustomSemanticsAction(label: l10n.actionMoveDown)] = moveDown;
    }

    return Semantics(
      container: true,
      customSemanticsActions: actions,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            key: ValueKey('move_up_$index'),
            tooltip: l10n.actionMoveUp,
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            onPressed: moveUp,
            icon: const Icon(Icons.arrow_upward_rounded),
          ),
          IconButton(
            key: ValueKey('move_down_$index'),
            tooltip: l10n.actionMoveDown,
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            onPressed: moveDown,
            icon: const Icon(Icons.arrow_downward_rounded),
          ),
        ],
      ),
    );
  }
}
