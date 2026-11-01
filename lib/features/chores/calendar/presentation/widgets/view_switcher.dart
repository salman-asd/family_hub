import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/features/chores/calendar/domain/calendar_enums.dart';
import 'package:flutter/material.dart';

/// Agenda / Month / Week (B.2). The order is the enum's; the labels come from
/// ARB. [enabled] lists the views that exist yet: the others are shown but
/// cannot be chosen (Agenda and Week arrive with P3-23).
class ViewSwitcher extends StatelessWidget {
  const ViewSwitcher({
    required this.selected,
    required this.enabled,
    required this.onChanged,
    super.key,
  });

  final CalendarView selected;
  final Set<CalendarView> enabled;
  final ValueChanged<CalendarView> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    String label(CalendarView view) => switch (view) {
      CalendarViewKind.agenda => l10n.choresCalendarViewAgenda,
      CalendarViewKind.month => l10n.choresCalendarViewMonth,
      CalendarViewKind.week => l10n.choresCalendarViewWeek,
    };
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SegmentedButton<CalendarView>(
        key: const Key('calendar_view_switcher'),
        showSelectedIcon: false,
        segments: [
          for (final view in CalendarViewKind.values)
            ButtonSegment<CalendarView>(
              value: view,
              label: Text(label(view)),
              enabled: enabled.contains(view),
            ),
        ],
        selected: <CalendarView>{selected},
        onSelectionChanged: (set) => onChanged(set.first),
      ),
    );
  }
}
