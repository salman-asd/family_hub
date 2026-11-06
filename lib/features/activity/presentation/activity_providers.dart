import 'package:family_hub/core/firebase/query_limits.dart';
import 'package:family_hub/features/activity/domain/activity_entry.dart';
import 'package:family_hub/features/activity/domain/activity_filter.dart';
import 'package:family_hub/features/activity/domain/activity_repository.dart';
import 'package:family_hub/features/family/presentation/family_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Replaced by the Firestore implementation in `bootstrap.dart`.
final activityRepositoryProvider = Provider<ActivityRepository>(
  (ref) => throw UnimplementedError(
    'activityRepositoryProvider must be overridden in bootstrap.dart / tests.',
  ),
);

/// The five newest entries for a dashboard card (P4-07).
final recentActivityProvider = StreamProvider.autoDispose
    .family<List<ActivityEntry>, int>((ref, limit) {
      final familyId = ref.watch(currentFamilyIdProvider);
      if (familyId == null) return Stream.value(const <ActivityEntry>[]);
      return ref
          .watch(activityRepositoryProvider)
          .watchRecent(
            familyId,
            limit: limit.clamp(1, kMaxDashboardActivity).toInt(),
          );
    });

/// The live, bounded first page. Member filtering is server-side.
final activityFirstPageProvider = StreamProvider.autoDispose
    .family<ActivityPage, String?>((ref, actorId) {
      final familyId = ref.watch(currentFamilyIdProvider);
      if (familyId == null) return Stream.value(ActivityPage.empty());
      return ref
          .watch(activityRepositoryProvider)
          .watchFirstPage(familyId, actorId: actorId, limit: kMaxActivityPage);
    });

final activityFilterProvider =
    NotifierProvider<ActivityFilterController, ActivityFilter>(
      ActivityFilterController.new,
    );

class ActivityFilterController extends Notifier<ActivityFilter> {
  @override
  ActivityFilter build() => const ActivityFilter();

  void setModule(ActivityModuleFilter module) {
    state = state.copyWith(module: module);
  }

  void setActor(String? actorId) {
    state = state.copyWith(actorId: actorId, clearActor: actorId == null);
  }
}

final class ActivityOlderPagesState {
  const ActivityOlderPagesState({
    this.entries = const <ActivityEntry>[],
    this.cursorId,
    this.hasMore,
    this.isLoading = false,
    this.failure,
  });

  final List<ActivityEntry> entries;
  final String? cursorId;
  final bool? hasMore;
  final bool isLoading;
  final Object? failure;

  ActivityOlderPagesState copyWith({
    List<ActivityEntry>? entries,
    String? cursorId,
    bool clearCursor = false,
    bool? hasMore,
    bool? isLoading,
    Object? failure,
    bool clearFailure = false,
  }) => ActivityOlderPagesState(
    entries: entries ?? this.entries,
    cursorId: clearCursor ? null : cursorId ?? this.cursorId,
    hasMore: hasMore ?? this.hasMore,
    isLoading: isLoading ?? this.isLoading,
    failure: clearFailure ? null : failure ?? this.failure,
  );
}

/// One-shot older pages keyed by actor filter; only page one has a listener.
final activityOlderPagesProvider =
    NotifierProvider<
      ActivityOlderPagesController,
      Map<String?, ActivityOlderPagesState>
    >(ActivityOlderPagesController.new);

class ActivityOlderPagesController
    extends Notifier<Map<String?, ActivityOlderPagesState>> {
  @override
  Map<String?, ActivityOlderPagesState> build() =>
      const <String?, ActivityOlderPagesState>{};

  ActivityOlderPagesState stateFor(String? actorId) =>
      state[actorId] ?? const ActivityOlderPagesState();

  Future<void> loadMore({
    required String familyId,
    required String? actorId,
    required ActivityPage firstPage,
  }) async {
    final current = stateFor(actorId);
    if (current.isLoading ||
        (current.hasMore == false && current.cursorId != null)) {
      return;
    }
    final cursorId = current.cursorId ?? firstPage.cursorId;
    if (cursorId == null || (current.cursorId == null && !firstPage.hasMore)) {
      return;
    }

    _update(actorId, current.copyWith(isLoading: true, clearFailure: true));
    final result = await ref
        .read(activityRepositoryProvider)
        .readOlderPage(
          familyId,
          actorId: actorId,
          afterDocumentId: cursorId,
          limit: kMaxActivityPage,
        );
    result.when(
      success: (page) {
        final seen = <String>{for (final entry in current.entries) entry.id};
        final appended = <ActivityEntry>[
          ...current.entries,
          for (final entry in page.entries)
            if (seen.add(entry.id)) entry,
        ];
        _update(
          actorId,
          ActivityOlderPagesState(
            entries: appended,
            cursorId: page.cursorId ?? cursorId,
            hasMore: page.hasMore,
          ),
        );
      },
      failure: (failure) => _update(
        actorId,
        current.copyWith(isLoading: false, failure: failure),
      ),
    );
  }

  void _update(String? actorId, ActivityOlderPagesState value) {
    state = <String?, ActivityOlderPagesState>{...state, actorId: value};
  }
}
