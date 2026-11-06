import 'package:family_hub/app/theme/theme_registry.dart';
import 'package:family_hub/core/localization/app_formatters.dart';
import 'package:family_hub/core/localization/generated/app_localizations.dart';
import 'package:family_hub/shared/widgets/access_cell.dart';
import 'package:family_hub/shared/widgets/activity_tile.dart';
import 'package:family_hub/shared/widgets/alert_strip.dart';
import 'package:family_hub/shared/widgets/badge_medal.dart';
import 'package:family_hub/shared/widgets/bell_button.dart';
import 'package:family_hub/shared/widgets/confetti_view.dart';
import 'package:family_hub/shared/widgets/dashboard_card_frame.dart';
import 'package:family_hub/shared/widgets/delivery_mode_tile.dart';
import 'package:family_hub/shared/widgets/diagnostic_row.dart';
import 'package:family_hub/shared/widgets/greeting_header.dart';
import 'package:family_hub/shared/widgets/level_ring.dart';
import 'package:family_hub/shared/widgets/loading_view.dart';
import 'package:family_hub/shared/widgets/plant_stage_view.dart';
import 'package:family_hub/shared/widgets/quiet_hours_picker.dart';
import 'package:family_hub/shared/widgets/reorderable_card_tile.dart';
import 'package:family_hub/shared/widgets/stat_pill.dart';
import 'package:family_hub/shared/widgets/switch_tile_with_reason.dart';
import 'package:family_hub/shared/widgets/time_offset_chips.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

import 'shared_widgets_test_support.dart';

void main() {
  setUpAll(loadBundledFonts);

  testWidgets('dashboard card supports content, loading, error and tapping', (
    tester,
  ) async {
    var taps = 0;
    await _pump(
      tester,
      DashboardCardFrame(
        title: 'Card',
        icon: Icons.insights_outlined,
        child: const Text('Content'),
        onTap: () => taps++,
      ),
    );
    await tester.tap(find.text('Content'));
    expect(taps, 1);

    await _pump(
      tester,
      const DashboardCardFrame(
        title: 'Card',
        icon: Icons.insights_outlined,
        mode: DashboardCardMode.loading,
        child: SizedBox.shrink(),
      ),
    );
    expect(find.byType(LoadingView), findsOneWidget);

    await _pump(
      tester,
      const DashboardCardFrame(
        title: 'Card',
        icon: Icons.insights_outlined,
        mode: DashboardCardMode.error,
        errorMessage: 'Network error',
        child: SizedBox.shrink(),
      ),
    );
    expect(find.text('Network error'), findsOneWidget);
  });

  testWidgets('greeting header renders localized caller text', (tester) async {
    await _pump(
      tester,
      const GreetingHeader(greeting: 'Welcome', name: 'Karim', subtitle: 'Hi'),
    );
    expect(find.text('Welcome'), findsOneWidget);
    expect(find.text('Karim'), findsOneWidget);
  });

  testWidgets('bell badge is capped and announces its supplied label', (
    tester,
  ) async {
    await _pump(
      tester,
      const BellButton(
        semanticLabel: '12 notifications',
        count: 12,
        countText: '12',
        overflowText: '9+',
        onPressed: _noop,
      ),
    );
    expect(find.text('9+'), findsOneWidget);
    expect(find.bySemanticsLabel('12 notifications'), findsOneWidget);
  });

  testWidgets('alert action is available and reports its tap', (tester) async {
    var tapped = false;
    await _pump(
      tester,
      AlertStrip(
        title: 'Alert',
        message: 'Details',
        tone: AlertStripTone.warning,
        actionLabel: 'Review',
        onAction: () => tapped = true,
      ),
    );
    await tester.tap(find.text('Review'));
    expect(tapped, isTrue);
  });

  testWidgets('activity tile is tappable and includes its time', (
    tester,
  ) async {
    var tapped = false;
    await _pump(
      tester,
      ActivityTile(
        title: 'Updated',
        subtitle: 'A setting changed',
        timeLabel: 'Today',
        onTap: () => tapped = true,
      ),
    );
    expect(find.text('Today'), findsOneWidget);
    await tester.tap(find.text('Updated'));
    expect(tapped, isTrue);
  });

  testWidgets('stat pill announces both its label and value', (tester) async {
    await _pump(
      tester,
      const StatPill(
        label: 'Completed',
        value: '3',
        icon: Icons.check_circle_outline,
        tone: StatPillTone.positive,
      ),
    );
    expect(find.bySemanticsLabel('Completed, 3'), findsOneWidget);
  });

  testWidgets('time offset chips update the complete selection', (
    tester,
  ) async {
    Set<int>? selection;
    await _pump(
      tester,
      TimeOffsetChips(
        options: const [15, 60],
        labels: const {15: '15 min', 60: '1 hour'},
        selected: const {15},
        onChanged: (value) => selection = value,
      ),
    );
    await tester.tap(find.text('1 hour'));
    expect(selection, {15, 60});
  });

  testWidgets('quiet hours picker shows both supplied time labels', (
    tester,
  ) async {
    await _pump(
      tester,
      QuietHoursPicker(
        startLabel: 'Start',
        endLabel: 'End',
        startMinutes: 22 * 60,
        endMinutes: 7 * 60,
        formatters: const AppFormatters(
          languageCode: 'en',
          useBanglaDigits: false,
        ),
        onStartChanged: (_) {},
        onEndChanged: (_) {},
      ),
    );
    expect(find.text('Start'), findsOneWidget);
    expect(find.text('End'), findsOneWidget);
  });

  testWidgets('disabled switch displays its reason and cannot change', (
    tester,
  ) async {
    await _pump(
      tester,
      const SwitchTileWithReason(
        title: 'Reminders',
        value: false,
        disabledReason: 'Managed by an admin',
      ),
    );
    expect(find.text('Managed by an admin'), findsOneWidget);
    expect(
      tester.widget<SwitchListTile>(find.byType(SwitchListTile)).onChanged,
      isNull,
    );
  });

  testWidgets('level ring retains progress semantics with reduced motion', (
    tester,
  ) async {
    await _pump(
      tester,
      const LevelRing(
        level: 4,
        levelLabel: 'Level 4',
        progress: 0.5,
        progressLabel: 'Halfway',
      ),
    );
    expect(find.bySemanticsLabel('Level 4, Halfway'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('badge medal exposes an earned and an unearned state', (
    tester,
  ) async {
    await _pump(
      tester,
      const Wrap(
        children: [
          BadgeMedal(
            label: 'Badge',
            statusLabel: 'Earned',
            icon: Icons.eco_outlined,
          ),
          BadgeMedal(
            label: 'Badge',
            statusLabel: 'Not earned',
            icon: Icons.eco_outlined,
            earned: false,
          ),
        ],
      ),
    );
    expect(find.bySemanticsLabel('Badge, Earned'), findsOneWidget);
    expect(find.bySemanticsLabel('Badge, Not earned'), findsOneWidget);
  });

  testWidgets('plant stage wrapper paints and announces its illustration', (
    tester,
  ) async {
    const painter = _TestPainter();
    await _pump(
      tester,
      const PlantStageView(
        painter: painter,
        reduced: false,
        semanticLabel: 'Blooming',
      ),
    );
    expect(find.bySemanticsLabel('Blooming'), findsOneWidget);
    expect(
      tester.widget<CustomPaint>(find.byType(CustomPaint)).painter,
      painter,
    );
  });

  testWidgets('confetti view omits its painter for reduced motion', (
    tester,
  ) async {
    const painter = _TestPainter();
    await _pump(
      tester,
      const ConfettiView(
        painter: painter,
        reduced: true,
        child: Text('Celebration'),
      ),
    );
    expect(
      tester.widget<CustomPaint>(find.byType(CustomPaint)).painter,
      isNull,
    );
    expect(find.text('Celebration'), findsOneWidget);
  });

  testWidgets('diagnostic row includes the status label in semantics', (
    tester,
  ) async {
    await _pump(
      tester,
      const DiagnosticRow(
        label: 'Connection',
        value: 'Online',
        status: DiagnosticStatus.success,
        statusLabel: 'Healthy',
      ),
    );
    expect(
      find.bySemanticsLabel('Connection, Online, Healthy'),
      findsOneWidget,
    );
  });

  testWidgets('reorderable card exposes semantic move actions', (tester) async {
    var movedUp = false;
    var movedDown = false;
    await _pump(
      tester,
      ReorderableListView(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        buildDefaultDragHandles: false,
        onReorderItem: (_, _) {},
        children: [
          ReorderableCardTile(
            key: const ValueKey('tile'),
            index: 0,
            title: 'Card',
            dragLabel: 'Drag',
            moveUpLabel: 'Move up',
            moveDownLabel: 'Move down',
            onMoveUp: () => movedUp = true,
            onMoveDown: () => movedDown = true,
          ),
        ],
      ),
    );
    final semanticWidget = find.byWidgetPredicate(
      (widget) =>
          widget is Semantics &&
          widget.properties.customSemanticsActions?.isNotEmpty == true,
    );
    final actions = tester
        .widget<Semantics>(semanticWidget)
        .properties
        .customSemanticsActions!;
    expect(
      actions.keys.map((action) => action.label),
      containsAll(['Move up', 'Move down']),
    );
    actions[const CustomSemanticsAction(label: 'Move up')]!();
    actions[const CustomSemanticsAction(label: 'Move down')]!();
    expect(movedUp, isTrue);
    expect(movedDown, isTrue);
  });

  testWidgets('access cell exposes all states and disabled reason', (
    tester,
  ) async {
    const labels = {
      AccessCellState.hidden: 'Hidden',
      AccessCellState.on: 'On',
      AccessCellState.off: 'Off',
      AccessCellState.requiredAccess: 'Required',
    };
    await _pump(
      tester,
      const AccessCell(
        value: AccessCellState.on,
        labels: labels,
        enabled: false,
        disabledReason: 'Managed elsewhere',
        onChanged: _accessNoop,
      ),
    );
    for (final label in labels.values) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.text('Managed elsewhere'), findsOneWidget);
  });

  testWidgets('delivery mode changes and locked mode explains why', (
    tester,
  ) async {
    DeliveryMode? selected;
    await _pump(
      tester,
      DeliveryModeTile(
        title: 'Delivery',
        mode: DeliveryMode.normal,
        normalLabel: 'Normal',
        pushLabel: 'Push',
        recommended: true,
        recommendedLabel: 'Recommended',
        onChanged: (value) => selected = value,
      ),
    );
    await tester.tap(find.text('Push'));
    expect(selected, DeliveryMode.push);

    await _pump(
      tester,
      const DeliveryModeTile(
        title: 'Delivery',
        mode: DeliveryMode.push,
        normalLabel: 'Normal',
        pushLabel: 'Push',
        locked: true,
        lockedReason: 'Unavailable',
        onChanged: _deliveryNoop,
      ),
    );
    expect(find.text('Unavailable'), findsOneWidget);
    expect(
      tester
          .widget<SegmentedButton<DeliveryMode>>(
            find.byType(SegmentedButton<DeliveryMode>),
          )
          .onSelectionChanged,
      isNull,
    );
  });

  testWidgets('P4 widgets fit at 200% in both locales and themes', (
    tester,
  ) async {
    for (final spec in appThemes) {
      for (final locale in sharedWidgetLocales) {
        final l10n = await AppLocalizations.delegate.load(locale);
        await pumpSharedWidget(
          tester,
          child: _overflowSamples(
            l10n,
            locale,
            AppFormatters(
              languageCode: locale.languageCode,
              useBanglaDigits: locale.languageCode == 'bn',
            ),
          ),
          spec: spec,
          locale: locale,
          textScale: 2,
        );
        expect(
          tester.takeException(),
          isNull,
          reason: 'P4 widget overflowed at 200% in ${locale.languageCode}',
        );
      }
    }
  });

  test('badge and access-state token pairs retain readable contrast', () {
    for (final spec in appThemes) {
      final tokens = spec.tokens;
      expect(
        _contrast(tokens.statusVerifiedOn, tokens.statusVerifiedContainer),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        _contrast(tokens.textSecondary, tokens.surfaceSunken),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        _contrast(tokens.textSecondary, tokens.background),
        greaterThanOrEqualTo(4.5),
      );
      for (final pair in [
        (tokens.statusSkippedOn, tokens.statusSkippedContainer),
        (tokens.statusCompletedOn, tokens.statusCompletedContainer),
        (tokens.statusOverdueOn, tokens.statusOverdueContainer),
        (tokens.statusVerifiedOn, tokens.statusVerifiedContainer),
      ]) {
        expect(_contrast(pair.$1, pair.$2), greaterThanOrEqualTo(4.5));
      }
    }
  });
}

Future<void> _pump(WidgetTester tester, Widget child) => pumpSharedWidget(
  tester,
  child: child,
  spec: defaultLightSpec,
  locale: const Locale('en'),
);

Widget _overflowSamples(
  AppLocalizations l10n,
  Locale locale,
  AppFormatters formatters,
) {
  const bangla =
      'পরিবারের সব সদস্যের জন্য এই মাসের বাজারের সম্পূর্ণ তালিকা এবং বিস্তারিত তথ্য';
  const english =
      'A detailed family dashboard update for every household member this month';
  final longLabel = locale.languageCode == 'bn' ? bangla : english;
  final accessLabels = {
    AccessCellState.hidden: longLabel,
    AccessCellState.on: longLabel,
    AccessCellState.off: longLabel,
    AccessCellState.requiredAccess: longLabel,
  };
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      DashboardCardFrame(
        title: longLabel,
        icon: Icons.insights_outlined,
        trailing: BellButton(
          semanticLabel: longLabel,
          count: 10,
          countText: formatters.number(10),
          overflowText: l10n.galleryBellOverflow,
          onPressed: _noop,
        ),
        child: Text(longLabel),
      ),
      GreetingHeader(greeting: longLabel, name: longLabel, subtitle: longLabel),
      AlertStrip(
        title: longLabel,
        message: longLabel,
        tone: AlertStripTone.warning,
        actionLabel: longLabel,
        onAction: _noop,
      ),
      ActivityTile(
        title: longLabel,
        subtitle: longLabel,
        timeLabel: longLabel,
        onTap: _noop,
      ),
      StatPill(label: longLabel, value: longLabel, icon: Icons.eco_outlined),
      TimeOffsetChips(
        options: const [15],
        labels: {15: longLabel},
        selected: const {},
        onChanged: (_) {},
      ),
      QuietHoursPicker(
        startLabel: longLabel,
        endLabel: longLabel,
        startMinutes: 22 * 60,
        endMinutes: 7 * 60,
        formatters: formatters,
        onStartChanged: (_) {},
        onEndChanged: (_) {},
      ),
      SwitchTileWithReason(
        title: longLabel,
        subtitle: longLabel,
        value: false,
        disabledReason: longLabel,
      ),
      LevelRing(
        level: 4,
        levelLabel: longLabel,
        progress: 0.5,
        progressLabel: longLabel,
      ),
      BadgeMedal(
        label: longLabel,
        statusLabel: l10n.galleryEarned,
        description: longLabel,
        icon: Icons.eco_outlined,
      ),
      PlantStageView(
        painter: const _TestPainter(),
        reduced: true,
        semanticLabel: longLabel,
      ),
      ConfettiView(
        painter: const _TestPainter(),
        reduced: true,
        semanticLabel: longLabel,
      ),
      DiagnosticRow(
        label: longLabel,
        value: longLabel,
        status: DiagnosticStatus.warning,
        statusLabel: longLabel,
      ),
      ReorderableListView(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        buildDefaultDragHandles: false,
        onReorderItem: (_, _) {},
        children: [
          ReorderableCardTile(
            key: const ValueKey('overflow'),
            index: 0,
            title: longLabel,
            dragLabel: longLabel,
            moveUpLabel: longLabel,
            moveDownLabel: longLabel,
            value: true,
            onChanged: (_) {},
            onMoveUp: _noop,
            onMoveDown: _noop,
          ),
        ],
      ),
      AccessCell(
        value: AccessCellState.requiredAccess,
        labels: accessLabels,
        onChanged: (_) {},
      ),
      DeliveryModeTile(
        title: longLabel,
        mode: DeliveryMode.push,
        normalLabel: longLabel,
        pushLabel: longLabel,
        recommended: true,
        recommendedLabel: l10n.galleryRecommended,
        onChanged: _deliveryNoop,
      ),
    ],
  );
}

double _contrast(Color foreground, Color background) {
  final first = foreground.computeLuminance();
  final second = background.computeLuminance();
  final lighter = first > second ? first : second;
  final darker = first > second ? second : first;
  return (lighter + 0.05) / (darker + 0.05);
}

void _noop() {}
void _accessNoop(AccessCellState _) {}
void _deliveryNoop(DeliveryMode _) {}

class _TestPainter extends CustomPainter {
  const _TestPainter();

  @override
  void paint(Canvas canvas, Size size) {}

  @override
  bool shouldRepaint(_TestPainter oldDelegate) => false;
}
