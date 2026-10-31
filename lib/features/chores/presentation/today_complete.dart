import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/features/chores/occurrences/domain/chore_item.dart';
import 'package:family_hub/features/chores/occurrences/presentation/occurrence_action_providers.dart';
import 'package:family_hub/features/chores/presentation/chores_failure_messages.dart';
import 'package:family_hub/features/family/presentation/family_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Completes [item] from a list row and offers an undo for five seconds
/// (P3-15).
///
/// Everything the undo needs (messenger, texts, the use cases, the ids) is
/// captured BEFORE the first `await`, so the snackbar action keeps working
/// after the row or the screen has gone away (CLAUDE: undo rule of P2-15).
Future<void> completeFromList(
  WidgetRef ref,
  BuildContext context,
  ChoreItem item,
) async {
  final familyId = ref.read(currentFamilyIdProvider);
  final uid = ref.read(currentUidProvider);
  if (familyId == null || uid == null) return;
  final messenger = ScaffoldMessenger.of(context);
  final l10n = context.l10n;
  final complete = ref.read(completeOccurrenceProvider);
  final uncomplete = ref.read(uncompleteOccurrenceProvider);

  final result = await complete(
    familyId: familyId,
    actorUid: uid,
    occurrenceId: item.id,
  );
  final failure = result.failureOrNull;
  if (failure != null) {
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.choresFailureMessage(failure))),
    );
    return;
  }
  messenger.showSnackBar(
    SnackBar(
      content: Text(l10n.statusCompleted),
      duration: const Duration(seconds: 5),
      action: SnackBarAction(
        label: l10n.todayUndo,
        onPressed: () async {
          final undone = await uncomplete(
            familyId: familyId,
            actorUid: uid,
            occurrenceId: item.id,
          );
          final error = undone.failureOrNull;
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                error == null
                    ? l10n.occurrenceUndone
                    : l10n.choresFailureMessage(error),
              ),
            ),
          );
        },
      ),
    ),
  );
}
