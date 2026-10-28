import 'package:family_hub/core/utils/date_key.dart';

import 'package:family_hub/features/chores/templates/domain/template_enums.dart';

/// A calendar-based rotation: one version per change, effective from a date
/// (D-P3-11). The ENGINE lives in P3-09; this is only the stored shape, because
/// a template may carry its own rotation.
final class Rotation {
  const Rotation({required this.versions});

  final List<RotationVersion> versions;

  Map<String, Object?> toMap() => <String, Object?>{
    'versions': <Map<String, Object?>>[
      for (final version in versions) version.toMap(),
    ],
  };

  @override
  bool operator ==(Object other) {
    if (other is! Rotation || other.versions.length != versions.length) {
      return false;
    }
    for (var i = 0; i < versions.length; i++) {
      if (other.versions[i] != versions[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(versions);

  @override
  String toString() => 'Rotation(${versions.length} versions)';
}

/// One rotation version. [weekStartDay] is SNAPSHOTTED so a later change of the
/// family's week-start setting can never move somebody's turn (C-18).
final class RotationVersion {
  const RotationVersion({
    required this.from,
    required this.members,
    required this.anchorDate,
    required this.anchorIndex,
    required this.cycleUnit,
    required this.weekStartDay,
  });

  final DateKey from;
  final List<String> members;
  final DateKey anchorDate;
  final int anchorIndex;
  final CycleUnit cycleUnit;
  final int weekStartDay;

  Map<String, Object?> toMap() => <String, Object?>{
    'from': from.toString(),
    'members': members,
    'anchorDate': anchorDate.toString(),
    'anchorIndex': anchorIndex,
    'cycleUnit': cycleUnit.id,
    'weekStartDay': weekStartDay,
  };

  @override
  bool operator ==(Object other) {
    if (other is! RotationVersion ||
        other.from != from ||
        other.anchorDate != anchorDate ||
        other.anchorIndex != anchorIndex ||
        other.cycleUnit != cycleUnit ||
        other.weekStartDay != weekStartDay ||
        other.members.length != members.length) {
      return false;
    }
    for (var i = 0; i < members.length; i++) {
      if (other.members[i] != members[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
    from,
    anchorDate,
    anchorIndex,
    cycleUnit,
    weekStartDay,
    Object.hashAll(members),
  );

  @override
  String toString() =>
      'RotationVersion(from $from, ${members.length} members, '
      '${cycleUnit.id} from $anchorDate)';
}
