import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:flutter/material.dart';

enum AccessCellState { hidden, on, off, requiredAccess }

class AccessCell extends StatelessWidget {
  const AccessCell({
    required this.value,
    required this.labels,
    required this.onChanged,
    this.enabled = true,
    this.disabledReason,
    super.key,
  });

  final AccessCellState value;
  final Map<AccessCellState, String> labels;
  final ValueChanged<AccessCellState> onChanged;
  final bool enabled;
  final String? disabledReason;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    assert(
      AccessCellState.values.every(labels.containsKey),
      'Provide one localized label for every access state',
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final state in AccessCellState.values)
              _StateChip(
                state: state,
                label: labels[state]!,
                selected: state == value,
                enabled: enabled,
                onSelected: () => onChanged(state),
              ),
          ],
        ),
        if (!enabled && disabledReason != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
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

class _StateChip extends StatelessWidget {
  const _StateChip({
    required this.state,
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onSelected,
  });

  final AccessCellState state;
  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final (icon, foreground, background) = switch (state) {
      AccessCellState.hidden => (
        Icons.visibility_off_outlined,
        tokens.statusSkippedOn,
        tokens.statusSkippedContainer,
      ),
      AccessCellState.on => (
        Icons.visibility_outlined,
        tokens.statusCompletedOn,
        tokens.statusCompletedContainer,
      ),
      AccessCellState.off => (
        Icons.block_outlined,
        tokens.statusOverdueOn,
        tokens.statusOverdueContainer,
      ),
      AccessCellState.requiredAccess => (
        Icons.push_pin_outlined,
        tokens.statusVerifiedOn,
        tokens.statusVerifiedContainer,
      ),
    };
    return Semantics(
      container: true,
      label: label,
      selected: selected,
      enabled: enabled,
      button: true,
      onTap: enabled ? onSelected : null,
      excludeSemantics: true,
      child: ChoiceChip(
        avatar: Icon(icon, size: 18, color: foreground),
        label: Text(label),
        selected: selected,
        showCheckmark: true,
        selectedColor: background,
        labelStyle: TextStyle(color: foreground),
        materialTapTargetSize: MaterialTapTargetSize.padded,
        onSelected: enabled ? (_) => onSelected() : null,
      ),
    );
  }
}
