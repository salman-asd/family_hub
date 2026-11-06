import 'package:family_hub/features/activity/domain/activity_entry.dart';

enum ActivityModuleFilter { all, bazar, chores, family, engagement }

/// Screen-local filters. The actor filter is also applied by Firestore; module
/// filtering remains client-side so it works across the pages already loaded.
final class ActivityFilter {
  const ActivityFilter({this.module = ActivityModuleFilter.all, this.actorId});

  final ActivityModuleFilter module;
  final String? actorId;

  List<ActivityEntry> apply(Iterable<ActivityEntry> entries) => <ActivityEntry>[
    for (final entry in entries)
      if (_matchesModule(entry)) entry,
  ];

  bool _matchesModule(ActivityEntry entry) => switch (module) {
    ActivityModuleFilter.all => true,
    ActivityModuleFilter.bazar => entry.type.startsWith('bazar.'),
    ActivityModuleFilter.chores => entry.type.startsWith('chores.'),
    ActivityModuleFilter.family => entry.type.startsWith('family.'),
    ActivityModuleFilter.engagement => entry.type.startsWith('engagement.'),
  };

  ActivityFilter copyWith({
    ActivityModuleFilter? module,
    String? actorId,
    bool clearActor = false,
  }) => ActivityFilter(
    module: module ?? this.module,
    actorId: clearActor ? null : actorId ?? this.actorId,
  );

  @override
  bool operator ==(Object other) =>
      other is ActivityFilter &&
      other.module == module &&
      other.actorId == actorId;

  @override
  int get hashCode => Object.hash(module, actorId);
}
