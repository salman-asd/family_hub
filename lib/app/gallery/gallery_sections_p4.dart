import 'package:family_hub/app/gallery/gallery_sections.dart';
import 'package:family_hub/app/gallery/gallery_sections_p4_engagement.dart';
import 'package:family_hub/core/localization/app_formatters.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/shared/widgets/activity_tile.dart';
import 'package:family_hub/shared/widgets/alert_strip.dart';
import 'package:family_hub/shared/widgets/bell_button.dart';
import 'package:family_hub/shared/widgets/dashboard_card_frame.dart';
import 'package:family_hub/shared/widgets/greeting_header.dart';
import 'package:family_hub/shared/widgets/quiet_hours_picker.dart';
import 'package:family_hub/shared/widgets/stat_pill.dart';
import 'package:family_hub/shared/widgets/switch_tile_with_reason.dart';
import 'package:family_hub/shared/widgets/time_offset_chips.dart';
import 'package:flutter/material.dart';

List<GallerySection> phase4GallerySections() => <GallerySection>[
  GallerySection(
    id: 'dashboard_card_frame',
    label: (l10n) => l10n.galleryDashboardCardFrame,
    build: (context) {
      final l10n = context.l10n;
      return Column(
        children: [
          DashboardCardFrame(
            title: l10n.gallerySampleTitle,
            icon: Icons.insights_outlined,
            child: Text(l10n.gallerySampleMessage),
            onTap: () {},
          ),
          DashboardCardFrame(
            title: l10n.gallerySampleTitle,
            icon: Icons.insights_outlined,
            mode: DashboardCardMode.loading,
            loadingLabel: l10n.loadingSemantics,
            child: const SizedBox.shrink(),
          ),
          DashboardCardFrame(
            title: l10n.gallerySampleTitle,
            icon: Icons.insights_outlined,
            mode: DashboardCardMode.error,
            errorMessage: l10n.errorNetwork,
            onRetry: () {},
            child: const SizedBox.shrink(),
          ),
        ],
      );
    },
  ),
  GallerySection(
    id: 'greeting_header',
    label: (l10n) => l10n.galleryGreetingHeader,
    build: (context) => GreetingHeader(
      greeting: context.l10n.gallerySampleTitle,
      name: context.l10n.gallerySamplePersonName,
      subtitle: context.l10n.gallerySampleMessage,
    ),
  ),
  GallerySection(
    id: 'bell_button',
    label: (l10n) => l10n.galleryBellButton,
    build: (context) {
      final formatters = _formatters(context);
      return Wrap(
        spacing: 16,
        children: [
          BellButton(
            semanticLabel: context.l10n.gallerySampleTitle,
            count: 0,
            countText: formatters.number(0),
            overflowText: context.l10n.galleryBellOverflow,
            onPressed: () {},
          ),
          BellButton(
            semanticLabel: context.l10n.gallerySampleMessage,
            count: 12,
            countText: formatters.number(12),
            overflowText: context.l10n.galleryBellOverflow,
            onPressed: () {},
          ),
        ],
      );
    },
  ),
  GallerySection(
    id: 'alert_strip',
    label: (l10n) => l10n.galleryAlertStrip,
    build: (context) => Column(
      children: [
        AlertStrip(
          title: context.l10n.gallerySampleTitle,
          message: context.l10n.gallerySampleMessage,
          tone: AlertStripTone.info,
        ),
        AlertStrip(
          title: context.l10n.gallerySampleTitle,
          message: context.l10n.gallerySampleMessage,
          tone: AlertStripTone.warning,
          actionLabel: context.l10n.actionSave,
          onAction: () {},
        ),
      ],
    ),
  ),
  GallerySection(
    id: 'activity_tile',
    label: (l10n) => l10n.galleryActivityTile,
    build: (context) => ActivityTile(
      title: context.l10n.gallerySampleTitle,
      subtitle: context.l10n.gallerySampleMessage,
      leading: const CircleAvatar(child: Icon(Icons.person_outline_rounded)),
      timeLabel: context.l10n.calendarToday,
      onTap: () {},
    ),
  ),
  GallerySection(
    id: 'stat_pill',
    label: (l10n) => l10n.galleryStatPill,
    build: (context) => Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final tone in StatPillTone.values)
          StatPill(
            label: context.l10n.gallerySampleTitle,
            value: _formatters(context).number(12),
            icon: Icons.eco_outlined,
            tone: tone,
          ),
      ],
    ),
  ),
  GallerySection(
    id: 'time_offset_chips',
    label: (l10n) => l10n.galleryTimeOffsetChips,
    build: (context) {
      final f = _formatters(context);
      return TimeOffsetChips(
        options: const [15, 60, 1440],
        labels: {
          15: f.durationLabel(15),
          60: f.durationLabel(60),
          1440: f.durationLabel(1440),
        },
        selected: const {60},
        onChanged: (_) {},
      );
    },
  ),
  GallerySection(
    id: 'quiet_hours_picker',
    label: (l10n) => l10n.galleryQuietHoursPicker,
    build: (context) => QuietHoursPicker(
      startLabel: context.l10n.galleryQuietHoursStart,
      endLabel: context.l10n.galleryQuietHoursEnd,
      startMinutes: 22 * 60,
      endMinutes: 7 * 60,
      formatters: _formatters(context),
      onStartChanged: (_) {},
      onEndChanged: (_) {},
    ),
  ),
  GallerySection(
    id: 'switch_tile_with_reason',
    label: (l10n) => l10n.gallerySwitchTileWithReason,
    build: (context) => Column(
      children: [
        SwitchTileWithReason(
          title: context.l10n.gallerySampleTitle,
          subtitle: context.l10n.gallerySampleMessage,
          value: true,
          onChanged: (_) {},
        ),
        SwitchTileWithReason(
          title: context.l10n.gallerySampleTitle,
          value: false,
          disabledReason: context.l10n.gallerySampleMessage,
        ),
      ],
    ),
  ),
  ...phase4EngagementGallerySections(),
];

AppFormatters _formatters(BuildContext context) {
  final languageCode = Localizations.localeOf(context).languageCode;
  return AppFormatters(
    languageCode: languageCode,
    useBanglaDigits: languageCode == 'bn',
  );
}
