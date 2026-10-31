import 'dart:async';

import 'package:family_hub/app/routing/app_routes.dart';
import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/features/chores/occurrences/domain/chore_item.dart';
import 'package:family_hub/features/chores/occurrences/domain/today_sections.dart';
import 'package:family_hub/features/chores/presentation/today_complete.dart';
import 'package:family_hub/features/chores/presentation/widgets/chore_tile.dart';
import 'package:family_hub/features/family/presentation/family_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';

/// One Today row: a [ChoreTile] inside a `Slidable` (D-P3-15).
///
/// Swipe right reveals "Mark done" (5 s undo), swipe left reveals "Details".
/// A pane only exists when the action can work: no "Mark done" on a finished
/// or skipped chore (U-08) or one the viewer may not complete, and no pane at
/// all on a projected item (U-03). The same two actions are exposed as custom
/// screen-reader actions, because TalkBack has no swipe gesture (U-11).
class TodayRow extends ConsumerWidget {
  const TodayRow({required this.item, super.key});

  final ChoreItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final t = context.tokens;
    final formatters = ref.watch(appFormattersProvider);
    final openable = canOpenOccurrence(item);
    final completable =
        openable && isActionableStatus(item.status) && mayComplete(ref, item);

    void open() => unawaited(context.push(AppRoutes.choresOccurrence(item.id)));
    void complete() => unawaited(completeFromList(ref, context, item));

    ActionPane pane(String label, IconData icon, VoidCallback run) =>
        ActionPane(
          motion: const DrawerMotion(),
          extentRatio: 0.4,
          children: [
            SlidableAction(
              onPressed: (_) => run(),
              backgroundColor: t.accentSoft,
              foregroundColor: t.accentStrong,
              icon: icon,
              label: label,
              borderRadius: BorderRadius.circular(t.radiusMd),
            ),
          ],
        );

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Slidable(
        key: ValueKey('today_${item.id}'),
        enabled: completable || openable,
        startActionPane: completable
            ? pane(
                l10n.occurrenceActionComplete,
                Icons.check_circle_outline_rounded,
                complete,
              )
            : null,
        endActionPane: openable
            ? pane(l10n.occurrenceDetailTitle, Icons.open_in_new_rounded, open)
            : null,
        child: ChoreTile(
          item: item,
          formatters: formatters,
          onTap: open,
          semanticActions: <CustomSemanticsAction, VoidCallback>{
            if (completable)
              CustomSemanticsAction(label: l10n.occurrenceActionComplete):
                  complete,
            if (openable)
              CustomSemanticsAction(label: l10n.occurrenceDetailTitle): open,
          },
        ),
      ),
    );
  }
}
