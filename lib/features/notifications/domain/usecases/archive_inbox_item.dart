import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/core/utils/clock.dart';
import 'package:family_hub/features/family/domain/family_repository.dart';
import 'package:family_hub/features/notifications/domain/inbox_repository.dart';

/// Archives one of the actor's own inbox items (P3-26): it disappears from the
/// list but the row stays (soft delete, CLAUDE.md rule 5). Owner only.
class ArchiveInboxItem {
  const ArchiveInboxItem({
    required this.inbox,
    required this.families,
    required this.clock,
  });

  final InboxRepository inbox;
  final FamilyRepository families;
  final Clock clock;

  Future<Result<void>> call({
    required String familyId,
    required String actorUid,
    required String itemId,
  }) async {
    final member = (await families.getMember(familyId, actorUid)).valueOrNull;
    if (member == null || !member.isActive) {
      return const Failure<void>(PermissionDenied());
    }
    final loaded = await inbox.get(familyId, itemId);
    final failure = loaded.failureOrNull;
    if (failure != null) return Failure<void>(failure);
    final item = loaded.valueOrNull;
    if (item == null) return const Failure<void>(NotFound(entity: 'inboxItem'));
    if (item.toMemberId != actorUid) {
      return const Failure<void>(PermissionDenied());
    }
    if (item.isArchived) return const Success<void>(null);
    return inbox.archive(
      familyId,
      actorId: actorUid,
      id: itemId,
      at: clock.nowUtc(),
    );
  }
}
