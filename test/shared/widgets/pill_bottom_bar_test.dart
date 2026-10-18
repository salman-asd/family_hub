import 'package:family_hub/app/theme/theme_builder.dart';
import 'package:family_hub/app/theme/theme_registry.dart';
import 'package:family_hub/shared/widgets/pill_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _items = <PillNavItem>[
  PillNavItem(key: Key('t0'), icon: Icons.home_outlined, label: 'Home'),
  PillNavItem(key: Key('t1'), icon: Icons.checklist_rounded, label: 'Chores'),
  PillNavItem(key: Key('t2'), icon: Icons.shopping_basket, label: 'Bazar'),
  PillNavItem(key: Key('t3'), icon: Icons.groups_outlined, label: 'Family'),
];

Future<void> _pump(
  WidgetTester tester, {
  required int selected,
  List<PillNavItem> items = _items,
  ValueChanged<int>? onSelected,
  AppThemeSpec? spec,
  double textScale = 1,
  Size size = const Size(360, 640),
}) async {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: buildThemeData(spec ?? appThemes.first),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
        ),
        child: child!,
      ),
      home: Scaffold(
        bottomNavigationBar: PillBottomBar(
          items: items,
          selectedIndex: selected,
          onSelected: onSelected ?? (_) {},
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('only the selected destination shows its label', (tester) async {
    await _pump(tester, selected: 1);
    expect(find.text('Chores'), findsOneWidget);
    expect(find.text('Home'), findsNothing);
    expect(find.text('Bazar'), findsNothing);
    expect(find.text('Family'), findsNothing);
  });

  testWidgets('the label follows the selection', (tester) async {
    await _pump(tester, selected: 3);
    expect(find.text('Family'), findsOneWidget);
    expect(find.text('Chores'), findsNothing);
  });

  testWidgets('tapping a destination reports its index', (tester) async {
    final taps = <int>[];
    await _pump(tester, selected: 0, onSelected: taps.add);
    await tester.tap(find.byKey(const Key('t2')));
    await tester.tap(find.byKey(const Key('t0')));
    expect(taps, [2, 0]);
  });

  testWidgets('every touch target is at least 48 x 48 dp', (tester) async {
    for (var selected = 0; selected < _items.length; selected++) {
      await _pump(tester, selected: selected);
      for (final item in _items) {
        final size = tester.getSize(find.byKey(item.key!));
        expect(size.width, greaterThanOrEqualTo(48), reason: item.label);
        expect(size.height, greaterThanOrEqualTo(48), reason: item.label);
      }
    }
  });

  testWidgets('each destination is announced with its label', (tester) async {
    final handle = tester.ensureSemantics();
    await _pump(tester, selected: 2);
    for (final item in _items) {
      expect(
        tester.getSemantics(find.byKey(item.key!)).label,
        item.label,
      );
    }
    handle.dispose();
  });

  testWidgets('renders in every registered theme without errors',
      (tester) async {
    for (final spec in appThemes.where((s) => s.available)) {
      await _pump(tester, selected: 0, spec: spec);
      expect(tester.takeException(), isNull, reason: spec.id);
    }
  });

  testWidgets('a long Bangla label at 200% text scale does not overflow',
      (tester) async {
    const long = [
      PillNavItem(key: Key('a'), icon: Icons.home, label: 'হোম'),
      PillNavItem(
        key: Key('b'),
        icon: Icons.checklist,
        label: 'পরিবারের সকল সদস্যের দৈনিক কাজের তালিকা',
      ),
      PillNavItem(key: Key('c'), icon: Icons.shopping_basket, label: 'বাজার'),
      PillNavItem(key: Key('d'), icon: Icons.groups, label: 'পরিবার'),
    ];
    await _pump(
      tester,
      selected: 1,
      items: long,
      textScale: 2,
      size: const Size(320, 640),
    );
    expect(tester.takeException(), isNull);
  });
}
