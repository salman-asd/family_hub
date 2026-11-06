import 'package:family_hub/app/routing/modal_route_tracker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('tracks modal routes on a nested tab navigator', (tester) async {
    final tracker = ModalRouteTracker();
    addTearDown(tracker.dispose);
    final branchKey = GlobalKey<NavigatorState>();

    await tester.pumpWidget(
      MaterialApp(
        home: Navigator(
          key: branchKey,
          observers: [tracker.createObserver()],
          onGenerateRoute: (settings) => MaterialPageRoute<void>(
            builder: (context) => Scaffold(
              body: TextButton(
                key: const Key('open_modal'),
                onPressed: () => showModalBottomSheet<void>(
                  context: context,
                  builder: (context) => SizedBox(
                    height: 120,
                    child: Center(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Modal'),
                      ),
                    ),
                  ),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );
    expect(tracker.hasOpenModalRoute, isFalse);

    await tester.tap(find.byKey(const Key('open_modal')));
    await tester.pumpAndSettle();
    expect(tracker.hasOpenModalRoute, isTrue);

    await tester.tap(find.text('Modal'));
    await tester.pumpAndSettle();
    expect(tracker.hasOpenModalRoute, isFalse);
  });
}
