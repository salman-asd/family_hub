import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/core/firebase/query_limits.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/features/chores/achievements/domain/default_engagement_settings.dart';
import 'package:family_hub/features/chores/achievements/domain/engagement_settings.dart';
import 'package:family_hub/features/chores/achievements/domain/member_stats.dart';
import 'package:family_hub/features/chores/achievements/domain/member_stats_repository.dart';
import 'package:family_hub/features/chores/achievements/domain/public_stats.dart';
import 'package:family_hub/features/chores/achievements/domain/public_stats_repository.dart';
import 'package:family_hub/features/chores/achievements/domain/usecases/sync_member_stats.dart';
import 'package:family_hub/features/chores/occurrences/domain/chore_occurrence.dart';
import 'package:family_hub/features/family/domain/member.dart';
import 'package:family_hub/features/family/domain/member_role.dart';
import 'package:family_hub/features/family/domain/membership.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../support/in_memory_backend.dart';
import '../../../../../support/in_memory_chores_backend.dart';
import '../engagement_test_support.dart';

void main() {
  const familyId = 'family';
  const memberId = 'member';
  final today = DateKey(2026, 11, 1);
  final settings = defaultEngagementSettings(
    startedOn: DateKey(2026, 10, 1),
    graceMinutes: 30,
  );

  late InMemoryBackend families;
  late _StatsRepository stats;
  late _PublicStatsRepository publicStats;
  late _CountingOccurrences occurrences;
  late SyncMemberStats sync;

  setUp(() {
    families = InMemoryBackend()
      ..members[familyId] = <String, Member>{
        memberId: const Member(
          uid: memberId,
          role: MemberRole.member,
          status: MembershipStatus.active,
          fullName: 'Member',
          relationship: 'other',
        ),
      };
    stats = _StatsRepository();
    publicStats = _PublicStatsRepository();
    stats.onPublicSave = (value) => publicStats.current = value;
    occurrences = _CountingOccurrences();
    sync = SyncMemberStats(
      families: families,
      stats: stats,
      publicStats: publicStats,
      previousMonthItemsLoader: (familyId, month) {
        final range = monthRange(month);
        return occurrences.listRangeOnce(
          familyId,
          from: range.start,
          to: range.end,
          limit: kMaxOccurrencesPerMonth,
        );
      },
    );
  });

  test(
    'first sync initializes, computes, and finalizes prior month once',
    () async {
      final first = await sync(
        familyId: familyId,
        memberId: memberId,
        today: today,
        settings: settings,
        currentMonthItems: const <ChoreOccurrence>[],
      );
      expect(first.failureOrNull, isNull);
      expect(first.valueOrNull?.monthly['2026-10']?.isFinal, isTrue);
      expect(first.valueOrNull?.monthly['2026-11']?.isFinal, isFalse);
      expect(occurrences.monthReads, 1);
      expect(stats.writes, 2);

      final second = await sync(
        familyId: familyId,
        memberId: memberId,
        today: today,
        settings: settings,
        currentMonthItems: const <ChoreOccurrence>[],
      );
      expect(second.failureOrNull, isNull);
      expect(occurrences.monthReads, 1);
      expect(stats.writes, 2);
    },
  );

  test('disabled engagement does not read or write private stats', () async {
    final result = await sync(
      familyId: familyId,
      memberId: memberId,
      today: today,
      settings: settings.copyWith(enabled: false),
      currentMonthItems: const <ChoreOccurrence>[],
    );
    expect(result.valueOrNull, isNull);
    expect(stats.reads, 0);
    expect(stats.writes, 0);
    expect(occurrences.monthReads, 0);
  });

  test(
    'opted-in cards are mirrored only when visibility allows them',
    () async {
      stats.current = MemberStats.empty(startedOn: settings.startedOn)
          .copyWith(sharing: true);
      final result = await sync(
        familyId: familyId,
        memberId: memberId,
        today: today,
        settings: settings.copyWith(statsVisibility: StatsVisibility.levels),
        currentMonthItems: const <ChoreOccurrence>[],
      );
      expect(result.failureOrNull, isNull);
      expect(stats.publicCards.last, isNotNull);

      await sync(
        familyId: familyId,
        memberId: memberId,
        today: today,
        settings: settings.copyWith(statsVisibility: StatsVisibility.private),
        currentMonthItems: const <ChoreOccurrence>[],
      );
      expect(stats.publicCards.last, isNull);
    },
  );

  test('private write failure is returned to the caller', () async {
    stats.nextFailure = const Network();
    final result = await sync(
      familyId: familyId,
      memberId: memberId,
      today: today,
      settings: settings,
      currentMonthItems: const <ChoreOccurrence>[],
    );
    expect(result.failureOrNull, isA<Network>());
  });

  test('absence-neutral eligibility is applied to synced stats', () async {
    final result = await sync(
      familyId: familyId,
      memberId: memberId,
      today: today,
      settings: settings,
      currentMonthItems: <ChoreOccurrence>[engagementOccurrence(day: today)],
      absenceNeutral: (_) => true,
    );

    expect(result.failureOrNull, isNull);
    expect(result.valueOrNull?.completedTotal, 0);
    expect(result.valueOrNull?.totalPoints, 0);
  });
}

final class _StatsRepository implements MemberStatsRepository {
  MemberStats? current;
  int reads = 0;
  int writes = 0;
  AppFailure? nextFailure;
  void Function(PublicStats? value)? onPublicSave;
  final List<PublicStats?> publicCards = <PublicStats?>[];

  @override
  Stream<MemberStats?> watch(
    String familyId,
    String memberId, {
    required DateKey defaultStartedOn,
  }) => Stream.value(current);

  @override
  Future<Result<MemberStats?>> get(
    String familyId,
    String memberId, {
    required DateKey defaultStartedOn,
  }) async {
    reads++;
    return Success<MemberStats?>(current);
  }

  @override
  Future<Result<void>> save(
    String familyId,
    String memberId,
    MemberStats stats, {
    required PublicStats? publicStats,
  }) async {
    final failure = nextFailure;
    if (failure != null) {
      nextFailure = null;
      return Failure<void>(failure);
    }
    writes++;
    current = stats;
    publicCards.add(publicStats);
    onPublicSave?.call(publicStats);
    return const Success<void>(null);
  }
}

final class _PublicStatsRepository implements PublicStatsRepository {
  PublicStats? current;

  @override
  Stream<PublicStats?> watch(String familyId, String memberId) =>
      Stream<PublicStats?>.value(current);

  @override
  Stream<Map<String, PublicStats>> watchFamily(String familyId) =>
      Stream<Map<String, PublicStats>>.value(const <String, PublicStats>{});

  @override
  Future<Result<PublicStats?>> get(String familyId, String memberId) async =>
      Success<PublicStats?>(current);
}

final class _CountingOccurrences extends InMemoryOccurrenceBackend {
  int monthReads = 0;

  @override
  Future<Result<List<ChoreOccurrence>>> listRangeOnce(
    String familyId, {
    required DateKey from,
    required DateKey to,
    required int limit,
  }) {
    monthReads++;
    return super.listRangeOnce(familyId, from: from, to: to, limit: limit);
  }
}
