import 'package:family_hub/app/gallery/gallery_sections.dart';
import 'package:family_hub/core/localization/app_formatters.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/shared/widgets/avatar_stack.dart';
import 'package:family_hub/shared/widgets/catalog_editor.dart';
import 'package:family_hub/shared/widgets/color_swatch_picker.dart';
import 'package:family_hub/shared/widgets/flag_chip.dart';
import 'package:family_hub/shared/widgets/mini_markdown_view.dart';
import 'package:family_hub/shared/widgets/minutes_field.dart';
import 'package:family_hub/shared/widgets/reason_sheet.dart';
import 'package:family_hub/shared/widgets/status_chip.dart';
import 'package:family_hub/shared/widgets/status_glyph.dart';
import 'package:family_hub/shared/widgets/step_progress.dart';
import 'package:family_hub/shared/widgets/weekday_chips.dart';
import 'package:flutter/material.dart';

/// The Phase 3 (P3-04) shared widgets, in every state. Appended to
/// [gallerySections], so each one gets a golden image and the 200 % overflow
/// test without a second list to maintain.
List<GallerySection> phase3GallerySections() => <GallerySection>[
  _statusGlyph,
  _flagChip,
  _stepProgress,
  _weekdayChips,
  _colorSwatchPicker,
  _minutesField,
  _avatarStack,
  _miniMarkdown,
  _catalogEditor,
  _reasonSheet,
];

GallerySection _statusGlyph = GallerySection(
  id: 'status_glyph',
  label: (l10n) => l10n.galleryStatusGlyph,
  build: (context) => Wrap(
    spacing: 16,
    runSpacing: 12,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      for (final size in StatusGlyph.allowedSizes)
        for (final status in WidgetStatus.values)
          StatusGlyph(status: status, size: size),
    ],
  ),
);

GallerySection _flagChip = GallerySection(
  id: 'flag_chip',
  label: (l10n) => l10n.galleryFlagChip,
  build: (context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      for (final flag in ChoreFlag.values) FlagChip(flag: flag),
      for (final flag in ChoreFlag.values) FlagChip(flag: flag, compact: true),
    ],
  ),
);

GallerySection _stepProgress = GallerySection(
  id: 'step_progress',
  label: (l10n) => l10n.galleryStepProgress,
  build: (context) {
    final f = _formatters(context);
    return Wrap(
      spacing: 16,
      runSpacing: 12,
      children: [
        StepProgress(done: 0, total: 5, formatters: f),
        StepProgress(done: 2, total: 5, formatters: f),
        StepProgress(done: 5, total: 5, formatters: f),
        // An empty subtask list and an out-of-range value must not crash.
        StepProgress(done: 0, total: 0, formatters: f),
        StepProgress(done: 7, total: 3, formatters: f, size: 28),
      ],
    );
  },
);

GallerySection _weekdayChips = GallerySection(
  id: 'weekday_chips',
  label: (l10n) => l10n.galleryWeekdayChips,
  build: (context) {
    final f = _formatters(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Saturday first (the family default) with two days picked.
        WeekdayChips(selected: const {6, 7}, onChanged: (_) {}, formatters: f),
        const SizedBox(height: 8),
        // Sunday first, nothing picked.
        WeekdayChips(
          selected: const {},
          onChanged: (_) {},
          formatters: f,
          weekStartDay: DateTime.sunday,
        ),
        const SizedBox(height: 8),
        // Disabled.
        WeekdayChips(
          selected: const {1, 3, 5},
          onChanged: (_) {},
          formatters: f,
          enabled: false,
        ),
      ],
    );
  },
);

GallerySection _colorSwatchPicker = GallerySection(
  id: 'color_swatch_picker',
  label: (l10n) => l10n.galleryColorSwatchPicker,
  build: (context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      ColorSwatchPicker(selectedIndex: 0, onChanged: (_) {}),
      const SizedBox(height: 8),
      ColorSwatchPicker(selectedIndex: 7, onChanged: (_) {}),
      const SizedBox(height: 8),
      ColorSwatchPicker(selectedIndex: 3, onChanged: (_) {}, enabled: false),
    ],
  ),
);

GallerySection _minutesField = GallerySection(
  id: 'minutes_field',
  label: (l10n) => l10n.galleryMinutesField,
  build: (context) {
    final f = _formatters(context);
    return Column(
      children: [
        MinutesField(
          label: context.l10n.gallerySampleDueTime,
          minutes: 9 * 60 + 15,
          formatters: f,
          onChanged: (_) {},
        ),
        const SizedBox(height: 12),
        // No time set: due by the end of the day.
        MinutesField(
          label: context.l10n.gallerySampleDueTime,
          minutes: null,
          formatters: f,
          onChanged: (_) {},
        ),
        const SizedBox(height: 12),
        MinutesField(
          label: context.l10n.gallerySampleDueTime,
          minutes: 21 * 60 + 45,
          formatters: f,
          onChanged: (_) {},
          enabled: false,
        ),
      ],
    );
  },
);

GallerySection _avatarStack = GallerySection(
  id: 'avatar_stack',
  label: (l10n) => l10n.galleryAvatarStack,
  build: (context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      AvatarStack(
        members: _people.take(3).toList(),
        overflowSemanticLabel: avatarStackLabel(context, _people[0].name, 2),
      ),
      const SizedBox(height: 12),
      // More than fit: the "+N" bubble appears.
      AvatarStack(
        members: _people,
        overflowSemanticLabel: avatarStackLabel(
          context,
          _people[0].name,
          _people.length - 4,
        ),
        onOverflowTap: () {},
      ),
      const SizedBox(height: 12),
      // Empty: renders nothing (no gap, no error).
      const AvatarStack(members: []),
    ],
  ),
);

GallerySection _miniMarkdown = GallerySection(
  id: 'mini_markdown',
  label: (l10n) => l10n.galleryMiniMarkdown,
  build: (context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      MiniMarkdownView(markdown: context.l10n.gallerySampleRules),
      const SizedBox(height: 12),
      // Unclosed bold and unknown syntax: rendered as plain text.
      const MiniMarkdownView(markdown: '**unclosed and <b>html</b> [link](x)'),
      const SizedBox(height: 12),
      // Empty source: the caller's empty text, or nothing.
      MiniMarkdownView(
        markdown: '   ',
        emptyText: context.l10n.emptyGenericMessage,
      ),
    ],
  ),
);

GallerySection _catalogEditor = GallerySection(
  id: 'catalog_editor',
  label: (l10n) => l10n.galleryCatalogEditor,
  build: (context) {
    final l10n = context.l10n;
    return Column(
      children: [
        CatalogEditor(
          title: l10n.catalogEditorActions,
          entries: const [
            CatalogEntry(id: 'kitchen', labelBn: 'রান্নাঘর', builtIn: true),
            CatalogEntry(
              id: 'sick',
              labelBn: 'অসুস্থ',
              labelEn: 'Sick',
              builtIn: true,
            ),
            CatalogEntry(
              id: 'custom_1',
              labelBn: 'অতিরিক্ত কাজ',
              active: false,
              detail: '07:00',
            ),
          ],
          onChanged: (_) {},
        ),
        const SizedBox(height: 16),
        CatalogEditor(entries: const [], onChanged: (_) {}),
      ],
    );
  },
);

/// The reason sheet is a modal, so the gallery shows a button that opens it —
/// the golden captures the trigger, the widget test covers the sheet itself.
GallerySection _reasonSheet = GallerySection(
  id: 'reason_sheet',
  label: (l10n) => l10n.galleryReasonSheet,
  build: (context) => FilledButton(
    onPressed: () => showReasonSheet(context, title: context.l10n.actionEdit),
    child: Text(context.l10n.galleryOpenSheet),
  ),
);

// ── Sample values ─────────────────────────────────────────────────────────────

final List<AvatarStackMember> _people = [
  const AvatarStackMember(id: 'u1', name: 'Rina'),
  const AvatarStackMember(id: 'u2', name: 'Karim'),
  const AvatarStackMember(id: 'u3', name: 'Sumi'),
  const AvatarStackMember(id: 'u4', name: 'Babul'),
  const AvatarStackMember(id: 'u5', name: 'Nila'),
  const AvatarStackMember(id: 'u6', name: 'Rafiq'),
];

/// The formatters the app would use for this language. The gallery renders in
/// both locales, so the sample text follows the active one.
AppFormatters _formatters(BuildContext context) =>
    context.l10n.localeName == 'bn'
    ? const AppFormatters(languageCode: 'bn', useBanglaDigits: true)
    : const AppFormatters(languageCode: 'en', useBanglaDigits: false);
