import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/features/chores/availability/domain/member_availability.dart';
import 'package:family_hub/features/chores/availability/domain/usecases/add_availability.dart';
import 'package:family_hub/features/chores/availability/domain/usecases/apply_absence_policy.dart';
import 'package:family_hub/features/chores/availability/domain/usecases/cancel_availability.dart';
import 'package:family_hub/features/chores/availability/domain/usecases/decide_availability.dart';
import 'package:family_hub/features/chores/comments/domain/comment_loader.dart';
import 'package:family_hub/features/chores/occurrences/domain/chore_occurrence.dart';
import 'package:family_hub/features/chores/occurrences/domain/occurrence_status.dart';
import 'package:family_hub/features/chores/settings/domain/chore_settings.dart';
import 'package:family_hub/features/chores/swaps/domain/usecases/accept_swap.dart';
import 'package:family_hub/features/chores/swaps/domain/usecases/cancel_swap.dart';
import 'package:family_hub/features/chores/swaps/domain/usecases/decline_swap.dart';
import 'package:family_hub/features/chores/swaps/domain/usecases/expire_swaps.dart';
import 'package:family_hub/features/chores/swaps/domain/usecases/request_swap.dart';

import '../chores_test_helpers.dart';
import '../occurrences/domain/usecases/completion_test_support.dart';

/// The P3-26 use cases wired over the in-memory fakes of one [ChoresFixture].
///
/// `cara` owns `tpl_1_20261024` (due 17:00 UTC, the fixture clock is 09:00 UTC),
/// `dave` is the ordinary recipient, `alice` and `bob` are managers.
class SwapKit {
  SwapKit() : fixture = ChoresFixture() {
    final f = fixture;
    inbox = RecordingInboxPort();
    loader = CommentLoader(
      occurrences: f.occurrences,
      templates: f.chores,
      dutyGroups: f.chores.dutyGroups,
      choreSettings: f.settings,
      families: f.families,
      dateKeys: f.dateKeys,
    );
    request = RequestSwap(
      loader: loader,
      swaps: f.swaps,
      availability: f.availability,
      clock: f.clock,
      inbox: inbox,
      newId: f.ids.call,
    );
    accept = AcceptSwap(
      loader: loader,
      swaps: f.swaps,
      availability: f.availability,
      clock: f.clock,
      inbox: inbox,
      newId: f.ids.call,
    );
    decline = DeclineSwap(
      families: f.families,
      swaps: f.swaps,
      availability: f.availability,
      occurrences: f.occurrences,
      choreSettings: f.settings,
      clock: f.clock,
      inbox: inbox,
    );
    cancel = CancelSwap(
      families: f.families,
      swaps: f.swaps,
      occurrences: f.occurrences,
      clock: f.clock,
      inbox: inbox,
    );
    expire = ExpireSwaps(
      families: f.families,
      swaps: f.swaps,
      availability: f.availability,
      occurrences: f.occurrences,
      choreSettings: f.settings,
      clock: f.clock,
      inbox: inbox,
    );
    addAvailability = AddAvailability(
      families: f.families,
      choreSettings: f.settings,
      availability: f.availability,
      clock: f.clock,
      newId: f.ids.call,
    );
    cancelAvailability = CancelAvailability(
      families: f.families,
      availability: f.availability,
      clock: f.clock,
      newId: f.ids.call,
    );
    decideAvailability = DecideAvailability(
      families: f.families,
      availability: f.availability,
      clock: f.clock,
      inbox: inbox,
      newId: f.ids.call,
    );
    applyPolicy = ApplyAbsencePolicy(
      families: f.families,
      choreSettings: f.settings,
      availability: f.availability,
      occurrences: f.occurrences,
      swaps: f.swaps,
      clock: f.clock,
      inbox: inbox,
    );
    seedChore();
  }

  static const String familyId = ChoresFixture.familyId;
  static const String occId = 'tpl_1_20261024';

  final ChoresFixture fixture;
  late final RecordingInboxPort inbox;
  late final CommentLoader loader;
  late final RequestSwap request;
  late final AcceptSwap accept;
  late final DeclineSwap decline;
  late final CancelSwap cancel;
  late final ExpireSwaps expire;
  late final AddAvailability addAvailability;
  late final CancelAvailability cancelAvailability;
  late final DecideAvailability decideAvailability;
  late final ApplyAbsencePolicy applyPolicy;

  /// One unstarted chore of `cara` on [day] (default the 24th).
  ChoreOccurrence seedChore({
    String id = occId,
    int day = 24,
    String assignee = 'cara',
    bool started = false,
  }) => seedOccurrence(
    fixture,
    anOccurrence(
      id: id,
      dateKey: DateKey(2026, 10, day),
      dueAt: DateTime.utc(2026, 10, day, 17),
      assigneeId: assignee,
      plannedAssigneeId: assignee,
      status: started ? OccurrenceStatus.inProgress : OccurrenceStatus.scheduled,
    ),
  );

  ChoreOccurrence stored([String id = occId]) =>
      fixture.occurrences.occurrences[familyId]![id]!;

  /// An absence record in the fake store.
  void seedAbsence(
    String id,
    String member, {
    int from = 24,
    int to = 26,
    AvailabilityStatus status = AvailabilityStatus.active,
  }) {
    fixture.swapWorld.absences[id] = MemberAvailability(
      id: id,
      memberId: member,
      startDate: DateKey(2026, 10, from),
      endDate: DateKey(2026, 10, to),
      typeId: ChoreSettings.defaults.absenceReasons.first.id,
      reason: 'Fever',
      status: status,
      createdBy: member,
    );
  }
}
