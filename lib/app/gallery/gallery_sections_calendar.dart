import 'package:family_hub/app/gallery/gallery_sections.dart';
import 'package:family_hub/core/localization/app_formatters.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/features/chores/calendar/domain/calendar_enums.dart';
import 'package:family_hub/features/chores/calendar/domain/day_summary.dart';
import 'package:family_hub/features/chores/calendar/presentation/painters/hatch_painter.dart';
import 'package:family_hub/features/chores/calendar/presentation/widgets/day_cell.dart';
import 'package:family_hub/features/chores/calendar/presentation/widgets/hatch_swatch.dart';
import 'package:family_hub/features/chores/calendar/presentation/widgets/heat_legend.dart';
import 'package:flutter/material.dart';

/// P3-24: the heat key, the two hatches and day cells in each decoration.
GallerySection calendarPolishSection = GallerySection(
  id: 'calendar_polish',
  label: (l10n) => l10n.galleryCalendarPolish,
  build: (context) {
    final f = AppFormatters(
      languageCode: Localizations.localeOf(context).languageCode,
      useBanglaDigits: Localizations.localeOf(context).languageCode == 'bn',
    );
    DaySummary day(
      int n, {
      int heat = 0,
      bool planned = false,
      Set<String> away = const <String>{},
      bool cover = false,
      bool attention = false,
    }) => DaySummary(
      dateKey: DateKey(2026, 10, n),
      heatLevel: heat,
      hasProjectedOnly: planned,
      unavailableMemberIds: away,
      hasNeedsCover: cover,
      hasNeedsAttention: attention,
    );
    final cells = <DaySummary>[
      day(1),
      day(2, heat: 1),
      day(3, heat: 4),
      day(4, planned: true),
      day(5, away: const <String>{'a'}),
      day(6, planned: true, away: const <String>{'a'}),
      day(7, cover: true, attention: true),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const HeatLegend(),
        const SizedBox(height: 8),
        const Wrap(
          spacing: 8,
          children: [
            HatchSwatch(directions: <HatchDirection>{HatchDirection.rising}),
            HatchSwatch(directions: <HatchDirection>{HatchDirection.falling}),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (final summary in cells)
              Expanded(
                child: DayCell(
                  summary: summary,
                  selected: summary.dateKey.day == 3,
                  scope: CalendarScope.all,
                  markerStyle: MarkerStyle.glyphs,
                  formatters: f,
                  minHeight: 56,
                  onTap: () {},
                  onLongPress: () {},
                ),
              ),
          ],
        ),
      ],
    );
  },
);
