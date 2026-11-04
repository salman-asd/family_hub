import 'package:family_hub/core/utils/clock_provider.dart';
import 'package:family_hub/features/family/presentation/family_providers.dart';
import 'package:family_hub/features/notifications/domain/inbox_item.dart';
import 'package:family_hub/features/notifications/domain/inbox_repository.dart';
import 'package:family_hub/features/notifications/domain/no_inbox_repository.dart';
import 'package:family_hub/features/notifications/domain/usecases/archive_inbox_item.dart';
import 'package:family_hub/features/notifications/domain/usecases/mark_inbox_read.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Overridden in `bootstrap.dart` and in tests; the default inbox is empty.
final inboxRepositoryProvider = Provider<InboxRepository>(
  (ref) => const NoInboxRepository(),
);

/// MY newest inbox items (archived ones hidden): ONE listener, at most
/// `kMaxInboxDocs`, newest first.
final inboxProvider = StreamProvider<List<InboxItem>>((ref) {
  final familyId = ref.watch(currentFamilyIdProvider);
  final uid = ref.watch(currentUidProvider);
  if (familyId == null || uid == null) {
    return Stream.value(const <InboxItem>[]);
  }
  return ref
      .watch(inboxRepositoryProvider)
      .watchMine(familyId, uid)
      .map(
        (items) => <InboxItem>[
          for (final item in items)
            if (!item.isArchived) item,
        ],
      );
});

/// The badge number of the bell.
final unreadInboxCountProvider = Provider<int>(
  (ref) =>
      (ref.watch(inboxProvider).value ?? const <InboxItem>[])
          .where((item) => item.isUnread)
          .length,
);

final markInboxReadProvider = Provider<MarkInboxRead>(
  (ref) => MarkInboxRead(
    inbox: ref.watch(inboxRepositoryProvider),
    families: ref.watch(familyRepositoryProvider),
    clock: ref.watch(clockProvider),
  ),
);

final archiveInboxItemProvider = Provider<ArchiveInboxItem>(
  (ref) => ArchiveInboxItem(
    inbox: ref.watch(inboxRepositoryProvider),
    families: ref.watch(familyRepositoryProvider),
    clock: ref.watch(clockProvider),
  ),
);
