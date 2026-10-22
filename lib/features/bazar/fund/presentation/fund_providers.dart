import 'package:family_hub/features/bazar/fund/domain/fund_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Overridden in `bootstrap.dart` and in tests.
final fundRepositoryProvider = Provider<FundRepository>(
  (ref) => throw UnimplementedError(
    'fundRepositoryProvider must be overridden (bootstrap.dart / tests).',
  ),
);
