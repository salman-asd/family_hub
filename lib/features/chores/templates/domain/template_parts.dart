import 'package:family_hub/features/chores/templates/domain/template_enums.dart';

export 'package:family_hub/features/chores/templates/domain/template_enums.dart';
export 'package:family_hub/features/chores/templates/domain/template_rotation.dart';

/// One time of day a chore can be due at (a template may run several times a
/// day: the family's "৩ বেলা" chores).
final class TemplateSlot {
  const TemplateSlot({
    required this.key,
    this.labelBn,
    this.labelEn,
    this.dueMinutes,
  });

  /// `main` or `[a-z0-9]{1,12}`; part of the occurrence id (D-P3-3).
  final String key;
  final String? labelBn;
  final String? labelEn;

  /// Wall-clock minutes after midnight; null means "end of day".
  final int? dueMinutes;

  bool get isMain => key == TemplateLimits.mainSlotKey;

  TemplateSlot copyWith({
    String? key,
    String? labelBn,
    String? labelEn,
    int? dueMinutes,
    bool clearDueMinutes = false,
  }) => TemplateSlot(
    key: key ?? this.key,
    labelBn: labelBn ?? this.labelBn,
    labelEn: labelEn ?? this.labelEn,
    dueMinutes: clearDueMinutes ? null : (dueMinutes ?? this.dueMinutes),
  );

  Map<String, Object?> toMap() => <String, Object?>{
    'key': key,
    'labelBn': labelBn,
    'labelEn': labelEn,
    'dueMinutes': dueMinutes,
  };

  @override
  bool operator ==(Object other) =>
      other is TemplateSlot &&
      other.key == key &&
      other.labelBn == labelBn &&
      other.labelEn == labelEn &&
      other.dueMinutes == dueMinutes;

  @override
  int get hashCode => Object.hash(key, labelBn, labelEn, dueMinutes);

  @override
  String toString() => 'TemplateSlot($key, $dueMinutes)';
}

/// One tickable step of a chore. The id is stable: `subtaskDone` on an
/// occurrence is keyed by it.
final class TemplateSubtask {
  const TemplateSubtask({
    required this.id,
    required this.title,
    this.required = false,
    this.hint,
  });

  /// `[a-z0-9_]{1,16}`.
  final String id;
  final String title;

  /// A required step must be ticked before the chore can be completed.
  final bool required;
  final String? hint;

  TemplateSubtask copyWith({String? title, bool? required, String? hint}) =>
      TemplateSubtask(
        id: id,
        title: title ?? this.title,
        required: required ?? this.required,
        hint: hint ?? this.hint,
      );

  Map<String, Object?> toMap() => <String, Object?>{
    'id': id,
    'title': title,
    'required': required,
    'hint': hint,
  };

  @override
  bool operator ==(Object other) =>
      other is TemplateSubtask &&
      other.id == id &&
      other.title == title &&
      other.required == required &&
      other.hint == hint;

  @override
  int get hashCode => Object.hash(id, title, required, hint);

  @override
  String toString() => 'TemplateSubtask($id, $title)';
}

/// Who does the chore.
///
/// * [AssigneeStrategy.rotation] - a duty group, or the template's OWN
///   rotation when it does not belong to a group;
/// * [AssigneeStrategy.fixed] - always the same member;
/// * [AssigneeStrategy.manual] - nobody until a manager assigns it.
final class AssigneeSpec {
  const AssigneeSpec({
    required this.strategy,
    this.fixedMemberId,
    this.dutyGroupId,
    this.rotation,
  });

  static const AssigneeSpec manual = AssigneeSpec(
    strategy: AssigneeStrategy.manual,
  );

  final AssigneeStrategy strategy;
  final String? fixedMemberId;

  /// The group whose rotation decides the owner (single source of truth: the
  /// group stores no template list).
  final String? dutyGroupId;

  /// The template's own rotation; used only when [dutyGroupId] is null.
  final Rotation? rotation;

  AssigneeSpec copyWith({
    AssigneeStrategy? strategy,
    String? fixedMemberId,
    String? dutyGroupId,
    Rotation? rotation,
    bool clearFixedMember = false,
    bool clearDutyGroup = false,
    bool clearRotation = false,
  }) => AssigneeSpec(
    strategy: strategy ?? this.strategy,
    fixedMemberId: clearFixedMember
        ? null
        : (fixedMemberId ?? this.fixedMemberId),
    dutyGroupId: clearDutyGroup ? null : (dutyGroupId ?? this.dutyGroupId),
    rotation: clearRotation ? null : (rotation ?? this.rotation),
  );

  Map<String, Object?> toMap() => <String, Object?>{
    'strategy': strategy.id,
    'fixedMemberId': fixedMemberId,
    'dutyGroupId': dutyGroupId,
    'rotation': rotation?.toMap(),
  };

  @override
  bool operator ==(Object other) =>
      other is AssigneeSpec &&
      other.strategy == strategy &&
      other.fixedMemberId == fixedMemberId &&
      other.dutyGroupId == dutyGroupId &&
      other.rotation == rotation;

  @override
  int get hashCode =>
      Object.hash(strategy, fixedMemberId, dutyGroupId, rotation);

  @override
  String toString() =>
      'AssigneeSpec(${strategy.id}, fixed: $fixedMemberId, '
      'group: $dutyGroupId, ownRotation: ${rotation != null})';
}

/// Reminder configuration. STORED in Phase 3, consumed in Phase 4.
final class ReminderConfig {
  const ReminderConfig({
    this.enabled = false,
    this.atDue = true,
    this.offsetsMinutes = const <int>[],
    this.overdueEnabled = false,
    this.overdueAfterMinutes = 60,
  });

  static const ReminderConfig off = ReminderConfig();

  final bool enabled;
  final bool atDue;

  /// Minutes before the due time (1 … 1440), at most five.
  final List<int> offsetsMinutes;
  final bool overdueEnabled;
  final int overdueAfterMinutes;

  ReminderConfig copyWith({
    bool? enabled,
    bool? atDue,
    List<int>? offsetsMinutes,
    bool? overdueEnabled,
    int? overdueAfterMinutes,
  }) => ReminderConfig(
    enabled: enabled ?? this.enabled,
    atDue: atDue ?? this.atDue,
    offsetsMinutes: offsetsMinutes ?? this.offsetsMinutes,
    overdueEnabled: overdueEnabled ?? this.overdueEnabled,
    overdueAfterMinutes: overdueAfterMinutes ?? this.overdueAfterMinutes,
  );

  Map<String, Object?> toMap() => <String, Object?>{
    'enabled': enabled,
    'atDue': atDue,
    'offsetsMinutes': offsetsMinutes,
    'overdueEnabled': overdueEnabled,
    'overdueAfterMinutes': overdueAfterMinutes,
  };

  @override
  bool operator ==(Object other) {
    if (other is! ReminderConfig ||
        other.enabled != enabled ||
        other.atDue != atDue ||
        other.overdueEnabled != overdueEnabled ||
        other.overdueAfterMinutes != overdueAfterMinutes ||
        other.offsetsMinutes.length != offsetsMinutes.length) {
      return false;
    }
    for (var i = 0; i < offsetsMinutes.length; i++) {
      if (other.offsetsMinutes[i] != offsetsMinutes[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
    enabled,
    atDue,
    overdueEnabled,
    overdueAfterMinutes,
    Object.hashAll(offsetsMinutes),
  );

  @override
  String toString() => 'ReminderConfig(enabled: $enabled, atDue: $atDue)';
}
