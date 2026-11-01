import 'dart:async';

import 'package:family_hub/app/routing/app_routes.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/features/chores/occurrences/domain/chore_item.dart';
import 'package:family_hub/features/chores/occurrences/domain/today_sections.dart';
import 'package:family_hub/features/chores/presentation/today_complete.dart';
import 'package:family_hub/features/chores/presentation/widgets/chore_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// What a long press on a chore can offer (P3-23). Swap and reassign join the
/// list with P3-26; until their providers exist they are simply absent.
enum QuickAction { complete, details }

/// The actions that WORK for [item] and the viewer: a planned (projected)
/// chore has no document to open or complete, a finished one is not completed
/// again, and "Mark done" only shows for somebody who may complete it.
List<QuickAction> quickActionsFor(ChoreItem item, {required bool mayComplete}) {
  if (!canOpenOccurrence(item)) return const <QuickAction>[];
  return <QuickAction>[
    if (isActionableStatus(item.status) && mayComplete) QuickAction.complete,
    QuickAction.details,
  ];
}

/// The long-press sheet. Does nothing when no action is allowed.
Future<void> showQuickActionsSheet(
  BuildContext context,
  WidgetRef ref,
  ChoreItem item,
) async {
  final actions = quickActionsFor(item, mayComplete: mayComplete(ref, item));
  if (actions.isEmpty) return;
  final chosen = await showModalBottomSheet<QuickAction>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      final l10n = context.l10n;
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final action in actions)
              ListTile(
                key: Key('calendar_quick_${action.name}'),
                minVerticalPadding: 12,
                leading: Icon(
                  action == QuickAction.complete
                      ? Icons.check_circle_outline_rounded
                      : Icons.open_in_new_rounded,
                ),
                title: Text(
                  action == QuickAction.complete
                      ? l10n.occurrenceActionComplete
                      : l10n.occurrenceDetailTitle,
                ),
                onTap: () => Navigator.of(context).pop(action),
              ),
          ],
        ),
      );
    },
  );
  if (chosen == null || !context.mounted) return;
  switch (chosen) {
    case QuickAction.complete:
      await completeFromList(ref, context, item);
    case QuickAction.details:
      unawaited(context.push(AppRoutes.choresOccurrence(item.id)));
  }
}
