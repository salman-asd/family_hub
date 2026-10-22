import 'package:family_hub/features/bazar/expenses/domain/expense_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Overridden in `bootstrap.dart` and in tests.
final expenseRepositoryProvider = Provider<ExpenseRepository>(
  (ref) => throw UnimplementedError(
    'expenseRepositoryProvider must be overridden (bootstrap.dart / tests).',
  ),
);
