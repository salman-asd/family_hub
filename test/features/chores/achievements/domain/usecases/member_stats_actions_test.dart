import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/features/chores/achievements/domain/default_engagement_settings.dart';
import 'package:family_hub/features/chores/achievements/domain/engagement_settings.dart';
import 'package:family_hub/features/chores/achievements/domain/member_stats.dart';
import 'package:family_hub/features/chores/achievements/domain/member_stats_repository.dart';
import 'package:family_hub/features/chores/achievements/domain/public_stats.dart';
import 'package:family_hub/features/chores/achievements/domain/usecases/mark_celebrated.dart';
import 'package:family_hub/features/chores/achievements/domain/usecases/set_stats_sharing.dart';
import 'package:family_hub/features/family/domain/member.dart';
import 'package:family_hub/features/family/domain/member_role.dart';
import 'package:family_hub/features/family/domain/membership.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../support/in_memory_backend.dart';

void main() {
  const familyId = 'family';
  const memberId = 'member';
  final today = DateKey(2026, 11, 5);
  final startedOn = DateKey(2026, 10, 1);
  final settings = defaultEngagementSettings(
    startedOn: startedOn,
    graceMinutes: 30,
  );
  late InMemoryBackend families;
  late _StatsRepository stats;

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
  });

  test('sharing is opt-in and mirrors only a points-free card', () async {
    final useCase = SetStatsSharing(families: families, stats: stats);
    final denied = await useCase(
      familyId: familyId,
      memberId: memberId,
      sharing: true,
      settings: settings,
    );
    expect(denied.failureOrNull, isA<Validation>());
    expect(stats.reads, 0);

    final allowed = await useCase(
      familyId: familyId,
      memberId: memberId,
      sharing: true,
      settings: settings.copyWith(statsVisibility: StatsVisibility.levels),
    );
    expect(allowed.failureOrNull, isNull);
    expect(stats.current?.sharing, isTrue);
    expect(stats.publicCards.last, isNotNull);
    expect(stats.publicCards.last!.level, 1);
    expect(stats.publicCards.last!.badgeIds, isEmpty);
  });

  test('celebration date is monotonic and future dates are rejected', () async {
    final useCase = MarkCelebrated(families: families, stats: stats);
    final future = await useCase(
      familyId: familyId,
      memberId: memberId,
      dateKey: today.addDays(1),
      today: today,
      settings: settings,
    );
    expect(future.failureOrNull, isA<Validation>());
    expect(stats.reads, 0);

    final marked = await useCase(
      familyId: familyId,
      memberId: memberId,
      dateKey: today,
      today: today,
      settings: settings,
    );
    expect(marked.failureOrNull, isNull);
    expect(marked.valueOrNull, isTrue);
    expect(stats.current?.lastCelebratedDateKey, today);
    final writes = stats.writes;

    final repeated = await useCase(
      familyId: familyId,
      memberId: memberId,
      dateKey: today,
      today: today,
      settings: settings,
    );
    expect(repeated.failureOrNull, isNull);
    expect(repeated.valueOrNull, isFalse);
    expect(stats.writes, writes);
  });
}

final class _StatsRepository implements MemberStatsRepository {
  MemberStats? current;
  int reads = 0;
  int writes = 0;
  final List<PublicStats?> publicCards = <PublicStats?>[];

  @override
  Stream<MemberStats?> watch(
    String familyId,
    String memberId, {
    required DateKey defaultStartedOn,
  }) => Stream<MemberStats?>.value(current);

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
    writes++;
    current = stats;
    publicCards.add(publicStats);
    return const Success<void>(null);
  }

  @override
  Future<Result<bool>> claimCelebration(
    String familyId,
    String memberId, {
    required DateKey dateKey,
    required DateKey defaultStartedOn,
  }) async {
    final previous = current ?? MemberStats.empty(startedOn: defaultStartedOn);
    final celebrated = previous.lastCelebratedDateKey;
    if (celebrated != null && !dateKey.isAfter(celebrated)) {
      return const Success<bool>(false);
    }
    current = previous.copyWith(lastCelebratedDateKey: dateKey);
    writes++;
    return const Success<bool>(true);
  }
}
