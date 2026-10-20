import 'package:family_hub/core/utils/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The injected "now" (CLAUDE.md hard rule 2).
///
/// This is the ONLY file in `core/utils/` that may import `flutter_riverpod`
/// (enforced by `test/architecture/layer_boundaries_test.dart`): [Clock] itself
/// stays pure Dart so domain code can depend on it.
final Provider<Clock> clockProvider = Provider<Clock>(
  (ref) => const SystemClock(),
);
