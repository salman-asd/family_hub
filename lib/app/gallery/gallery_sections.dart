import 'package:family_hub/app/gallery/gallery_sections_p2.dart';
import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:family_hub/core/localization/generated/app_localizations.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/core/utils/money.dart';
import 'package:family_hub/shared/widgets/app_avatar.dart';
import 'package:family_hub/shared/widgets/app_card.dart';
import 'package:family_hub/shared/widgets/empty_state.dart';
import 'package:family_hub/shared/widgets/error_view.dart';
import 'package:family_hub/shared/widgets/item_thumb.dart';
import 'package:family_hub/shared/widgets/loading_view.dart';
import 'package:family_hub/shared/widgets/money_text.dart';
import 'package:family_hub/shared/widgets/pill_bottom_bar.dart';
import 'package:family_hub/shared/widgets/progress_ring.dart';
import 'package:family_hub/shared/widgets/section_header.dart';
import 'package:family_hub/shared/widgets/status_chip.dart';
import 'package:family_hub/shared/widgets/sync_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A URL that can never resolve, used to show the *failed image* state on
/// purpose: it proves the documented fallback (initials stay in place, no error
/// text, no flicker) without a network dependency.
const String kGalleryBrokenImageUrl = 'https://invalid.invalid/image.png';

/// One entry of the component gallery (roadmap Step 11).
///
/// The gallery screen and its golden test both read [gallerySections], so a
/// widget appears on `/dev/gallery` and in the goldens at the same time, in the
/// same states, and neither can drift from the other.
@immutable
class GallerySection {
  const GallerySection({
    required this.id,
    required this.label,
    required this.build,
  });

  /// Stable lower-snake id; also the golden file name prefix.
  final String id;

  /// Localized section heading.
  final String Function(AppLocalizations l10n) label;

  /// The widget shown in every state it has.
  final WidgetBuilder build;
}

/// Every shared widget of Step 11, in every state.
List<GallerySection> gallerySections() => <GallerySection>[
  _avatar,
  _itemThumb,
  _statusChip,
  _emptyState,
  _loading,
  _error,
  _sectionHeader,
  _card,
  _money,
  _progress,
  _pillBar,
  _syncBanner,
  ...phase2GallerySections(),
];

// ── Sample values ─────────────────────────────────────────────────────────────

const Money _smallAmount = Money.paisa(1250);
const Money _largeAmount = Money.paisa(125050);
const Money _hugeAmount = Money.paisa(123456789);

// ── Sections ──────────────────────────────────────────────────────────────────

final GallerySection _avatar = GallerySection(
  id: 'app_avatar',
  label: (l10n) => l10n.galleryAvatar,
  build: (context) {
    final l10n = context.l10n;
    final name = l10n.gallerySamplePersonName;
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // Colour derived from the id: the same person keeps the same colour on
        // every screen and every launch.
        AppAvatar(id: 'usr_karim', name: name, semanticLabel: name),
        // A preset colour (p0…p11).
        AppAvatar(id: 'usr_karim', name: name, avatarKey: 'p3'),
        // Sizes.
        AppAvatar(id: 'usr_rahim', name: name, size: 28),
        AppAvatar(id: 'usr_rahim', name: name, size: 64),
        // A failed image load: the initials stay, with no error text.
        AppAvatar(
          id: 'usr_jasim',
          name: name,
          imageUrl: kGalleryBrokenImageUrl,
        ),
      ],
    );
  },
);

final GallerySection _itemThumb = GallerySection(
  id: 'item_thumb',
  label: (l10n) => l10n.galleryItemThumb,
  build: (context) {
    final l10n = context.l10n;
    final name = l10n.gallerySampleItemName;
    final label = l10n.thumbSemantics(name);
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // No image: coloured initial placeholder.
        ItemThumb(id: 'item_potato', name: name, semanticLabel: label),
        // Item image, then the category image, then the placeholder.
        ItemThumb(
          id: 'item_potato',
          name: name,
          imageUrl: kGalleryBrokenImageUrl,
          semanticLabel: label,
        ),
        ItemThumb(
          id: 'item_onion',
          name: name,
          categoryImageUrl: kGalleryBrokenImageUrl,
          semanticLabel: label,
        ),
        // Circular variant, for a category row.
        ItemThumb(
          id: 'item_rice',
          name: name,
          size: 48,
          rounded: true,
          semanticLabel: label,
        ),
      ],
    );
  },
);

final GallerySection _statusChip = GallerySection(
  id: 'status_chip',
  label: (l10n) => l10n.galleryStatusChip,
  build: (context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      for (final status in WidgetStatus.values) StatusChip(status: status),
      for (final status in WidgetStatus.values)
        StatusChip(status: status, compact: true),
    ],
  ),
);

final GallerySection _emptyState = GallerySection(
  id: 'empty_state',
  label: (l10n) => l10n.galleryEmptyState,
  build: (context) {
    final l10n = context.l10n;
    return Column(
      children: [
        // Title, message and a primary action.
        SizedBox(
          height: 240,
          child: EmptyState(
            icon: Icons.shopping_basket_outlined,
            title: l10n.emptyGenericTitle,
            message: l10n.emptyGenericMessage,
            actionLabel: l10n.actionSave,
            onAction: () {},
          ),
        ),
        const SizedBox(height: 16),
        // Text only — the compact form used inside a card.
        SizedBox(
          height: 140,
          child: EmptyState(
            title: l10n.gallerySampleTitle,
            message: l10n.gallerySampleMessage,
          ),
        ),
      ],
    );
  },
);

final GallerySection _loading = GallerySection(
  id: 'loading_view',
  label: (l10n) => l10n.galleryLoadingView,
  build: (context) => const Column(
    children: [
      // Three text lines, the usual "list is loading" shape.
      SizedBox(height: 64, child: LoadingView()),
      SizedBox(height: 24),
      // With a leading avatar placeholders, as a member list row.
      SizedBox(height: 64, child: LoadingView(lines: 2, showAvatar: true)),
    ],
  ),
);

final GallerySection _error = GallerySection(
  id: 'error_view',
  label: (l10n) => l10n.galleryErrorView,
  build: (context) {
    final l10n = context.l10n;
    return Column(
      children: [
        // Retryable: network-style failure.
        SizedBox(
          height: 240,
          child: ErrorView(message: l10n.errorNetwork, onRetry: () {}),
        ),
        const SizedBox(height: 16),
        // Permanent: nothing to retry, so no button is drawn.
        SizedBox(
          height: 200,
          child: ErrorView(message: l10n.errorPermissionDenied),
        ),
        const SizedBox(height: 16),
        // Custom heading and icon.
        SizedBox(
          height: 240,
          child: ErrorView(
            title: l10n.gallerySampleTitle,
            message: l10n.errorUnknown,
            icon: Icons.cloud_off_rounded,
            onRetry: () {},
          ),
        ),
      ],
    );
  },
);

final GallerySection _sectionHeader = GallerySection(
  id: 'section_header',
  label: (l10n) => l10n.gallerySectionHeader,
  build: (context) {
    final l10n = context.l10n;
    return Column(
      children: [
        SectionHeader(title: l10n.gallerySampleTitle),
        SectionHeader(
          title: l10n.gallerySampleTitle,
          seeAllLabel: l10n.commonSeeAll,
          onSeeAll: () {},
        ),
      ],
    );
  },
);

final GallerySection _card = GallerySection(
  id: 'app_card',
  label: (l10n) => l10n.galleryAppCard,
  build: (context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(child: Text(l10n.gallerySampleMessage)),
        const SizedBox(height: 12),
        AppCard(raised: true, child: Text(l10n.gallerySampleMessage)),
        const SizedBox(height: 12),
        // Tappable: gets ink feedback and keeps its 48dp target.
        AppCard(onTap: () {}, child: Text(l10n.gallerySampleTitle)),
        const SizedBox(height: 12),
        // Sunken: used for a secondary block inside a page.
        AppCard(
          color: context.tokens.surfaceSunken,
          child: Text(l10n.gallerySampleTitle),
        ),
      ],
    );
  },
);

final GallerySection _money = GallerySection(
  id: 'money_text',
  label: (l10n) => l10n.galleryMoneyText,
  build: (context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const MoneyText(value: _smallAmount),
        const SizedBox(height: 8),
        MoneyText(value: _largeAmount, style: textTheme.headlineSmall),
        const SizedBox(height: 8),
        // Whole amounts can drop the '.00'.
        const MoneyText(value: _hugeAmount, hideZeroFraction: true),
        const SizedBox(height: 8),
        MoneyText(value: Money.zero, semanticsLabel: l10n.galleryMoneyText),
      ],
    );
  },
);

final GallerySection _progress = GallerySection(
  id: 'progress_ring',
  label: (l10n) => l10n.galleryProgressRing,
  build: (context) {
    final l10n = context.l10n;
    return Wrap(
      spacing: 24,
      runSpacing: 16,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // Indeterminate: the length of the work is unknown.
        const ProgressRing(),
        const ProgressRing(value: 0),
        const ProgressRing(value: 0.25),
        const ProgressRing(value: 0.75),
        const ProgressRing(value: 1),
        // With a centre label and the localized announcement that goes with it.
        Consumer(
          builder: (context, ref, _) {
            final percent = ref.watch(appFormattersProvider).number(75);
            return ProgressRing(
              value: 0.75,
              size: 64,
              strokeWidth: 6,
              center: Text(percent),
              semanticLabel: context.l10n.progressSemantics(
                l10n.galleryProgressRing,
                percent,
              ),
            );
          },
        ),
      ],
    );
  },
);

final GallerySection _pillBar = GallerySection(
  id: 'pill_bottom_bar',
  label: (l10n) => l10n.galleryPillBottomBar,
  build: (context) {
    final l10n = context.l10n;
    final items = [
      PillNavItem(icon: Icons.home_outlined, label: l10n.navHome),
      PillNavItem(icon: Icons.checklist_outlined, label: l10n.navChores),
      PillNavItem(icon: Icons.shopping_basket_outlined, label: l10n.navBazar),
      PillNavItem(icon: Icons.people_alt_outlined, label: l10n.navFamily),
    ];
    return Column(
      children: [
        // First destination selected.
        PillBottomBar(selectedIndex: 0, onSelected: (index) {}, items: items),
        const SizedBox(height: 24),
        // Fourth selected: the label expands and the others stay icon-only.
        PillBottomBar(selectedIndex: 3, onSelected: (index) {}, items: items),
      ],
    );
  },
);

final GallerySection _syncBanner = GallerySection(
  id: 'sync_banner',
  label: (l10n) => l10n.gallerySyncBanner,
  build: (context) => const Column(
    children: [
      SyncBanner(pendingWrites: 3),
      SizedBox(height: 12),
      SyncBanner(pendingWrites: 12, offline: true),
      SizedBox(height: 12),
      // Zero pending writes renders nothing.
      SyncBanner(pendingWrites: 0),
    ],
  ),
);
