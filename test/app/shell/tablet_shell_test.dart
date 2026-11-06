import 'package:family_hub/app/shell/app_shell.dart';
import 'package:family_hub/app/theme/theme_builder.dart';
import 'package:family_hub/app/theme/theme_registry.dart';
import 'package:family_hub/shared/widgets/pill_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// P4-24: the shell's chrome follows the layout class, and swapping the chrome
/// must never disturb the tab a person is on or how far they scrolled.
///
/// The shell is built directly (like the branch test in `router_test.dart`) so
/// the assertions are about the chrome, not about the session providers.
void main() {
  const tabs = ['home', 'chores', 'bazar', 'family'];

  late GoRouter router;

  Future<void> pumpShell(WidgetTester tester, Size size) async {
    tester.view
      ..physicalSize = size
      ..devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    router = GoRouter(
      initialLocation: '/home',
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, shell) => AppShell(
            navigationShell: shell,
            destinations: [
              for (final id in tabs)
                ShellDestination(
                  id: id,
                  icon: Icons.circle_outlined,
                  label: (_) => id,
                ),
            ],
          ),
          branches: [
            for (final id in tabs)
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/$id',
                    builder: (_, _) => _TabScreen(id: id),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(
          theme: buildThemeData(appThemes.first),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> resize(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    await tester.pump();
    await tester.pumpAndSettle();
  }

  String path() => router.routeInformationProvider.value.uri.path;

  /// A rail destination, found by the label it must always show (rule 16).
  Finder rail(String id) =>
      find.descendant(of: find.byType(NavigationRail), matching: find.text(id));

  testWidgets('a phone gets the pill bar and no rail', (tester) async {
    await pumpShell(tester, const Size(360, 780));
    expect(path(), '/home');
    expect(find.byType(PillBottomBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
  });

  testWidgets('a portrait tablet (medium) still gets the pill bar', (
    tester,
  ) async {
    await pumpShell(tester, const Size(700, 1100));
    expect(find.byType(PillBottomBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
  });

  testWidgets('a landscape phone keeps the compact chrome', (tester) async {
    await pumpShell(tester, const Size(900, 400));
    expect(find.byType(PillBottomBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
  });

  testWidgets('an expanded window gets the labelled rail', (tester) async {
    await pumpShell(tester, const Size(1024, 768));
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(PillBottomBar), findsNothing);
    for (final id in tabs) {
      // Every tab is named, not only iconed (rule 16).
      expect(rail(id), findsOneWidget, reason: '$id has a label');
    }
  });

  testWidgets('rail -> bar keeps the selected tab', (tester) async {
    await pumpShell(tester, const Size(1024, 768));
    await tester.tap(rail('family'));
    await tester.pumpAndSettle();
    expect(path(), '/family');

    await resize(tester, const Size(500, 900));
    expect(find.byType(PillBottomBar), findsOneWidget);
    expect(path(), '/family', reason: 'shrinking must not change the tab');
    expect(
      tester.widget<PillBottomBar>(find.byType(PillBottomBar)).selectedIndex,
      3,
    );
  });

  testWidgets('bar -> rail keeps the selected tab', (tester) async {
    await pumpShell(tester, const Size(400, 900));
    await tester.tap(find.byKey(const Key('tab_family')));
    await tester.pumpAndSettle();

    await resize(tester, const Size(1100, 800));
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(path(), '/family');
    expect(
      tester.widget<NavigationRail>(find.byType(NavigationRail)).selectedIndex,
      3,
    );
  });

  testWidgets('the branch keeps its scroll position across the chrome swap', (
    tester,
  ) async {
    await pumpShell(tester, const Size(1024, 620));
    await tester.tap(rail('family'));
    await tester.pumpAndSettle();

    final list = find.byKey(const ValueKey('list_family'));
    final scrollable = find.descendant(
      of: list,
      matching: find.byType(Scrollable),
    );
    await tester.drag(list, const Offset(0, -150));
    await tester.pumpAndSettle();
    final before = tester.state<ScrollableState>(scrollable).position;
    expect(before.pixels, greaterThan(0));

    await resize(tester, const Size(620, 1024));

    expect(find.byType(NavigationRail), findsNothing);
    expect(
      tester.state<ScrollableState>(scrollable).position,
      same(before),
      reason: 'only the chrome is rebuilt; the branch keeps its state',
    );
    expect(
      tester.state<ScrollableState>(scrollable).position.pixels,
      before.pixels,
    );
  });
}

/// A branch's screen: tall enough to scroll on every size used in the test.
class _TabScreen extends StatelessWidget {
  const _TabScreen({required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(id)),
      body: ListView(
        key: ValueKey('list_$id'),
        children: [
          for (var i = 0; i < 40; i++)
            SizedBox(height: 60, child: Center(child: Text('$id $i'))),
        ],
      ),
    );
  }
}
