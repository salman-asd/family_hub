import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/features/notifications/domain/inbox_item.dart';
import 'package:family_hub/features/notifications/domain/usecases/mark_inbox_read.dart';

/// Marks all unread persisted rows through [MarkInboxRead]. Virtual rows are
/// acknowledged locally by the presentation layer and are never written.
class MarkAllRead {
  const MarkAllRead(this._markInboxRead);

  final MarkInboxRead _markInboxRead;

  Future<Result<int>> call({
    required String familyId,
    required String actorUid,
    required List<InboxItem> items,
  }) {
    final storedIds = <String>[
      for (final item in items)
        if (item.isUnread && !item.id.startsWith('v:')) item.id,
    ];
    if (storedIds.isEmpty) return Future.value(const Success<int>(0));
    return _markInboxRead(
      familyId: familyId,
      actorUid: actorUid,
      ids: storedIds,
    );
  }
}
