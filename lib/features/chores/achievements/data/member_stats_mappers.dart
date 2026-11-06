import 'package:family_hub/core/firebase/base_mapper.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/features/chores/achievements/domain/member_stats.dart';
import 'package:family_hub/features/chores/achievements/domain/scoring/streak_calculator.dart';

abstract final class MemberStatsMappers {
  static Map<String, dynamic> toMap(
    MemberStats stats,
    BaseDocumentMetadata metadata,
  ) => <String, dynamic>{
    'totalPoints': stats.totalPoints,
    'level': stats.level,
    'completedTotal': stats.completedTotal,
    'onTimeTotal': stats.onTimeTotal,
    'coversTotal': stats.coversTotal,
    'verifiedCleanTotal': stats.verifiedCleanTotal,
    'streak': <String, Object?>{
      'current': stats.streak.current,
      'best': stats.streak.best,
      'asOfDateKey': stats.streak.asOfDateKey?.toString(),
      'pausedDays': stats.streak.pausedDays,
    },
    'badges': <String, Object?>{
      for (final entry in stats.badges.entries)
        entry.key: <String, Object?>{
          'earnedAt': entry.value.earnedAt.toString(),
          if (entry.value.monthKey case final month?)
            'monthKey': month.toString(),
        },
    },
    'monthly': <String, Object?>{
      for (final entry in stats.monthly.entries)
        entry.key: <String, Object?>{
          'points': entry.value.points,
          'done': entry.value.done,
          'onTime': entry.value.onTime,
          'covers': entry.value.covers,
          'verifiedClean': entry.value.verifiedClean,
          'final': entry.value.isFinal,
          'specVersion': entry.value.specVersion,
        },
    },
    'processedThrough': stats.processedThrough?.toString(),
    'lastCelebratedDateKey': stats.lastCelebratedDateKey?.toString(),
    'startedOn': stats.startedOn.toString(),
    'sharing': stats.sharing,
    ...BaseMapper.metadataToMap(metadata),
  };

  static MemberStats fromMap(
    Map<String, dynamic>? map, {
    required DateKey defaultStartedOn,
  }) {
    if (map == null) return MemberStats.empty(startedOn: defaultStartedOn);
    final streak = _map(map['streak']);
    final rawBadges = _map(map['badges']);
    final rawMonthly = _map(map['monthly']);
    final badges = <String, BadgeEarned>{};
    for (final entry in rawBadges.entries) {
      final badge = _map(entry.value);
      final earnedAt = _date(badge['earnedAt']);
      if (earnedAt == null) continue;
      badges[entry.key] = BadgeEarned(
        earnedAt: earnedAt,
        monthKey: _month(badge['monthKey']),
      );
    }
    return MemberStats(
      totalPoints: _int(map['totalPoints']),
      level: _int(map['level'], fallback: 1),
      completedTotal: _int(map['completedTotal']),
      onTimeTotal: _int(map['onTimeTotal']),
      coversTotal: _int(map['coversTotal']),
      verifiedCleanTotal: _int(map['verifiedCleanTotal']),
      streak: StreakState(
        current: _int(streak['current']),
        best: _int(streak['best']),
        pausedDays: _int(streak['pausedDays']),
        asOfDateKey: _date(streak['asOfDateKey']),
      ),
      badges: badges,
      monthly: <String, MonthlyStats>{
        for (final entry in rawMonthly.entries)
          if (_month(entry.key) != null)
            entry.key: MonthlyStats(
              points: _int(_map(entry.value)['points']),
              done: _int(_map(entry.value)['done']),
              onTime: _int(_map(entry.value)['onTime']),
              covers: _int(_map(entry.value)['covers']),
              verifiedClean: _int(_map(entry.value)['verifiedClean']),
              isFinal: _map(entry.value)['final'] == true,
              specVersion: _int(_map(entry.value)['specVersion'], fallback: 1),
            ),
      },
      processedThrough: _date(map['processedThrough']),
      lastCelebratedDateKey: _date(map['lastCelebratedDateKey']),
      startedOn: _date(map['startedOn']) ?? defaultStartedOn,
      sharing: map['sharing'] == true,
    );
  }

  static Map<String, dynamic> _map(Object? value) =>
      value is Map<String, dynamic> ? value : const <String, dynamic>{};

  static int _int(Object? value, {int fallback = 0}) =>
      value is int && value >= 0 ? value : fallback;

  static DateKey? _date(Object? value) {
    if (value is! String) return null;
    return DateKey.parse(value).valueOrNull;
  }

  static MonthKey? _month(Object? value) {
    if (value is! String) return null;
    return MonthKey.parse(value).valueOrNull;
  }
}
