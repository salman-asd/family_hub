import 'package:family_hub/core/audit/audit_event.dart';
import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/core/permissions/permissions.dart';
import 'package:family_hub/core/utils/clock.dart';
import 'package:family_hub/features/chores/settings/domain/chore_settings.dart';
import 'package:family_hub/features/chores/settings/domain/chore_settings_repository.dart';
import 'package:family_hub/features/family/domain/family.dart';
import 'package:family_hub/features/family/domain/member.dart';
import 'package:family_hub/features/family/domain/member_role.dart';
import 'package:family_hub/features/family/domain/membership.dart';
import 'package:family_hub/features/family/domain/family_repository.dart';

import '../../support/in_memory_backend.dart';
import '../../support/in_memory_chores_backend.dart';

import 'package:family_hub/features/chores/templates/domain/chore_template.dart';
import 'package:family_hub/features/chores/templates/domain/recurrence/recurrence.dart';
import 'package:family_hub/features/chores/templates/domain/template_parts.dart';
import 'package:family_hub/core/utils/date_key.dart';

/// Deterministic ids: `id_1`, `id_2`, …
class SeqIds {
  int _next = 0;

  String call() => 'id_${++_next}';
}

/// The chores test family of road map 3.11: admin `alice`, Household Manager
/// `bob`, members `cara` and `dave`, pending `erin`.
///
/// The in-memory [InMemoryBackend] is the family port (it already implements
/// `FamilyRepository`); [FakeChoreSettingsRepository] is the settings port.
/// Later steps extend this file rather than starting a second fixture.
class ChoresFixture {
  ChoresFixture()
    : backend = InMemoryBackend(),
      clock = FakeClock(DateTime.utc(2026, 10, 24, 9)),
      ids = SeqIds() {
    _seedFamily();
  }

  static const String familyId = 'f1';

  final InMemoryBackend backend;
  final FakeClock clock;
  final SeqIds ids;
  final FakeChoreSettingsRepository settings = FakeChoreSettingsRepository();
  final InMemoryChoresBackend chores = InMemoryChoresBackend();

  void _seedFamily() {
    backend.families[familyId] = const Family(
      id: familyId,
      name: 'Chores family',
    );
    backend.members[familyId] = <String, Member>{
      'alice': _member('alice', MemberRole.admin, MembershipStatus.active),
      'bob': _member('bob', MemberRole.moderator, MembershipStatus.active),
      'cara': _member('cara', MemberRole.member, MembershipStatus.active),
      'dave': _member('dave', MemberRole.member, MembershipStatus.active),
      'erin': _member('erin', MemberRole.member, MembershipStatus.pending),
    };
    backend.adminIds[familyId] = <String>['alice'];
    backend.permissionSettings[familyId] = PermissionSettings.defaults;
    for (final uid in <String>['alice', 'bob', 'cara', 'dave', 'erin']) {
      backend.userFamily[uid] = familyId;
    }
  }

  static Member _member(String uid, MemberRole role, MembershipStatus status) =>
      Member(
        uid: uid,
        role: role,
        status: status,
        fullName: 'Person $uid',
        relationship: 'other',
      );

  /// The family port the use cases ask for permissions through.
  FamilyRepository get families => backend;
}

/// A valid draft: daily "wash the dishes", manual assignment, one main slot.
/// Tests override only what they are about.
TemplateDraft aTemplate({
  String nameBn = 'বাসন ধোয়া',
  String? nameEn = 'Wash the dishes',
  String? groupId = 'kitchen',
  Recurrence? recurrence,
  List<TemplateSlot>? slots,
  AssigneeSpec? assignee,
  String instructions = '',
  List<TemplateSubtask>? subtasks,
  int? estimatedMinutes,
  Difficulty difficulty = Difficulty.normal,
  VerificationMode verification = VerificationMode.off,
  ReminderConfig? reminders,
  DateKey? startDate,
  DateKey? endDate,
  int? colorIndex,
  String? iconKey,
}) => TemplateDraft(
  nameBn: nameBn,
  nameEn: nameEn,
  groupId: groupId,
  recurrence: recurrence ?? const DailyRecurrence(),
  slots: slots ?? <TemplateSlot>[aSlot()],
  assignee: assignee ?? AssigneeSpec.manual,
  instructions: instructions,
  subtasks: subtasks ?? const <TemplateSubtask>[],
  estimatedMinutes: estimatedMinutes,
  difficulty: difficulty,
  verification: verification,
  reminders: reminders ?? ReminderConfig.off,
  startDate: startDate ?? DateKey(2026, 10, 1),
  endDate: endDate,
  colorIndex: colorIndex,
  iconKey: iconKey,
);

/// The main slot: due at 09:00 by default.
TemplateSlot aSlot({
  String key = TemplateLimits.mainSlotKey,
  String? labelBn,
  String? labelEn,
  int? dueMinutes = 540,
}) => TemplateSlot(
  key: key,
  labelBn: labelBn,
  labelEn: labelEn,
  dueMinutes: dueMinutes,
);

/// A subtask with a stable id.
TemplateSubtask aSubtask({
  String id = 'step_1',
  String title = 'প্লেট ধোয়া',
  bool required = false,
  String? hint,
}) => TemplateSubtask(id: id, title: title, required: required, hint: hint);

/// In-memory [ChoreSettingsRepository] for use-case tests.
class FakeChoreSettingsRepository implements ChoreSettingsRepository {
  FakeChoreSettingsRepository({
    this.settings = ChoreSettings.defaults,
    this.policy = AbsencePolicy.askCover,
  });

  ChoreSettings settings;
  AbsencePolicy policy;
  int saves = 0;
  int policySaves = 0;
  AppFailure? nextFailure;
  final List<AuditEvent> events = <AuditEvent>[];

  @override
  Stream<ChoreSettings> watch(String familyId) => Stream.value(settings);

  @override
  Future<Result<ChoreSettings>> get(String familyId) async =>
      Success<ChoreSettings>(settings);

  @override
  Future<Result<void>> save(
    String familyId,
    ChoreSettings value,
    AuditEvent event,
  ) async {
    saves++;
    final failure = nextFailure;
    if (failure != null) {
      nextFailure = null;
      return Failure<void>(failure);
    }
    settings = value;
    events.add(event);
    return const Success<void>(null);
  }

  @override
  Stream<AbsencePolicy> watchAbsencePolicy(String familyId) =>
      Stream.value(policy);

  @override
  Future<Result<AbsencePolicy>> getAbsencePolicy(String familyId) async =>
      Success<AbsencePolicy>(policy);

  @override
  Future<Result<void>> saveAbsencePolicy(
    String familyId,
    AbsencePolicy value,
    AuditEvent event,
  ) async {
    policySaves++;
    final failure = nextFailure;
    if (failure != null) {
      nextFailure = null;
      return Failure<void>(failure);
    }
    policy = value;
    events.add(event);
    return const Success<void>(null);
  }
}
