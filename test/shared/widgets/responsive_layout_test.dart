import 'package:family_hub/core/utils/layout_class.dart';
import 'package:family_hub/shared/widgets/responsive_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// P4-24: the single place a screen asks "is this window wide enough for two
/// panes?" — the thresholds the tablet layouts are built on.
void main() {
  Future<LayoutClass> classAt(WidgetTester tester, Size size) async {
    tester.view
      ..physicalSize = size
      ..devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    LayoutClass? seen;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            seen = context.layoutClass;
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    return seen!;
  }

  testWidgets('the breakpoints follow the roadmap sizes', (tester) async {
    expect(await classAt(tester, const Size(360, 780)), LayoutClass.compact);
    expect(await classAt(tester, const Size(600, 900)), LayoutClass.medium);
    expect(await classAt(tester, const Size(840, 1024)), LayoutClass.expanded);
    expect(await classAt(tester, const Size(1024, 768)), LayoutClass.expanded);
  });

  testWidgets('only the expanded class gets a second pane', (tester) async {
    expect(
      (await classAt(tester, const Size(360, 780))).showsTwoPanes,
      isFalse,
    );
    expect(
      (await classAt(tester, const Size(600, 900))).showsTwoPanes,
      isFalse,
    );
    expect(
      (await classAt(tester, const Size(840, 1024))).showsTwoPanes,
      isTrue,
    );
  });
}
