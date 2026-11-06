import 'package:flutter/material.dart';

class TimeOffsetChips extends StatelessWidget {
  const TimeOffsetChips({
    required this.options,
    required this.labels,
    required this.selected,
    required this.onChanged,
    this.enabled = true,
    super.key,
  }) : assert(options.length <= 5, 'At most five reminder offsets are allowed');

  final List<int> options;
  final Map<int, String> labels;
  final Set<int> selected;
  final ValueChanged<Set<int>> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    assert(
      options.every(labels.containsKey),
      'Every reminder offset needs a localized label',
    );
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final offset in options)
          FilterChip(
            key: ValueKey<int>(offset),
            label: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 32),
              child: Center(child: Text(labels[offset]!)),
            ),
            selected: selected.contains(offset),
            showCheckmark: true,
            materialTapTargetSize: MaterialTapTargetSize.padded,
            onSelected: enabled ? (_) => _toggle(offset) : null,
          ),
      ],
    );
  }

  void _toggle(int offset) {
    final next = <int>{...selected};
    if (!next.remove(offset)) next.add(offset);
    onChanged(next);
  }
}
