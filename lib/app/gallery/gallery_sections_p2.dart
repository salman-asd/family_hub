import 'package:family_hub/app/gallery/gallery_sections.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/core/utils/money.dart';
import 'package:family_hub/shared/widgets/amount_field.dart';
import 'package:family_hub/shared/widgets/category_badge.dart';
import 'package:family_hub/shared/widgets/day_section_header.dart';
import 'package:family_hub/shared/widgets/month_switcher.dart';
import 'package:family_hub/shared/widgets/person_picker.dart';
import 'package:family_hub/shared/widgets/progress_bar_status.dart';
import 'package:family_hub/shared/widgets/total_display.dart';
import 'package:flutter/material.dart';

/// The Phase 2 (P2-12) shared widgets, in every state.  Appended to
/// [gallerySections], so each one gets goldens and the 200 % overflow test.
List<GallerySection> phase2GallerySections() => <GallerySection>[
  _monthSwitcher,
  _amountField,
  _totalDisplay,
  _progressBar,
  _dayHeader,
  _personPicker,
  _categoryBadge,
];

final MonthKey _sampleMonth = MonthKey(2026, 10);

final GallerySection _monthSwitcher = GallerySection(
  id: 'month_switcher',
  label: (l10n) => l10n.galleryMonthSwitcher,
  build: (context) => Column(
    children: [
      MonthSwitcher(month: _sampleMonth, onChanged: (_) {}),
      // At the lower bound: the back arrow is disabled.
      MonthSwitcher(
        month: _sampleMonth,
        min: _sampleMonth,
        onChanged: (_) {},
      ),
      // At the upper bound: the forward arrow is disabled.
      MonthSwitcher(
        month: _sampleMonth,
        max: _sampleMonth,
        onChanged: (_) {},
      ),
      // The longest Bangla month name.
      MonthSwitcher(month: MonthKey(2026, 2), onChanged: (_) {}),
    ],
  ),
);

final GallerySection _amountField = GallerySection(
  id: 'amount_field',
  label: (l10n) => l10n.galleryAmountField,
  build: (context) => const _AmountSamples(),
);

class _AmountSamples extends StatefulWidget {
  const _AmountSamples();

  @override
  State<_AmountSamples> createState() => _AmountSamplesState();
}

class _AmountSamplesState extends State<_AmountSamples> {
  final _empty = TextEditingController();
  final _filled = TextEditingController(text: '1250.50');
  final _bangla = TextEditingController(text: '১২৩.৫০');
  final _quantity = TextEditingController(text: '1.500');

  @override
  void dispose() {
    _empty.dispose();
    _filled.dispose();
    _bangla.dispose();
    _quantity.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AmountField(controller: _empty, label: l10n.gallerySampleTitle),
        const SizedBox(height: 12),
        AmountField(controller: _filled, label: l10n.gallerySampleTitle),
        const SizedBox(height: 12),
        AmountField(
          controller: _bangla,
          label: l10n.gallerySampleTitle,
          errorText: l10n.gallerySampleMessage,
        ),
        const SizedBox(height: 12),
        AmountField(
          controller: _quantity,
          label: l10n.gallerySampleTitle,
          scale: 3,
        ),
        const SizedBox(height: 12),
        AmountField(
          controller: _filled,
          label: l10n.gallerySampleTitle,
          enabled: false,
        ),
      ],
    );
  }
}

final GallerySection _totalDisplay = GallerySection(
  id: 'total_display',
  label: (l10n) => l10n.galleryTotalDisplay,
  build: (context) {
    final label = context.l10n.gallerySampleTitle;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TotalDisplay(total: null, label: label),
        const SizedBox(height: 16),
        TotalDisplay(total: const Money.paisa(125050), label: label),
        const SizedBox(height: 16),
        TotalDisplay(
          total: const Money.paisa(123456789),
          label: label,
          calculated: true,
        ),
      ],
    );
  },
);

final GallerySection _progressBar = GallerySection(
  id: 'progress_bar_status',
  label: (l10n) => l10n.galleryProgressBarStatus,
  build: (context) {
    final label = context.l10n.gallerySampleItemName;
    final trailing = context.l10n.gallerySampleTitle;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ProgressBarStatus(
          basisPoints: 0,
          level: ProgressLevel.ok,
          label: label,
        ),
        const SizedBox(height: 12),
        ProgressBarStatus(
          basisPoints: 7900,
          level: ProgressLevel.ok,
          label: label,
          trailing: trailing,
        ),
        const SizedBox(height: 12),
        ProgressBarStatus(
          basisPoints: 8000,
          level: ProgressLevel.warning,
          label: label,
        ),
        const SizedBox(height: 12),
        ProgressBarStatus(
          basisPoints: 10000,
          level: ProgressLevel.exceeded,
          label: label,
        ),
        const SizedBox(height: 12),
        // Past the limit: the bar stops at 100 % and shows the overflow tick.
        ProgressBarStatus(
          basisPoints: 14000,
          level: ProgressLevel.exceeded,
          label: label,
          trailing: trailing,
        ),
        const SizedBox(height: 12),
        // No limit configured.
        ProgressBarStatus(
          basisPoints: null,
          level: ProgressLevel.ok,
          label: label,
        ),
      ],
    );
  },
);

final GallerySection _dayHeader = GallerySection(
  id: 'day_section_header',
  label: (l10n) => l10n.galleryDaySectionHeader,
  build: (context) {
    final long =
        '${context.l10n.gallerySampleTitle} ${context.l10n.gallerySampleMessage}';
    return Column(
      children: [
        DaySectionHeader(
          dateLabel: context.l10n.gallerySampleTitle,
          total: const Money.paisa(85000),
        ),
        DaySectionHeader(dateLabel: long, total: const Money.paisa(123456789)),
      ],
    );
  },
);

final GallerySection _personPicker = GallerySection(
  id: 'person_picker',
  label: (l10n) => l10n.galleryPersonPicker,
  build: (context) {
    final label = context.l10n.gallerySampleTitle;
    final name = context.l10n.gallerySamplePersonName;
    final people = <PersonOption>[
      for (var i = 0; i < 12; i++)
        PersonOption(id: 'member_$i', name: name, avatarKey: 'p$i'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Nothing selected, nobody to clear.
        PersonPicker(
          options: people.take(3).toList(),
          selectedId: null,
          onChanged: (_) {},
          label: label,
        ),
        const SizedBox(height: 16),
        // One selected, with a "No one" choice.
        PersonPicker(
          options: people.take(3).toList(),
          selectedId: 'member_1',
          onChanged: (_) {},
          label: label,
          allowNone: true,
        ),
        const SizedBox(height: 16),
        // A single person.
        PersonPicker(
          options: people.take(1).toList(),
          selectedId: 'member_0',
          onChanged: (_) {},
          label: label,
        ),
        const SizedBox(height: 16),
        // Twelve people scroll sideways.
        PersonPicker(
          options: people,
          selectedId: 'member_7',
          onChanged: (_) {},
          label: label,
        ),
      ],
    );
  },
);

final GallerySection _categoryBadge = GallerySection(
  id: 'category_badge',
  label: (l10n) => l10n.galleryCategoryBadge,
  build: (context) {
    final name = context.l10n.gallerySampleItemName;
    final long =
        '${context.l10n.gallerySampleTitle} ${context.l10n.gallerySampleMessage}';
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        CategoryBadge(name: name, colorIndex: 0, emoji: '🫑'),
        CategoryBadge(name: name, colorIndex: 5),
        CategoryBadge(name: name, colorIndex: 11, compact: true),
        CategoryBadge(name: name, colorIndex: 3, emoji: '🐄', compact: true),
        CategoryBadge(name: long, colorIndex: 8, emoji: '💊'),
      ],
    );
  },
);
