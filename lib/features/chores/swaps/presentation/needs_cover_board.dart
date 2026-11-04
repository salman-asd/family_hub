import 'dart:async';

import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/core/permissions/permissions.dart';
import 'package:family_hub/features/chores/calendar/presentation/calendar_items_providers.dart';
import 'package:family_hub/features/chores/occurrences/domain/chore_item.dart';
import 'package:family_hub/features/chores/occurrences/domain/occurrence_status.dart';
import 'package:family_hub/features/chores/presentation/date_of_key.dart';
import 'package:family_hub/features/chores/presentation/member_names.dart';
import 'package:family_hub/features/chores/presentation/occurrence_action_sheets.dart';
import 'package:family_hub/features/family/presentation/family_providers.dart';
import 'package:family_hub/features/family/presentation/permission_providers.dart';
import 'package:family_hub/shared/widgets/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The chores that still need somebody (P3-27, managers): nobody owns them, or
/// the owner is away or inactive. One tap assigns a person (the same sheets as
/// the detail screen). Upcoming and open chores of this month only.
class NeedsCoverBoard extends ConsumerWidget {
  const NeedsCoverBoard({super.key});

  bool _open(ChoreItem item) =>
      item.status != ChoreStatus.completed &&
      item.status != ChoreStatus.verified &&
      item.status != ChoreStatus.skipped;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final t = context.tokens;
    final formatters = ref.watch(appFormattersProvider);
    final keys = ref.watch(familyDateKeysProvider);
    final today = keys.today();
    final members = ref.watch(membersProvider).value ?? const [];
    final month = ref.watch(monthItemsProvider(keys.thisMonth()));
    final canAssign = ref.can(Permission.reassignChore);
    final needing = <ChoreItem>[
      for (final item in month.value?.items ?? const <ChoreItem>[])
        if (!item.isProjected &&
            _open(item) &&
            !item.dateKey.isBefore(today) &&
            (item.assigneeId == null || item.flags.contains(ChoreFlag.needsCover)))
          item,
    ];
    return Scaffold(
      appBar: AppBar(title: Text(l10n.needsCoverTitle)),
      body: !canAssign
          ? EmptyState(icon: Icons.lock_outline_rounded, title: l10n.needsCoverNoAccess)
          : needing.isEmpty
          ? EmptyState(icon: Icons.verified_outlined, title: l10n.needsCoverEmpty)
          : ListView(
              children: [
                for (final item in needing)
                  ListTile(
                    key: Key('needs_cover_${item.id}'),
                    minVerticalPadding: 12,
                    title: Text(item.nameBn),
                    subtitle: Text(
                      '${formatters.fullDate(dateOfKey(item.dateKey))}'
                      '${item.assigneeId == null ? '' : ' · ${memberNameOf(members, item.assigneeId)}'}',
                      style: TextStyle(color: t.textSecondary),
                    ),
                    trailing: FilledButton(
                      style: FilledButton.styleFrom(minimumSize: const Size(48, 48)),
                      onPressed: () => unawaited(
                        ref.reassignWithSheets(context, occurrenceId: item.id),
                      ),
                      child: Text(l10n.needsCoverAssign),
                    ),
                  ),
              ],
            ),
    );
  }
}
