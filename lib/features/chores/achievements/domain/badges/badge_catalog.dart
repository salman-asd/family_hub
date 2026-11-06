final class BadgeThresholds {
  const BadgeThresholds({
    required this.consistentDays,
    required this.reliablePercent,
    required this.reliableMinDone,
    required this.helperCovers,
    required this.detailCount,
  }) : assert(consistentDays > 0),
       assert(reliablePercent >= 0 && reliablePercent <= 100),
       assert(reliableMinDone > 0),
       assert(helperCovers > 0),
       assert(detailCount > 0);

  final int consistentDays;
  final int reliablePercent;
  final int reliableMinDone;
  final int helperCovers;
  final int detailCount;

  BadgeThresholds copyWith({
    int? consistentDays,
    int? reliablePercent,
    int? reliableMinDone,
    int? helperCovers,
    int? detailCount,
  }) => BadgeThresholds(
    consistentDays: consistentDays ?? this.consistentDays,
    reliablePercent: reliablePercent ?? this.reliablePercent,
    reliableMinDone: reliableMinDone ?? this.reliableMinDone,
    helperCovers: helperCovers ?? this.helperCovers,
    detailCount: detailCount ?? this.detailCount,
  );

  @override
  bool operator ==(Object other) =>
      other is BadgeThresholds &&
      other.consistentDays == consistentDays &&
      other.reliablePercent == reliablePercent &&
      other.reliableMinDone == reliableMinDone &&
      other.helperCovers == helperCovers &&
      other.detailCount == detailCount;

  @override
  int get hashCode => Object.hash(
    consistentDays,
    reliablePercent,
    reliableMinDone,
    helperCovers,
    detailCount,
  );
}

abstract final class BadgeCatalog {
  static const String freshStart = 'fresh_start';
  static const String consistent = 'consistent';
  static const String reliable = 'reliable';
  static const String helper = 'helper';
  static const String detailChampion = 'detail_champion';

  static const List<String> ids = <String>[
    freshStart,
    consistent,
    reliable,
    helper,
    detailChampion,
  ];
}
