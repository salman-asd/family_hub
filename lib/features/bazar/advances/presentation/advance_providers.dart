import 'package:family_hub/features/bazar/advances/domain/advance_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Overridden in `bootstrap.dart` and in tests.
final advanceRepositoryProvider = Provider<AdvanceRepository>(
  (ref) => throw UnimplementedError(
    'advanceRepositoryProvider must be overridden (bootstrap.dart / tests).',
  ),
);
