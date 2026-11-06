import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_states.dart';
import '../../support/semantics_audit.dart';
import 'phase4_test_support.dart';

/// P4-23: the accessibility smoke test for every Phase 4 screen.
///
/// The state harness already runs Material's `labeledTapTargetGuideline`, but
/// only over what fits on a 400x900 phone. Here the surface is tall enough that
/// a whole page is laid out at once, so a control far down a settings list is
/// checked too, and anything that stays unlabeled must be written down below.
void main() {
  // Tappables that carry no label of their own and are correct anyway.
  // Every entry names the widget and the reason. Keep this list honest: a new
  // offender fails the test until it is either labelled or explained here.
  const List<String> unlabeledAllowList = <String>[];

  // Proves the walk below can see an offender at all: without this, a broken
  // audit would report a clean bill of health forever.
  testWidgets('the audit reports a bare icon button', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpAuditScreen(
      tester,
      home: Scaffold(
        body: Center(
          child: IconButton(
            key: const ValueKey('bare'),
            onPressed: () {},
            icon: const Icon(Icons.add),
          ),
        ),
      ),
      surface: const Size(400, 900),
    );

    final audit = auditTapTargets(tester);
    expect(audit.tappableNodes, 1);
    expect(audit.unlabeled, hasLength(1));
    expect(audit.unlabeled.single, isNotEmpty);
    semantics.dispose();
  });

  for (final screen in phase4Screens) {
    for (final language in const ['bn', 'en']) {
      testWidgets('${screen.name} / $language labels every tappable', (
        tester,
      ) async {
        final semantics = tester.ensureSemantics();
        await pumpAuditScreen(
          tester,
          home: screen.build(),
          locale: Locale(language),
          overrides: screen.overrides(ScreenState.data),
          surface: const Size(1200, 4000),
        );

        expect(tester.takeException(), isNull, reason: 'screen threw');
        final audit = auditTapTargets(tester);
        // Guards the audit itself: a walk that read almost nothing means the
        // screen was never really pumped. Achievements is read-only, so the
        // node count is the check, not the tappable count.
        expect(audit.nodes, greaterThan(5), reason: screen.name);
        expect(
          audit.unlabeled
              .where((target) => !unlabeledAllowList.any(target.contains))
              .toList(),
          isEmpty,
          reason: 'tappables TalkBack would read as "button"',
        );
        semantics.dispose();
      });
    }
  }
}
