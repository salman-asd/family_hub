import 'package:flutter/material.dart';

/// One option of a [ChoiceWrap].
class ChoiceOption<T> {
  const ChoiceOption(this.value, this.label, {this.key});

  final T value;
  final String label;
  final Key? key;
}

/// Single-choice chips that wrap onto several lines (no dropdown, so long
/// Bangla labels and large text scales just flow).  Selection is shown by a
/// check mark as well as colour.
class ChoiceWrap<T> extends StatelessWidget {
  const ChoiceWrap({
    required this.options,
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final List<ChoiceOption<T>> options;
  final T? selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        for (final o in options)
          ChoiceChip(
            key: o.key,
            label: Text(o.label),
            selected: o.value == selected,
            showCheckmark: true,
            onSelected: (_) => onChanged(o.value),
          ),
      ],
    );
  }
}
