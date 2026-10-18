import 'package:family_hub/app/theme/theme_builder.dart';
import 'package:family_hub/app/theme/theme_registry.dart';
import 'package:family_hub/shared/widgets/permission_gate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The child every test gates: a button that records its taps.
Widget _action(
  VoidCallback onPressed, {
  Key key = const Key('action'),
}) =>
    TextButton(
      key: key,
      onPressed: onPressed,
      child: const Text('Complete'),
    );

Future<void> _pump(
  WidgetTester tester, {
  required bool allowed,
  required VoidCallback onPressed,
  PermissionGateMode mode = PermissionGateMode.hide,
  String? deniedMessage,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: buildThemeData(appThemes.first),
      home: Scaffold(
        body: PermissionGate(
          allowed: allowed,
          mode: mode,
          deniedMessage: deniedMessage,
          child: _action(onPressed),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('an allowed action is shown as it is', (tester) async {
    var taps = 0;
    await _pump(tester, allowed: true, onPressed: () => taps++);

    expect(find.text('Complete'), findsOneWidget);

    await tester.tap(find.byKey(const Key('action')));
    expect(taps, 1);
  });

  testWidgets('an allowed action stays usable in disable mode', (tester) async {
    var taps = 0;
    await _pump(
      tester,
      allowed: true,
      mode: PermissionGateMode.disable,
      onPressed: () => taps++,
    );

    await tester.tap(find.byKey(const Key('action')));
    expect(taps, 1);
  });

  testWidgets('hide mode removes a denied action', (tester) async {
    await _pump(tester, allowed: false, onPressed: () {});

    expect(find.text('Complete'), findsNothing);
    expect(find.byKey(const Key('action')), findsNothing);
  });

  testWidgets('disable mode keeps a denied action visible but unusable',
      (tester) async {
    var taps = 0;
    await _pump(
      tester,
      allowed: false,
      mode: PermissionGateMode.disable,
      onPressed: () => taps++,
    );

    expect(find.text('Complete'), findsOneWidget);

    await tester.tap(find.byKey(const Key('action')), warnIfMissed: false);
    expect(taps, 0, reason: 'a blocked action must not fire');
  });

  testWidgets('disable mode dims the denied action', (tester) async {
    await _pump(
      tester,
      allowed: false,
      mode: PermissionGateMode.disable,
      onPressed: () {},
    );

    final opacity = tester.widget<Opacity>(
      find
          .descendant(
            of: find.byType(PermissionGate),
            matching: find.byType(Opacity),
          )
          .first,
    );
    expect(opacity.opacity, PermissionGate.disabledOpacity);
  });

  testWidgets('disable mode explains why, with an icon and a label',
      (tester) async {
    await _pump(
      tester,
      allowed: false,
      mode: PermissionGateMode.disable,
      deniedMessage: 'Only an admin can do this',
      onPressed: () {},
    );

    expect(find.text('Only an admin can do this'), findsOneWidget);
    // Never colour alone: the icon carries the status too (rule 13).
    expect(find.byIcon(Icons.lock_outline), findsOneWidget);
  });

  testWidgets('disable mode shows no explanation when none is given',
      (tester) async {
    await _pump(
      tester,
      allowed: false,
      mode: PermissionGateMode.disable,
      onPressed: () {},
    );

    expect(find.text('Complete'), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline), findsNothing);
  });

  testWidgets('a denied action is announced to assistive tech', (tester) async {
    final handle = tester.ensureSemantics();

    await _pump(
      tester,
      allowed: false,
      mode: PermissionGateMode.disable,
      deniedMessage: 'Only an admin can do this',
      onPressed: () {},
    );

    expect(find.bySemanticsLabel('Only an admin can do this'), findsWidgets);
    // Disposed in the body, not in addTearDown: the binding checks for leaked
    // handles before tear-down callbacks run.
    handle.dispose();
  });
}
