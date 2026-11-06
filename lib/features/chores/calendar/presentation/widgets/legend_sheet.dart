import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/features/chores/calendar/presentation/painters/hatch_painter.dart';
import 'package:family_hub/features/chores/calendar/presentation/widgets/day_corner_marks.dart';
import 'package:family_hub/features/chores/calendar/presentation/widgets/hatch_swatch.dart';
import 'package:family_hub/features/chores/calendar/presentation/widgets/heat_legend.dart';
import 'package:family_hub/features/chores/occurrences/domain/occurrence_status.dart';
import 'package:family_hub/features/chores/presentation/widgets/chore_tile.dart'
    show statusLabelOf, widgetStatusOf;
import 'package:family_hub/shared/widgets/status_glyph.dart';
import 'package:flutter/material.dart';

/// "What the symbols mean": every status shape, the hatch and corner marks of
/// a day cell, and the heat key (B.3, B.7).
Future<void> showLegendSheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => const LegendSheet(),
    );

class LegendSheet extends StatelessWidget {
  const LegendSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              header: true,
              child: Text(l10n.calendarLegend, style: textTheme.titleMedium),
            ),
            const SizedBox(height: 8),
            for (final status in ChoreStatus.values)
              _LegendRow(
                leading: StatusGlyph(status: widgetStatusOf(status), size: 18),
                text: statusLabelOf(status, l10n),
              ),
            const SizedBox(height: 8),
            Semantics(
              header: true,
              child: Text(
                l10n.calendarLegendMarks,
                style: textTheme.titleSmall,
              ),
            ),
            _LegendRow(
              leading: const HatchSwatch(
                directions: <HatchDirection>{HatchDirection.rising},
                size: 24,
              ),
              text: l10n.calendarLegendPlanned,
            ),
            _LegendRow(
              leading: const HatchSwatch(
                directions: <HatchDirection>{HatchDirection.falling},
                size: 24,
              ),
              text: l10n.calendarLegendAway,
            ),
            _LegendRow(
              leading: const DayCornerMark(cover: true),
              text: l10n.calendarCellNeedsCover,
            ),
            _LegendRow(
              leading: const DayCornerMark(cover: false),
              text: l10n.calendarCellNeedsAttention,
            ),
            const SizedBox(height: 8),
            Semantics(
              header: true,
              child: Text(l10n.calendarHeatLegend, style: textTheme.titleSmall),
            ),
            const SizedBox(height: 4),
            const HeatLegend(),
          ],
        ),
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({required this.leading, required this.text});

  final Widget leading;
  final String text;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: Row(
        children: [
          SizedBox(width: 28, child: Center(child: leading)),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
