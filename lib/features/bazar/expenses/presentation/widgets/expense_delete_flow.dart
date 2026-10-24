import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/features/bazar/expenses/domain/expense.dart';
import 'package:family_hub/features/bazar/expenses/domain/usecases/restore_expense.dart';
import 'package:family_hub/features/bazar/expenses/presentation/expense_providers.dart';
import 'package:family_hub/features/bazar/presentation/bazar_failure_messages.dart';
import 'package:family_hub/features/family/presentation/family_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// How long the Undo snackbar stays up after a delete.
const Duration kUndoDuration = Duration(seconds: 6);

/// Asks, deletes, then offers Undo.  Returns `true` once the expense is
/// deleted.  Undo is a plain restore that queues offline like any entry.
///
/// Everything the Undo needs is captured before the first `await`, so the
/// snackbar keeps working after the screen that started it has closed.
Future<bool> confirmAndDeleteExpense(
  BuildContext context,
  WidgetRef ref,
  Expense expense,
) async {
  final l10n = context.l10n;
  final messenger = ScaffoldMessenger.of(context);
  final familyId = ref.read(currentFamilyIdProvider);
  final uid = ref.read(currentUidProvider);
  final softDelete = ref.read(softDeleteExpenseProvider);
  final RestoreExpense restore = ref.read(restoreExpenseProvider);
  if (familyId == null || uid == null) return false;

  final confirmed = await showModalBottomSheet<bool>(
    context: context,
    showDragHandle: true,
    builder: (_) => _ConfirmDeleteSheet(name: expense.itemName),
  );
  if (confirmed != true) return false;

  final result = await softDelete(
    actorUid: uid,
    familyId: familyId,
    expenseId: expense.id,
  );
  final failure = result.failureOrNull;
  if (failure != null) {
    messenger.showSnackBar(SnackBar(content: Text(l10n.bazarFailureMessage(failure))));
    return false;
  }

  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        duration: kUndoDuration,
        content: Text(l10n.expenseDeleted),
        action: SnackBarAction(
          label: l10n.actionUndo,
          onPressed: () async {
            final undone = await restore(
              actorUid: uid,
              familyId: familyId,
              expenseId: expense.id,
            );
            final undoFailure = undone.failureOrNull;
            messenger.showSnackBar(
              SnackBar(
                content: Text(
                  undoFailure == null
                      ? l10n.expenseRestored
                      : l10n.bazarFailureMessage(undoFailure),
                ),
              ),
            );
          },
        ),
      ),
    );
  return true;
}

/// Brings a deleted expense back (managers, from the detail screen).
Future<AppFailure?> restoreDeletedExpense(
  WidgetRef ref,
  Expense expense,
) async {
  final familyId = ref.read(currentFamilyIdProvider);
  final uid = ref.read(currentUidProvider);
  if (familyId == null || uid == null) return const PermissionDenied();
  final result = await ref.read(restoreExpenseProvider)(
    actorUid: uid,
    familyId: familyId,
    expenseId: expense.id,
  );
  return result.failureOrNull;
}

class _ConfirmDeleteSheet extends StatelessWidget {
  const _ConfirmDeleteSheet({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final t = context.tokens;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.expenseDeleteTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.expenseDeleteMessage(name),
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: t.textSecondary),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                key: const ValueKey('confirm-delete'),
                style: FilledButton.styleFrom(
                  backgroundColor: t.danger,
                  foregroundColor: t.textOnAccent,
                ),
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(l10n.actionDelete),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(l10n.actionCancel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
