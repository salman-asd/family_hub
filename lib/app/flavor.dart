import 'package:flutter_riverpod/flutter_riverpod.dart';

enum Flavor {
  dev,
  prod;

  String get label => this == Flavor.dev ? 'Family Hub (dev)' : 'Family Hub';
}

/// The running flavor.
///
/// Has no default: `bootstrap.dart` overrides it with the flavor passed to
/// `main_dev.dart` / `main_prod.dart`, and tests override it explicitly.
final flavorProvider = Provider<Flavor>(
  (ref) => throw UnimplementedError(
    'flavorProvider must be overridden (bootstrap.dart / tests).',
  ),
);
