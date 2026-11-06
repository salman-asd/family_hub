part of 'chore_item.dart';

const Object _unset = Object();

/// `copyWith`'s nullable fields: no argument keeps the value, `null` clears it.
T? _pick<T>(Object? value, T? current) =>
    identical(value, _unset) ? current : value as T?;

/// A badge the UI may show on a chore tile (road map P3-11).
enum ChoreFlag {
  /// Completed, the template requires verification and nobody verified yet.
  awaitingVerification,

  /// Nobody can do it: the stored flag, or the assignee is absent that day.
  needsCover,

  /// A comment asked for attention.
  needsAttention,

  /// Not written yet (a draft from the generator, D-P3-6): read-only.
  isProjected,

  /// This member is covering somebody else's chore.
  isCover,

  /// A swap request is still open (P3-26 supplies the request).
  hasPendingSwap,
}

/// How far through its subtasks a chore is. `total == 0` means the chore has no
/// subtasks, so the UI hides the counter instead of showing "0/0".
final class ChoreProgress {
  const ChoreProgress({required this.done, required this.total});

  static const ChoreProgress none = ChoreProgress(done: 0, total: 0);

  final int done;
  final int total;

  bool get hasSubtasks => total > 0;

  bool get isComplete => total > 0 && done >= total;

  @override
  bool operator ==(Object other) =>
      other is ChoreProgress && other.done == done && other.total == total;

  @override
  int get hashCode => Object.hash(done, total);

  @override
  String toString() => 'ChoreProgress($done/$total)';
}
