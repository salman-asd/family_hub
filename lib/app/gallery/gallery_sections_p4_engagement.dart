import 'package:family_hub/app/gallery/gallery_sections.dart';
import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:family_hub/core/localization/generated/app_localizations.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/shared/widgets/access_cell.dart';
import 'package:family_hub/shared/widgets/badge_medal.dart';
import 'package:family_hub/shared/widgets/confetti_view.dart';
import 'package:family_hub/shared/widgets/delivery_mode_tile.dart';
import 'package:family_hub/shared/widgets/diagnostic_row.dart';
import 'package:family_hub/shared/widgets/level_ring.dart';
import 'package:family_hub/shared/widgets/plant_stage_view.dart';
import 'package:family_hub/shared/widgets/reorderable_card_tile.dart';
import 'package:flutter/material.dart';

List<GallerySection> phase4EngagementGallerySections() => <GallerySection>[
  GallerySection(
    id: 'level_ring',
    label: (l10n) => l10n.galleryLevelRing,
    build: (context) => LevelRing(
      level: 3,
      levelLabel: context.l10n.gallerySampleTitle,
      progress: 0.65,
      progressLabel: context.l10n.gallerySampleMessage,
    ),
  ),
  GallerySection(
    id: 'badge_medal',
    label: (l10n) => l10n.galleryBadgeMedal,
    build: (context) => Wrap(
      spacing: 16,
      children: [
        BadgeMedal(
          label: context.l10n.gallerySampleTitle,
          statusLabel: context.l10n.galleryEarned,
          description: context.l10n.gallerySampleMessage,
          icon: Icons.workspace_premium_outlined,
        ),
        BadgeMedal(
          label: context.l10n.gallerySampleTitle,
          statusLabel: context.l10n.galleryUnearned,
          icon: Icons.eco_outlined,
          earned: false,
        ),
      ],
    ),
  ),
  GallerySection(
    id: 'plant_stage_view',
    label: (l10n) => l10n.galleryPlantStageView,
    build: (context) {
      final tokens = context.tokens;
      return Wrap(
        spacing: 12,
        children: [
          for (var stage = 0; stage < 4; stage++)
            PlantStageView(
              painter: _GalleryPlantPainter(tokens.chart[stage], stage + 1),
              reduced: stage == 0,
              semanticLabel: context.l10n.gallerySampleTitle,
              size: 64,
              child: const Center(child: Icon(Icons.grass_rounded)),
            ),
        ],
      );
    },
  ),
  GallerySection(
    id: 'confetti_view',
    label: (l10n) => l10n.galleryConfettiView,
    build: (context) {
      final tokens = context.tokens;
      return Column(
        children: [
          SizedBox(
            height: 72,
            child: ConfettiView(
              painter: _GalleryConfettiPainter(tokens.chart.first),
              reduced: false,
              child: const Center(child: Icon(Icons.celebration_outlined)),
            ),
          ),
          SizedBox(
            height: 72,
            child: ConfettiView(
              painter: _GalleryConfettiPainter(tokens.chart.first),
              reduced: true,
              child: const Center(child: Icon(Icons.celebration_outlined)),
            ),
          ),
        ],
      );
    },
  ),
  GallerySection(
    id: 'diagnostic_row',
    label: (l10n) => l10n.galleryDiagnosticRow,
    build: (context) => Column(
      children: [
        for (final status in DiagnosticStatus.values)
          DiagnosticRow(
            label: context.l10n.gallerySampleTitle,
            value: context.l10n.gallerySampleMessage,
            status: status,
            statusLabel: context.l10n.gallerySampleTitle,
          ),
      ],
    ),
  ),
  GallerySection(
    id: 'reorderable_card_tile',
    label: (l10n) => l10n.galleryReorderableCardTile,
    build: (context) {
      final l10n = context.l10n;
      return ReorderableListView(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        buildDefaultDragHandles: false,
        onReorderItem: (_, _) {},
        children: [
          ReorderableCardTile(
            key: const ValueKey('gallery'),
            index: 0,
            title: l10n.gallerySampleTitle,
            dragLabel: l10n.galleryDragLabel,
            moveUpLabel: l10n.galleryMoveUp,
            moveDownLabel: l10n.galleryMoveDown,
            value: true,
            onChanged: (_) {},
            onMoveUp: () {},
            onMoveDown: () {},
          ),
        ],
      );
    },
  ),
  GallerySection(
    id: 'access_cell',
    label: (l10n) => l10n.galleryAccessCell,
    build: (context) {
      final l10n = context.l10n;
      final labels = _accessLabels(l10n);
      return Column(
        children: [
          AccessCell(
            value: AccessCellState.on,
            labels: labels,
            onChanged: (_) {},
          ),
          const SizedBox(height: 12),
          AccessCell(
            value: AccessCellState.hidden,
            labels: labels,
            enabled: false,
            disabledReason: l10n.gallerySampleMessage,
            onChanged: (_) {},
          ),
        ],
      );
    },
  ),
  GallerySection(
    id: 'delivery_mode_tile',
    label: (l10n) => l10n.galleryDeliveryModeTile,
    build: (context) {
      final l10n = context.l10n;
      return Column(
        children: [
          DeliveryModeTile(
            title: l10n.gallerySampleTitle,
            mode: DeliveryMode.normal,
            normalLabel: l10n.galleryDeliveryNormal,
            pushLabel: l10n.galleryDeliveryPush,
            recommended: true,
            recommendedLabel: l10n.galleryRecommended,
            onChanged: (_) {},
          ),
          const SizedBox(height: 12),
          DeliveryModeTile(
            title: l10n.gallerySampleTitle,
            mode: DeliveryMode.push,
            normalLabel: l10n.galleryDeliveryNormal,
            pushLabel: l10n.galleryDeliveryPush,
            locked: true,
            lockedReason: l10n.gallerySampleMessage,
            onChanged: (_) {},
          ),
        ],
      );
    },
  ),
];

Map<AccessCellState, String> _accessLabels(AppLocalizations l10n) =>
    <AccessCellState, String>{
      AccessCellState.hidden: l10n.galleryAccessHidden,
      AccessCellState.on: l10n.galleryAccessOn,
      AccessCellState.off: l10n.galleryAccessOff,
      AccessCellState.requiredAccess: l10n.galleryAccessRequired,
    };

class _GalleryConfettiPainter extends CustomPainter {
  const _GalleryConfettiPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    for (var index = 0; index < 5; index++) {
      canvas.drawCircle(
        Offset(size.width * (index + 1) / 6, size.height / 2),
        3,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_GalleryConfettiPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _GalleryPlantPainter extends CustomPainter {
  const _GalleryPlantPainter(this.color, this.growth);

  final Color color;
  final int growth;

  @override
  void paint(Canvas canvas, Size size) {
    final stem = Paint()
      ..color = color
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final centre = size.width / 2;
    final base = size.height * 0.88;
    final top = size.height * (0.78 - growth * 0.13);
    canvas.drawLine(Offset(centre, base), Offset(centre, top), stem);
    for (var leaf = 0; leaf < growth; leaf++) {
      final y = base - (leaf + 1) * size.height * 0.14;
      final direction = leaf.isEven ? -1 : 1;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(centre + direction * size.width * 0.18, y),
          width: size.width * 0.34,
          height: size.height * 0.14,
        ),
        stem,
      );
    }
  }

  @override
  bool shouldRepaint(_GalleryPlantPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.growth != growth;
}
