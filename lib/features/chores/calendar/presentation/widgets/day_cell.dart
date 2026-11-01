import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:family_hub/core/localization/app_formatters.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/features/chores/calendar/domain/calendar_enums.dart';
import 'package:family_hub/features/chores/calendar/domain/day_summary.dart';
import 'package:family_hub/features/chores/calendar/presentation/widgets/day_cell_label.dart';
import 'package:family_hub/features/chores/calendar/presentation/widgets/day_markers.dart';
import 'package:flutter/material.dart';

/// One day of the month grid (Appendix B.2).
///
/// * the date number in a pill: TODAY = a 2 dp ring, SELECTED = a filled pill
///   (two different shapes, so neither depends on colour);
/// * the markers row ([DayMarkers]);
/// * a small person mark when some of the day's chores are the viewer's own
///   while the whole family is shown;
/// * a day outside the month is dimmed and has no markers (D-P3-8).
///
/// The whole cell is one button of at least [minHeight] dp that announces
/// [dayCellLabel] as ONE sentence.
class DayCell extends StatelessWidget {
  const DayCell({
    required this.summary,
    required this.selected,
    required this.scope,
    required this.markerStyle,
    required this.formatters,
    required this.minHeight,
    required this.onTap,
    required this.onLongPress,
    super.key,
  });

  final DaySummary summary;
  final bool selected;
  final CalendarScope scope;
  final MarkerStyle markerStyle;
  final AppFormatters formatters;
  final double minHeight;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final outside = summary.isOutsideMonth;
    final numberColour = outside
        ? t.textDisabled
        : selected
        ? t.accentStrong
        : t.textPrimary;
    final label = dayCellLabel(
      l10n: context.l10n,
      formatters: formatters,
      summary: summary,
      selected: selected,
    );
    final showMine =
        !outside && scope == CalendarScope.all && summary.mineCount > 0;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      onLongPress: onLongPress,
      child: InkWell(
        key: ValueKey<String>('calendar_day_${summary.dateKey}'),
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(t.radiusMd),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: minHeight),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    Container(
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: selected ? t.accentSoft : null,
                        borderRadius: BorderRadius.circular(t.radiusPill),
                        border: summary.isToday
                            ? Border.all(color: t.accent, width: 2)
                            : null,
                      ),
                      child: Text(
                        formatters.number(summary.dateKey.day),
                        maxLines: 1,
                        style: TextStyle(
                          color: numberColour,
                          fontSize: 14,
                          fontWeight: selected || summary.isToday
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                    if (showMine)
                      PositionedDirectional(
                        top: -2,
                        end: -2,
                        child: ExcludeSemantics(
                          child: Icon(
                            Icons.person_rounded,
                            size: 12,
                            color: t.accent,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                DayMarkers(
                  summary: summary,
                  style: markerStyle,
                  formatters: formatters,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
