import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/core/utils/clock.dart';
import 'package:family_hub/features/family/domain/family_repository.dart';
import 'package:family_hub/features/notifications/domain/inbox_repository.dart';

/// Marks the actor's own inbox items as read (P3-26). Owner only: an id that
/// belongs to somebody else is `PermissionDenied`; an unknown id is skipped
/// (it may have been archived on another phone).
///
/// EVERYDAY write (queues offline). Items that are already read are not
/// written again, so repeating the call writes nothing.
class MarkInboxRead {
  const MarkInboxRead({
    required this.inbox,
    required this.families,
    required this.clock,
  });

  final InboxRepository inbox;
  final FamilyRepository families;
  final Clock clock;

  Future<Result<int>> call({
    required String familyId,
    required String actorUid,
    required List<String> ids,
  }) async {
    final member = (await families.getMember(familyId, actorUid)).valueOrNull;
    if (member == null || !member.isActive) {
      return const Failure<int>(PermissionDenied());
    }
    final unread = <String>[];
    for (final id in ids.toSet()) {
      final loaded = await inbox.get(familyId, id);
      final failure = loaded.failureOrNull;
      if (failure != null) return Failure<int>(failure);
      final item = loaded.valueOrNull;
      if (item == null) continue;
      if (item.toMemberId != actorUid) {
        return const Failure<int>(PermissionDenied());
      }
      if (item.readAt == null) unread.add(id);
    }
    if (unread.isEmpty) return const Success<int>(0);
    final written = await inbox.markRead(
      familyId,
      actorId: actorUid,
      ids: unread,
      at: clock.nowUtc(),
    );
    final writeFailure = written.failureOrNull;
    if (writeFailure != null) return Failure<int>(writeFailure);
    return Success<int>(unread.length);
  }
}
