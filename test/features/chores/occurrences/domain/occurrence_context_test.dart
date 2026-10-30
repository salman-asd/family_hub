import 'package:family_hub/core/permissions/permission_settings.dart';
import 'package:family_hub/features/chores/occurrences/domain/usecases/occurrence_action.dart';
import 'package:family_hub/features/family/domain/member.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../chores_test_helpers.dart';

/// M-06: ONE definition of "the assignee" - `assigneeId` only.
///
/// The P3-13 rules (`mayTick`) and `CompleteOccurrence` already used it; this
/// context used to fall back to `plannedAssigneeId`, so a chore nobody owned
/// yet could be ticked by its planned owner in the UI and be refused by the
/// rules. An unassigned chore is somebody else's (road map 3.3).
void main() {
  OccurrenceContext contextFor({
    required String uid,
    String? assigneeId,
    String? plannedAssigneeId = 'cara',
    MemberRole role = MemberRole.member,
    PermissionSettings settings = PermissionSettings.defaults,
  }) => OccurrenceContext.build(
    occurrence: anOccurrence(
      assigneeId: assigneeId,
      plannedAssigneeId: plannedAssigneeId,
    ),
    member: aMember(uid: uid, role: role),
    settings: settings,
  );

  test('the assignee is the member named in assigneeId', () {
    final context = contextFor(uid: 'cara', assigneeId: 'cara');
    expect(context.actor.isAssignee, isTrue);
    expect(context.actor.mayTick, isTrue);
  });

  test('the PLANNED owner is not the assignee while assigneeId is null', () {
    final context = contextFor(uid: 'cara');
    expect(context.actor.isAssignee, isFalse);
    expect(context.actor.mayTick, isFalse);
  });

  test('a covering member is the assignee, the planned owner is not', () {
    final planned = contextFor(
      uid: 'cara',
      assigneeId: 'dave',
      plannedAssigneeId: 'cara',
    );
    final cover = contextFor(
      uid: 'dave',
      assigneeId: 'dave',
      plannedAssigneeId: 'cara',
    );
    expect(planned.actor.isAssignee, isFalse);
    expect(cover.actor.isAssignee, isTrue);
  });

  test('a manager may act on an unassigned chore', () {
    final context = contextFor(uid: 'bob', role: MemberRole.moderator);
    expect(context.actor.isAssignee, isFalse);
    expect(context.actor.isManager, isTrue);
    expect(context.actor.mayTick, isTrue);
  });

  test('the family switch lets a plain member act on an unassigned chore', () {
    final context = contextFor(
      uid: 'gina',
      settings: const PermissionSettings(membersCanCompleteForOthers: true),
    );
    expect(context.actor.isAssignee, isFalse);
    expect(context.actor.mayTick, isTrue);
  });

  test('a disabled chores module removes the manager role', () {
    final context = contextFor(
      uid: 'bob',
      role: MemberRole.moderator,
      settings: const PermissionSettings(choresEnabled: false),
    );
    expect(context.actor.isManager, isFalse);
  });

  test('the completer is flagged, so nobody verifies their own work', () {
    final context = OccurrenceContext.build(
      occurrence: anOccurrence(completedBy: 'bob'),
      member: aMember(uid: 'bob', role: MemberRole.moderator),
      settings: PermissionSettings.defaults,
    );
    expect(context.actor.isCompleter, isTrue);
  });
}
