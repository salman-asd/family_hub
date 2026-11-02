import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:family_hub/core/localization/app_formatters.dart';
import 'package:family_hub/features/chores/calendar/domain/calendar_enums.dart';
import 'package:family_hub/features/chores/calendar/domain/day_summary.dart';
import 'package:family_hub/features/chores/presentation/widgets/chore_tile.dart'
    show widgetStatusOf;
import 'package:family_hub/shared/widgets/status_glyph.dart';
import 'package:flutter/material.dart';

/// What a day cell shows for its chores (Appendix B.2): at most three status
/// glyphs and a "+N", or dots, or just a count - the person's marker style.
///
/// Glyphs are SHAPES (CLAUDE rule 13); dots and the count are the denser
/// options the person chose on purpose. The cell announces the day as one
/// label, so nothing in here is read separately.
class DayMarkers extends StatelessWidget {
  const DayMarkers({
    required this.summary,
    required this.style,
    required this.formatters,
    this.ink,
    super.key,
  });

  final DaySummary summary;
  final MarkerStyle style;
  final AppFormatters formatters;

  /// The colour of the "+N" and of the count; the secondary text colour when
  /// null. A heat-tinted cell passes the primary ink so the text stays at
  /// least 4.5:1 on the tint (P3-24).
  final Color? ink;

  @override
  Widget build(BuildContext context) {
    if (summary.isOutsideMonth || summary.total == 0) {
      return const SizedBox(height: 12);
    }
    final t = context.tokens;
    final picks = summary.markers;
    final Widget row = switch (style) {
      MarkerStyle.glyphs => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final status in picks.markers)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1),
              child: StatusGlyph(status: widgetStatusOf(status), size: 10),
            ),
          if (picks.extra > 0) _extra(ink ?? t.textSecondary, picks.extra),
        ],
      ),
      MarkerStyle.dots => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final status in picks.markers)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1.5),
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: StatusGlyph.statusColours(widgetStatusOf(status), t),
                ),
              ),
            ),
          if (picks.extra > 0) _extra(ink ?? t.textSecondary, picks.extra),
        ],
      ),
      MarkerStyle.count => Text(
        formatters.number(summary.total),
        maxLines: 1,
        style: TextStyle(
          color: ink ?? t.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    };
    return ExcludeSemantics(
      child: SizedBox(
        height: 12,
        child: FittedBox(fit: BoxFit.scaleDown, child: row),
      ),
    );
  }

  Widget _extra(Color colour, int extra) => Padding(
    padding: const EdgeInsetsDirectional.only(start: 2),
    child: Text(
      '+${formatters.number(extra)}',
      maxLines: 1,
      style: TextStyle(
        color: colour,
        fontSize: 12,
        fontWeight: FontWeight.w700,
        height: 1,
      ),
    ),
  );
}
