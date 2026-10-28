import 'package:family_hub/core/localization/app_formatters.dart';
import 'package:flutter/material.dart';

/// Picks any number of weekdays, shown in the family's week order (P3-04).
///
/// Weekdays use `DateTime` numbering (1 = Monday … 7 = Sunday) because that is
/// what the recurrence and rotation shapes store. [weekStartDay] rotates the
/// chips only: start 6 (Saturday, the family default) shows
/// `[6, 7, 1, 2, 3, 4, 5]`.
///
/// Selected days carry a check mark as well as a fill, so the state does not
/// depend on colour alone; each chip is a ≥ 48 dp target.
class WeekdayChips extends StatelessWidget {
  const WeekdayChips({
    required this.selected,
    required this.onChanged,
    required this.formatters,
    this.weekStartDay = DateTime.saturday,
    this.enabled = true,
    super.key,
  });

  /// The selected weekdays (1 … 7), in any order; stored sorted by the caller.
  final Set<int> selected;

  /// Called with the whole new selection whenever a chip is toggled.
  final ValueChanged<Set<int>> onChanged;

  final AppFormatters formatters;
  final int weekStartDay;
  final bool enabled;

  /// Weekdays top to bottom for [weekStartDay] (1 = Monday … 7 = Sunday).
  static List<int> order(int weekStartDay) {
    assert(
      weekStartDay >= DateTime.monday && weekStartDay <= DateTime.sunday,
      'weekStartDay must be 1..7',
    );
    return <int>[for (var i = 0; i < 7; i++) (weekStartDay - 1 + i) % 7 + 1];
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final day in order(weekStartDay))
          FilterChip(
            key: ValueKey<int>(day),
            label: ConstrainedBox(
              // 48 dp is the minimum touch target; the label may still grow.
              constraints: const BoxConstraints(minHeight: 48 - 16),
              child: Center(
                widthFactor: 1,
                child: Text(formatters.weekdayShort(day)),
              ),
            ),
            visualDensity: VisualDensity.standard,
            materialTapTargetSize: MaterialTapTargetSize.padded,
            selected: selected.contains(day),
            showCheckmark: true,
            onSelected: enabled ? (_) => _toggle(day) : null,
          ),
      ],
    );
  }

  void _toggle(int day) {
    final next = <int>{...selected};
    if (!next.remove(day)) next.add(day);
    onChanged(next);
  }
}
