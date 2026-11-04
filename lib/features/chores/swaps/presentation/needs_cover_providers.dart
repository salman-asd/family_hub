import 'package:family_hub/core/permissions/permissions.dart';
import 'package:family_hub/features/chores/calendar/presentation/calendar_items_providers.dart';
import 'package:family_hub/features/chores/occurrences/domain/chore_item.dart';
import 'package:family_hub/features/chores/occurrences/domain/occurrence_status.dart';
import 'package:family_hub/features/family/presentation/family_providers.dart';
import 'package:family_hub/features/family/presentation/permission_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The chores that still need somebody: stored, open, from today on, and either
/// nobody owns them or the owner is away or inactive. Shared by the needs-cover
/// board and the badge on its Manage tile (P3-29), so the two always agree.
final needsCoverItemsProvider = Provider<List<ChoreItem>>((ref) {
  final keys = ref.watch(familyDateKeysProvider);
  final today = keys.today();
  final month = ref.watch(monthItemsProvider(keys.thisMonth()));
  return <ChoreItem>[
    for (final item in month.value?.items ?? const <ChoreItem>[])
      if (!item.isProjected &&
          _isOpen(item) &&
          !item.dateKey.isBefore(today) &&
          (item.assigneeId == null ||
              item.flags.contains(ChoreFlag.needsCover)))
        item,
  ];
});

bool _isOpen(ChoreItem item) =>
    item.status != ChoreStatus.completed &&
    item.status != ChoreStatus.verified &&
    item.status != ChoreStatus.skipped;

/// The Manage badge: zero for anybody who may not assign (no point counting
/// what they cannot act on).
final needsCoverCountProvider = Provider<int>((ref) {
  if (!ref.can(Permission.reassignChore)) return 0;
  return ref.watch(needsCoverItemsProvider).length;
});
