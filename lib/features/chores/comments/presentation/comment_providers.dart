import 'package:family_hub/app/theme/theme_controller.dart';
import 'package:family_hub/core/utils/clock_provider.dart';
import 'package:family_hub/features/chores/comments/domain/comment_flags.dart';
import 'package:family_hub/features/chores/comments/domain/comment_loader.dart';
import 'package:family_hub/features/chores/comments/domain/comment_repository.dart';
import 'package:family_hub/features/chores/comments/domain/occurrence_comment.dart';
import 'package:family_hub/features/chores/comments/domain/usecases/add_comment.dart';
import 'package:family_hub/features/chores/comments/domain/usecases/hide_comment.dart';
import 'package:family_hub/features/chores/comments/domain/usecases/mark_needs_attention.dart';
import 'package:family_hub/features/chores/comments/domain/usecases/resolve_comment.dart';
import 'package:family_hub/features/chores/comments/domain/usecases/unhide_comment.dart';
import 'package:family_hub/features/chores/duty_groups/presentation/duty_group_providers.dart';
import 'package:family_hub/features/chores/occurrences/presentation/inbox_port_provider.dart';
import 'package:family_hub/features/chores/occurrences/presentation/occurrence_providers.dart';
import 'package:family_hub/features/chores/settings/presentation/chore_settings_providers.dart';
import 'package:family_hub/features/chores/templates/presentation/template_providers.dart';
import 'package:family_hub/features/family/presentation/family_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Overridden in `bootstrap.dart` and in tests (same pattern as occurrences).
final commentRepositoryProvider = Provider<CommentRepository>(
  (ref) => throw UnimplementedError(
    'commentRepositoryProvider must be overridden (bootstrap.dart / tests).',
  ),
);

final commentLoaderProvider = Provider<CommentLoader>(
  (ref) => CommentLoader(
    occurrences: ref.watch(occurrenceRepositoryProvider),
    templates: ref.watch(templateRepositoryProvider),
    dutyGroups: ref.watch(dutyGroupRepositoryProvider),
    choreSettings: ref.watch(choreSettingsRepositoryProvider),
    families: ref.watch(familyRepositoryProvider),
    dateKeys: ref.watch(familyDateKeysProvider),
  ),
);

final addCommentProvider = Provider<AddComment>(
  (ref) => AddComment(
    loader: ref.watch(commentLoaderProvider),
    comments: ref.watch(commentRepositoryProvider),
    clock: ref.watch(clockProvider),
    inbox: ref.watch(inboxPortProvider),
  ),
);

final markNeedsAttentionProvider = Provider<MarkNeedsAttention>(
  (ref) => MarkNeedsAttention(ref.watch(addCommentProvider)),
);

final resolveCommentProvider = Provider<ResolveComment>(
  (ref) => ResolveComment(
    loader: ref.watch(commentLoaderProvider),
    comments: ref.watch(commentRepositoryProvider),
    clock: ref.watch(clockProvider),
  ),
);

final hideCommentProvider = Provider<HideComment>(
  (ref) => HideComment(
    loader: ref.watch(commentLoaderProvider),
    comments: ref.watch(commentRepositoryProvider),
    clock: ref.watch(clockProvider),
  ),
);

final unhideCommentProvider = Provider<UnhideComment>(
  (ref) => UnhideComment(
    loader: ref.watch(commentLoaderProvider),
    comments: ref.watch(commentRepositoryProvider),
    clock: ref.watch(clockProvider),
  ),
);

/// The thread of one chore: ONE listener, released when the screen leaves
/// (CLAUDE.md rule 11), bounded by `kMaxCommentsPerOccurrence`.
final commentsProvider = StreamProvider.autoDispose
    .family<List<OccurrenceComment>, String>((ref, occurrenceId) {
      final familyId = ref.watch(currentFamilyIdProvider);
      if (familyId == null) {
        return Stream.value(const <OccurrenceComment>[]);
      }
      return ref
          .watch(commentRepositoryProvider)
          .watchComments(familyId, occurrenceId);
    });

/// Bumped after every write of a local last-seen instant, so tiles rebuild.
final commentSeenTickProvider = NotifierProvider<CommentSeenTick, int>(
  CommentSeenTick.new,
);

class CommentSeenTick extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state++;
}

String _seenKey(String? familyId, String occurrenceId) =>
    'commentSeen.${familyId ?? '-'}.$occurrenceId';

/// The instant the viewer last read the thread of [occurrenceId] on THIS
/// device (D-P3-21: local only, not synced), or null when never.
final commentSeenAtProvider = Provider.family<DateTime?, String>((ref, id) {
  ref.watch(commentSeenTickProvider);
  final millis = ref
      .watch(sharedPreferencesProvider)
      .getInt(_seenKey(ref.watch(currentFamilyIdProvider), id));
  return millis == null
      ? null
      : DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true);
});

/// Whether a tile shows the "new comments" dot.  A chore nobody commented on
/// ([last] null) never reads the local store.
final hasUnreadCommentProvider =
    Provider.family<bool, ({String id, DateTime? last})>((ref, key) {
      final last = key.last;
      if (last == null) return false;
      return CommentFlags.hasUnread(
        last,
        ref.watch(commentSeenAtProvider(key.id)),
      );
    });

/// How many comments by OTHER people arrived since the viewer last looked.
final unreadCommentsProvider = Provider.autoDispose.family<int, String>((
  ref,
  occurrenceId,
) {
  final seen = ref.watch(commentSeenAtProvider(occurrenceId));
  final uid = ref.watch(currentUidProvider);
  final thread = ref.watch(commentsProvider(occurrenceId)).value ?? const [];
  return thread
      .where(
        (c) =>
            c.authorId != uid && (seen == null || c.createdAt.isAfter(seen)),
      )
      .length;
});

/// Remembers that the thread was read up to [upTo] (never moves backwards).
Future<void> markCommentsSeen(
  WidgetRef ref,
  String occurrenceId,
  DateTime upTo,
) async {
  final current = ref.read(commentSeenAtProvider(occurrenceId));
  if (current != null && !upTo.isAfter(current)) return;
  await ref
      .read(sharedPreferencesProvider)
      .setInt(
        _seenKey(ref.read(currentFamilyIdProvider), occurrenceId),
        upTo.millisecondsSinceEpoch,
      );
  ref.read(commentSeenTickProvider.notifier).bump();
}
