/// One member's load over a range (P3-28).
///
/// Everything is a plain count so the screen can show a number next to every
/// bar (never a bar or a colour alone). [points] weigh a chore by difficulty
/// (easy 1, normal 2, hard 3); [share] is this member's part of all points.
final class MemberWorkload {
  const MemberWorkload({
    required this.memberId,
    this.assigned = 0,
    this.done = 0,
    this.points = 0,
    this.minutes = 0,
    this.coversGiven = 0,
    this.coversReceived = 0,
    this.unavailableDays = 0,
    this.share = 0,
  });

  final String memberId;

  /// Chores owned by the member in the range (skipped ones excluded).
  final int assigned;

  /// Of those, finished or verified.
  final int done;
  final int points;

  /// Estimated minutes, only where a chore has an estimate.
  final int minutes;

  /// Chores the member covers for somebody else.
  final int coversGiven;

  /// Chores planned for the member that somebody else does.
  final int coversReceived;

  /// Days of the range the member is away (active absences).
  final int unavailableDays;

  /// `points / total points` of the family, 0 when nobody has any.
  final double share;

  @override
  String toString() => 'MemberWorkload($memberId $assigned/$points)';
}

/// The family's workload over a range, one entry per member in the order given.
final class WorkloadSummary {
  const WorkloadSummary({required this.members, required this.totalPoints});

  static const WorkloadSummary empty = WorkloadSummary(
    members: <MemberWorkload>[],
    totalPoints: 0,
  );

  final List<MemberWorkload> members;
  final int totalPoints;

  MemberWorkload? of(String memberId) {
    for (final member in members) {
      if (member.memberId == memberId) return member;
    }
    return null;
  }
}
