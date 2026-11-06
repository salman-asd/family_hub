import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/features/chores/achievements/domain/scoring/streak_calculator.dart';

final class BadgeEarned {
  const BadgeEarned({required this.earnedAt, this.monthKey});

  final DateKey earnedAt;
  final MonthKey? monthKey;

  BadgeEarned copyWith({
    DateKey? earnedAt,
    MonthKey? monthKey,
    bool clearMonthKey = false,
  }) => BadgeEarned(
    earnedAt: earnedAt ?? this.earnedAt,
    monthKey: clearMonthKey ? null : (monthKey ?? this.monthKey),
  );

  @override
  bool operator ==(Object other) =>
      other is BadgeEarned &&
      other.earnedAt == earnedAt &&
      other.monthKey == monthKey;

  @override
  int get hashCode => Object.hash(earnedAt, monthKey);
}

final class MonthlyStats {
  const MonthlyStats({
    required this.points,
    required this.done,
    required this.onTime,
    required this.covers,
    required this.verifiedClean,
    required this.isFinal,
    required this.specVersion,
  }) : assert(points >= 0),
       assert(done >= 0),
       assert(onTime >= 0),
       assert(covers >= 0),
       assert(verifiedClean >= 0);

  final int points;
  final int done;
  final int onTime;
  final int covers;
  final int verifiedClean;
  final bool isFinal;
  final int specVersion;

  MonthlyStats maxWith(MonthlyStats other, {required bool finalized}) =>
      MonthlyStats(
        points: points > other.points ? points : other.points,
        done: done > other.done ? done : other.done,
        onTime: onTime > other.onTime ? onTime : other.onTime,
        covers: covers > other.covers ? covers : other.covers,
        verifiedClean: verifiedClean > other.verifiedClean
            ? verifiedClean
            : other.verifiedClean,
        isFinal: finalized || isFinal || other.isFinal,
        specVersion: isFinal ? specVersion : other.specVersion,
      );

  MonthlyStats copyWith({
    int? points,
    int? done,
    int? onTime,
    int? covers,
    int? verifiedClean,
    bool? isFinal,
    int? specVersion,
  }) => MonthlyStats(
    points: points ?? this.points,
    done: done ?? this.done,
    onTime: onTime ?? this.onTime,
    covers: covers ?? this.covers,
    verifiedClean: verifiedClean ?? this.verifiedClean,
    isFinal: isFinal ?? this.isFinal,
    specVersion: specVersion ?? this.specVersion,
  );

  @override
  bool operator ==(Object other) =>
      other is MonthlyStats &&
      other.points == points &&
      other.done == done &&
      other.onTime == onTime &&
      other.covers == covers &&
      other.verifiedClean == verifiedClean &&
      other.isFinal == isFinal &&
      other.specVersion == specVersion;

  @override
  int get hashCode => Object.hash(
    points,
    done,
    onTime,
    covers,
    verifiedClean,
    isFinal,
    specVersion,
  );
}

final class MemberStats {
  MemberStats({
    required this.totalPoints,
    required this.level,
    required this.completedTotal,
    required this.onTimeTotal,
    required this.coversTotal,
    required this.verifiedCleanTotal,
    required this.streak,
    required Map<String, BadgeEarned> badges,
    required Map<String, MonthlyStats> monthly,
    required this.processedThrough,
    required this.lastCelebratedDateKey,
    required this.startedOn,
    required this.sharing,
  }) : badges = Map<String, BadgeEarned>.unmodifiable(badges),
       monthly = Map<String, MonthlyStats>.unmodifiable(monthly);

  factory MemberStats.empty({required DateKey startedOn}) => MemberStats(
    totalPoints: 0,
    level: 1,
    completedTotal: 0,
    onTimeTotal: 0,
    coversTotal: 0,
    verifiedCleanTotal: 0,
    streak: StreakState.empty,
    badges: const <String, BadgeEarned>{},
    monthly: const <String, MonthlyStats>{},
    processedThrough: null,
    lastCelebratedDateKey: null,
    startedOn: startedOn,
    sharing: false,
  );

  final int totalPoints;
  final int level;
  final int completedTotal;
  final int onTimeTotal;
  final int coversTotal;
  final int verifiedCleanTotal;
  final StreakState streak;
  final Map<String, BadgeEarned> badges;
  final Map<String, MonthlyStats> monthly;
  final DateKey? processedThrough;
  final DateKey? lastCelebratedDateKey;
  final DateKey startedOn;
  final bool sharing;

  MemberStats copyWith({
    int? totalPoints,
    int? level,
    int? completedTotal,
    int? onTimeTotal,
    int? coversTotal,
    int? verifiedCleanTotal,
    StreakState? streak,
    Map<String, BadgeEarned>? badges,
    Map<String, MonthlyStats>? monthly,
    Object? processedThrough = _unset,
    Object? lastCelebratedDateKey = _unset,
    DateKey? startedOn,
    bool? sharing,
  }) => MemberStats(
    totalPoints: totalPoints ?? this.totalPoints,
    level: level ?? this.level,
    completedTotal: completedTotal ?? this.completedTotal,
    onTimeTotal: onTimeTotal ?? this.onTimeTotal,
    coversTotal: coversTotal ?? this.coversTotal,
    verifiedCleanTotal: verifiedCleanTotal ?? this.verifiedCleanTotal,
    streak: streak ?? this.streak,
    badges: badges ?? this.badges,
    monthly: monthly ?? this.monthly,
    processedThrough: identical(processedThrough, _unset)
        ? this.processedThrough
        : processedThrough as DateKey?,
    lastCelebratedDateKey: identical(lastCelebratedDateKey, _unset)
        ? this.lastCelebratedDateKey
        : lastCelebratedDateKey as DateKey?,
    startedOn: startedOn ?? this.startedOn,
    sharing: sharing ?? this.sharing,
  );

  @override
  bool operator ==(Object other) =>
      other is MemberStats &&
      other.totalPoints == totalPoints &&
      other.level == level &&
      other.completedTotal == completedTotal &&
      other.onTimeTotal == onTimeTotal &&
      other.coversTotal == coversTotal &&
      other.verifiedCleanTotal == verifiedCleanTotal &&
      other.streak == streak &&
      _sameMap(other.badges, badges) &&
      _sameMap(other.monthly, monthly) &&
      other.processedThrough == processedThrough &&
      other.lastCelebratedDateKey == lastCelebratedDateKey &&
      other.startedOn == startedOn &&
      other.sharing == sharing;

  @override
  int get hashCode => Object.hash(
    totalPoints,
    level,
    completedTotal,
    onTimeTotal,
    coversTotal,
    verifiedCleanTotal,
    streak,
    Object.hashAllUnordered(
      badges.entries.map((entry) => Object.hash(entry.key, entry.value)),
    ),
    Object.hashAllUnordered(
      monthly.entries.map((entry) => Object.hash(entry.key, entry.value)),
    ),
    processedThrough,
    lastCelebratedDateKey,
    startedOn,
    sharing,
  );
}

bool _sameMap<K, V>(Map<K, V> first, Map<K, V> second) {
  if (first.length != second.length) return false;
  return first.entries.every((entry) => second[entry.key] == entry.value);
}

const Object _unset = Object();
