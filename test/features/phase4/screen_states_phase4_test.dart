import '../../support/screen_states.dart';
import 'phase4_test_support.dart';

/// P4-23: every screen Phase 4 touched, run through the shared state +
/// accessibility harness (loading / data / empty / error / offline x themes x
/// locales x 200% text).
void main() {
  for (final screen in phase4Screens) {
    screenStateTests(
      screen.name,
      screen.build,
      states: phase4States,
      overrides: screen.overrides,
    );
  }
}
