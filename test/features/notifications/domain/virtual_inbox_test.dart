import 'package:family_hub/features/notifications/domain/virtual_inbox.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime.utc(2026, 11, 12, 8);

  test('builds one stable local item for each active cause', () {
    final items = VirtualInbox.build(
      monthKey: '2026-11',
      viewerId: 'member-1',
      now: now,
      acknowledgedIds: const <String>{},
      budgetPercent: 85,
      pendingJoinRequests: 2,
      pendingContributionRequests: 3,
      contributionDue: true,
      awaitingVerification: 4,
    );

    expect(items.map((item) => item.id), <String>[
      'v:budget:2026-11',
      'v:join:2026-11',
      'v:contribution-requests:2026-11',
      'v:contribution-due:2026-11:member-1',
      'v:verification:2026-11',
    ]);
    expect(items.every((item) => item.isUnread), isTrue);
    expect(items.every((item) => item.id.startsWith('v:')), isTrue);
  });

  test('omits resolved causes and keeps local read state by stable id', () {
    final items = VirtualInbox.build(
      monthKey: '2026-11',
      viewerId: 'member-1',
      now: now,
      acknowledgedIds: const <String>{'v:budget:2026-11'},
      budgetPercent: 85,
    );
    final item = items.single;

    expect(item.id, 'v:budget:2026-11');
    expect(item.isUnread, isFalse);
    expect(
      VirtualInbox.build(
        monthKey: '2026-11',
        viewerId: 'member-1',
        now: now,
        acknowledgedIds: const <String>{},
      ),
      isEmpty,
    );
  });

  test('each cause is independently visible and disappears when cleared', () {
    final inputs =
        <
          ({
            int? budgetPercent,
            int pendingJoinRequests,
            int pendingContributionRequests,
            bool contributionDue,
            int awaitingVerification,
            String type,
          })
        >[
          (
            budgetPercent: 85,
            pendingJoinRequests: 0,
            pendingContributionRequests: 0,
            contributionDue: false,
            awaitingVerification: 0,
            type: VirtualInboxType.budgetAlert,
          ),
          (
            budgetPercent: null,
            pendingJoinRequests: 2,
            pendingContributionRequests: 0,
            contributionDue: false,
            awaitingVerification: 0,
            type: VirtualInboxType.pendingJoinRequests,
          ),
          (
            budgetPercent: null,
            pendingJoinRequests: 0,
            pendingContributionRequests: 3,
            contributionDue: false,
            awaitingVerification: 0,
            type: VirtualInboxType.pendingContributionRequests,
          ),
          (
            budgetPercent: null,
            pendingJoinRequests: 0,
            pendingContributionRequests: 0,
            contributionDue: true,
            awaitingVerification: 0,
            type: VirtualInboxType.contributionDue,
          ),
          (
            budgetPercent: null,
            pendingJoinRequests: 0,
            pendingContributionRequests: 0,
            contributionDue: false,
            awaitingVerification: 4,
            type: VirtualInboxType.awaitingVerification,
          ),
        ];

    for (final input in inputs) {
      final item = VirtualInbox.build(
        monthKey: '2026-11',
        viewerId: 'member-1',
        now: now,
        acknowledgedIds: const <String>{},
        budgetPercent: input.budgetPercent,
        pendingJoinRequests: input.pendingJoinRequests,
        pendingContributionRequests: input.pendingContributionRequests,
        contributionDue: input.contributionDue,
        awaitingVerification: input.awaitingVerification,
      ).single;
      expect(item.type, input.type);
      expect(
        VirtualInbox.build(
          monthKey: '2026-11',
          viewerId: 'member-1',
          now: now,
          acknowledgedIds: const <String>{},
        ),
        isEmpty,
      );
    }
  });
}
