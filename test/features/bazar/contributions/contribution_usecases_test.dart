import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/core/utils/money.dart';
import 'package:family_hub/features/bazar/contributions/domain/contribution.dart';
import 'package:family_hub/features/bazar/contributions/domain/contribution_status.dart';
import 'package:family_hub/features/bazar/fund/domain/fund_transaction.dart';
import 'package:family_hub/features/bazar/settings/domain/bazar_settings.dart';
import 'package:flutter_test/flutter_test.dart';

import 'contribution_test_helpers.dart';

const String _f = ContributionFixture.familyId;

void main() {
  late ContributionFixture t;

  setUp(() => t = ContributionFixture());

  Future<Contribution> recorded(
    String member,
    int paisa, {
    DateKey? date,
  }) async {
    final result = await t.record(
      actorUid: 'alice',
      familyId: _f,
      memberId: member,
      amount: Money.paisa(paisa),
      date: date ?? t.today,
    );
    return result.valueOrNull!;
  }

  Future<Contribution> requested(String member, int paisa) async {
    final result = await t.request(
      actorUid: member,
      familyId: _f,
      memberId: member,
      amount: Money.paisa(paisa),
      date: t.today,
    );
    return result.valueOrNull!;
  }

  group('RecordContribution (manager path)', () {
    test('writes an approved row, its con_ ledger row and one log entry', () async {
      final c = await recorded('cara', 100000);
      expect(c.status, ContributionApproval.approved);
      expect(c.fundTxId, 'con_${c.id}');
      expect(t.balance.paisa, 100000);
      final row = t.fx.backend.fundTransactionsOf(_f).single;
      expect(row.type, FundTxType.contribution);
      expect(row.refId, c.id);
      expect(t.repo.events, hasLength(1));
    });

    test('a moderator may record, a member may not', () async {
      final ok = await t.record(
        actorUid: 'bob',
        familyId: _f,
        memberId: 'cara',
        amount: const Money.paisa(500),
        date: t.today,
      );
      expect(ok.isSuccess, isTrue);
      final denied = await t.record(
        actorUid: 'cara',
        familyId: _f,
        memberId: 'cara',
        amount: const Money.paisa(500),
        date: t.today,
      );
      expect(denied.failureOrNull, isA<PermissionDenied>());
    });

    test('rejects zero, future dates, pending members and locked months', () async {
      Future<AppFailure?> go(int paisa, DateKey date, [String member = 'cara']) async =>
          (await t.record(
            actorUid: 'alice',
            familyId: _f,
            memberId: member,
            amount: Money.paisa(paisa),
            date: date,
          )).failureOrNull;

      expect(await go(0, t.today), const Validation('amount', 'amount_not_positive'));
      expect(
        await go(1, DateKey(2026, 10, 19)),
        const Validation('dateKey', 'future_date'),
      );
      expect(
        await go(1, t.today, 'dave'),
        const Validation('memberId', 'member_required'),
      );
      t.close(MonthKey(2026, 10));
      expect(await go(1, t.today), const Conflict(code: 'month_locked'));
      expect(t.repo.writes, 0);
    });

    test('a retry with the same ids is the same document and log entry', () async {
      for (var i = 0; i < 2; i++) {
        t.repo.contributions.clear();
        t.fx.backend.fundTransactions.clear();
        await t.record(
          actorUid: 'alice',
          familyId: _f,
          memberId: 'cara',
          amount: const Money.paisa(100),
          date: t.today,
          id: 'c1',
          eventId: 'e1',
        );
      }
      expect(t.repo.contributions.keys, <String>['c1']);
      expect(t.repo.events.map((e) => e.id).toSet(), <String>{'e1'});
    });
  });

  group('RequestContribution (member path)', () {
    test('writes pending and NO ledger row', () async {
      final c = await requested('cara', 70000);
      expect(c.status, ContributionApproval.pending);
      expect(c.fundTxId, isNull);
      expect(t.fx.backend.fundTransactionsOf(_f), isEmpty);
      expect(t.balance, Money.zero);
    });

    test('only for oneself', () async {
      final r = await t.request(
        actorUid: 'cara',
        familyId: _f,
        memberId: 'bob',
        amount: const Money.paisa(1),
        date: t.today,
      );
      expect(r.failureOrNull, isA<PermissionDenied>());
    });

    test('a pending member cannot request', () async {
      final r = await t.request(
        actorUid: 'dave',
        familyId: _f,
        memberId: 'dave',
        amount: const Money.paisa(1),
        date: t.today,
      );
      expect(r.failureOrNull, isA<PermissionDenied>());
    });
  });

  group('edit / cancel a pending request', () {
    test('the owner edits it; it stays pending', () async {
      final c = await requested('cara', 100);
      final r = await t.edit(
        actorUid: 'cara',
        familyId: _f,
        contributionId: c.id,
        amount: const Money.paisa(250),
        date: t.today,
        method: ContributionMethod.nagad,
      );
      expect(r.valueOrNull!.amount.paisa, 250);
      expect(t.repo.contributions[c.id]!.isPending, isTrue);
      expect(t.repo.contributions[c.id]!.method, ContributionMethod.nagad);
    });

    test('somebody else cannot edit or cancel it', () async {
      final c = await requested('cara', 100);
      final edit = await t.edit(
        actorUid: 'bob',
        familyId: _f,
        contributionId: c.id,
        amount: const Money.paisa(1),
        date: t.today,
      );
      expect(edit.failureOrNull, isA<PermissionDenied>());
      final cancel = await t.cancel(
        actorUid: 'bob',
        familyId: _f,
        contributionId: c.id,
      );
      expect(cancel.failureOrNull, isA<PermissionDenied>());
    });

    test('cancel is a soft void with no ledger row', () async {
      final c = await requested('cara', 100);
      final r = await t.cancel(actorUid: 'cara', familyId: _f, contributionId: c.id);
      expect(r.isSuccess, isTrue);
      expect(t.repo.contributions[c.id]!.isVoided, isTrue);
      expect(t.fx.backend.fundTransactionsOf(_f), isEmpty);
    });

    test('an approved or decided request is not editable', () async {
      final c = await requested('cara', 100);
      await t.approve(actorUid: 'alice', familyId: _f, contributionId: c.id);
      final r = await t.edit(
        actorUid: 'cara',
        familyId: _f,
        contributionId: c.id,
        amount: const Money.paisa(1),
        date: t.today,
      );
      expect(r.failureOrNull, const Conflict(code: 'contribution_not_pending'));
    });
  });

  group('approve / reject', () {
    test('approve writes the con_ row exactly once; a second approve conflicts', () async {
      final c = await requested('cara', 100000);
      final first = await t.approve(
        actorUid: 'bob',
        familyId: _f,
        contributionId: c.id,
      );
      expect(first.valueOrNull!.status, ContributionApproval.approved);
      expect(t.balance.paisa, 100000);
      final second = await t.approve(
        actorUid: 'alice',
        familyId: _f,
        contributionId: c.id,
      );
      expect(second.failureOrNull, const Conflict(code: 'contribution_not_pending'));
      expect(t.fx.backend.fundTransactionsOf(_f), hasLength(1));
      expect(t.repo.freshReads, everyElement(isTrue));
    });

    test('a member cannot approve, not even their own request', () async {
      final c = await requested('cara', 100);
      final r = await t.approve(
        actorUid: 'cara',
        familyId: _f,
        contributionId: c.id,
      );
      expect(r.failureOrNull, isA<PermissionDenied>());
      expect(t.balance, Money.zero);
    });

    test('approve is denied for a moderator when finance is switched off', () async {
      t.fx.backend.permissionSettings[_f] = t.fx.backend.permissionSettings[_f]!
          .copyWith(moderatorManagesFinance: false);
      final c = await requested('cara', 100);
      final r = await t.approve(actorUid: 'bob', familyId: _f, contributionId: c.id);
      expect(r.failureOrNull, isA<PermissionDenied>());
    });

    test('approve in a locked month is refused', () async {
      final c = await requested('cara', 100);
      t.close(MonthKey(2026, 10));
      final r = await t.approve(actorUid: 'alice', familyId: _f, contributionId: c.id);
      expect(r.failureOrNull, const Conflict(code: 'month_locked'));
    });

    test('reject needs a reason and writes no ledger row', () async {
      final c = await requested('cara', 100);
      final blank = await t.reject(
        actorUid: 'alice',
        familyId: _f,
        contributionId: c.id,
        reason: '  ',
      );
      expect(blank.failureOrNull, const Validation('reason', 'required'));
      final ok = await t.reject(
        actorUid: 'alice',
        familyId: _f,
        contributionId: c.id,
        reason: 'Not received',
      );
      expect(ok.valueOrNull!.status, ContributionApproval.rejected);
      expect(ok.valueOrNull!.rejectReason, 'Not received');
      expect(t.fx.backend.fundTransactionsOf(_f), isEmpty);
    });
  });

  group('change requests', () {
    test('request writes only pendingChange; the ledger does not move', () async {
      final c = await recorded('cara', 100000);
      final r = await t.requestChange(
        actorUid: 'cara',
        familyId: _f,
        contributionId: c.id,
        amount: const Money.paisa(150000),
        date: t.today,
      );
      expect(r.valueOrNull!.pendingChange!.amount.paisa, 150000);
      expect(r.valueOrNull!.amount.paisa, 100000);
      expect(t.balance.paisa, 100000);
      final again = await t.requestChange(
        actorUid: 'cara',
        familyId: _f,
        contributionId: c.id,
        amount: const Money.paisa(1),
        date: t.today,
      );
      expect(again.failureOrNull, const Conflict(code: 'change_already_pending'));
    });

    test('only the owner may ask; a pending request is not "approved"', () async {
      final c = await recorded('cara', 100);
      final other = await t.requestChange(
        actorUid: 'bob',
        familyId: _f,
        contributionId: c.id,
        amount: const Money.paisa(5),
        date: t.today,
      );
      expect(other.failureOrNull, isA<PermissionDenied>());
      final p = await requested('cara', 100);
      final notApproved = await t.requestChange(
        actorUid: 'cara',
        familyId: _f,
        contributionId: p.id,
        amount: const Money.paisa(5),
        date: t.today,
      );
      expect(notApproved.failureOrNull, const Conflict(code: 'contribution_not_approved'));
    });

    test('approve moves the balance by exactly the delta', () async {
      final c = await recorded('cara', 100000);
      await t.requestChange(
        actorUid: 'cara',
        familyId: _f,
        contributionId: c.id,
        amount: const Money.paisa(130000),
        date: t.today,
      );
      final r = await t.approveChange(
        actorUid: 'alice',
        familyId: _f,
        contributionId: c.id,
      );
      expect(r.valueOrNull!.amount.paisa, 130000);
      expect(r.valueOrNull!.pendingChange, isNull);
      expect(t.balance.paisa, 130000);
      final adj = t.fx.backend
          .fundTransactionsOf(_f)
          .where((x) => x.type == FundTxType.adjustment)
          .single;
      expect(adj.amount.paisa, 30000);
      // The original ledger row was never edited.
      expect(t.fx.backend.fundTransactions[_f]!['con_${c.id}']!.amount.paisa, 100000);
    });

    test('a lower amount writes a negative delta; an equal one writes none', () async {
      final c = await recorded('cara', 100000);
      await t.requestChange(
        actorUid: 'cara',
        familyId: _f,
        contributionId: c.id,
        amount: const Money.paisa(40000),
        date: t.today,
      );
      await t.approveChange(actorUid: 'alice', familyId: _f, contributionId: c.id);
      expect(t.balance.paisa, 40000);

      final d = await recorded('bob', 5000);
      await t.requestChange(
        actorUid: 'bob',
        familyId: _f,
        contributionId: d.id,
        amount: const Money.paisa(5000),
        date: t.today,
        method: ContributionMethod.bank,
      );
      await t.approveChange(actorUid: 'alice', familyId: _f, contributionId: d.id);
      expect(
        t.fx.backend
            .fundTransactionsOf(_f)
            .where((x) => x.type == FundTxType.adjustment),
        hasLength(1),
      );
      expect(t.repo.contributions[d.id]!.method, ContributionMethod.bank);
    });

    test('moving the date into another month writes an out and an in row', () async {
      final c = await recorded('cara', 100000, date: DateKey(2026, 9, 28));
      await t.requestChange(
        actorUid: 'cara',
        familyId: _f,
        contributionId: c.id,
        amount: const Money.paisa(100000),
        date: DateKey(2026, 10, 2),
      );
      final r = await t.approveChange(
        actorUid: 'alice',
        familyId: _f,
        contributionId: c.id,
      );
      expect(r.valueOrNull!.monthKey, MonthKey(2026, 10));
      final adj = t.fx.backend
          .fundTransactionsOf(_f)
          .where((x) => x.type == FundTxType.adjustment)
          .toList();
      expect(adj, hasLength(2));
      expect(adj.map((x) => x.monthKey.toString()).toSet(), <String>{'2026-09', '2026-10'});
      expect(adj.fold<int>(0, (s, x) => s + x.amount.paisa), 0);
      expect(t.balance.paisa, 100000);
    });

    test('reject only clears the request and records the reason', () async {
      final c = await recorded('cara', 100000);
      await t.requestChange(
        actorUid: 'cara',
        familyId: _f,
        contributionId: c.id,
        amount: const Money.paisa(1),
        date: t.today,
      );
      final r = await t.rejectChange(
        actorUid: 'alice',
        familyId: _f,
        contributionId: c.id,
        reason: 'wrong amount',
      );
      expect(r.valueOrNull!.pendingChange, isNull);
      expect(r.valueOrNull!.amount.paisa, 100000);
      expect(t.repo.events.last.params['reason'], 'wrong amount');
      expect(t.balance.paisa, 100000);
    });

    test('approve without a request conflicts', () async {
      final c = await recorded('cara', 100);
      final r = await t.approveChange(
        actorUid: 'alice',
        familyId: _f,
        contributionId: c.id,
      );
      expect(r.failureOrNull, const Conflict(code: 'no_pending_change'));
    });
  });

  group('VoidContribution', () {
    test('keeps the balance right with a compensating row', () async {
      final a = await recorded('cara', 100000);
      await recorded('bob', 50000);
      final r = await t.voidIt(actorUid: 'alice', familyId: _f, contributionId: a.id);
      expect(r.valueOrNull!.isVoided, isTrue);
      expect(t.balance.paisa, 50000);
      expect(t.fx.backend.fundTransactions[_f]!['con_${a.id}']!.amount.paisa, 100000);
    });

    test('only approved, only once, and not in a locked month', () async {
      final p = await requested('cara', 100);
      final pending = await t.voidIt(actorUid: 'alice', familyId: _f, contributionId: p.id);
      expect(pending.failureOrNull, const Conflict(code: 'contribution_not_approved'));

      final a = await recorded('cara', 100);
      await t.voidIt(actorUid: 'alice', familyId: _f, contributionId: a.id);
      final twice = await t.voidIt(actorUid: 'alice', familyId: _f, contributionId: a.id);
      expect(twice.failureOrNull, const Conflict(code: 'already_voided'));

      final b = await recorded('bob', 100);
      t.close(MonthKey(2026, 10));
      final locked = await t.voidIt(actorUid: 'alice', familyId: _f, contributionId: b.id);
      expect(locked.failureOrNull, const Conflict(code: 'month_locked'));
    });

    test('a member cannot void', () async {
      final a = await recorded('cara', 100);
      final r = await t.voidIt(actorUid: 'cara', familyId: _f, contributionId: a.id);
      expect(r.failureOrNull, isA<PermissionDenied>());
    });
  });

  group('plans', () {
    test('GenerateMonthPlans splits the target among active members only', () async {
      t.settings.stored = const BazarSettings(
        defaultMonthlyContribution: Money.paisa(500000),
      );
      final r = await t.generate(
        actorUid: 'alice',
        familyId: _f,
        month: ContributionFixture.october,
      );
      final plans = r.valueOrNull!;
      expect(plans.map((p) => p.memberId).toSet(), <String>{'alice', 'bob', 'cara'});
      expect(plans.fold<int>(0, (s, p) => s + p.expected.paisa), 500000);
    });

    test('never overwrites an override and is idempotent', () async {
      t.settings.stored = const BazarSettings(
        defaultMonthlyContribution: Money.paisa(300000),
      );
      await t.setPlan(
        actorUid: 'alice',
        familyId: _f,
        memberId: 'cara',
        month: ContributionFixture.october,
        expected: const Money.paisa(7),
      );
      await t.generate(
        actorUid: 'alice',
        familyId: _f,
        month: ContributionFixture.october,
      );
      expect(t.repo.plans['2026-10_cara']!.expected.paisa, 7);
      final again = await t.generate(
        actorUid: 'alice',
        familyId: _f,
        month: ContributionFixture.october,
      );
      expect(again.valueOrNull, isEmpty);
    });

    test('a zero target is a validation error; plans need permission', () async {
      final zero = await t.generate(
        actorUid: 'alice',
        familyId: _f,
        month: ContributionFixture.october,
      );
      expect(zero.failureOrNull, const Validation('target', 'required'));
      final denied = await t.setPlan(
        actorUid: 'cara',
        familyId: _f,
        memberId: 'cara',
        month: ContributionFixture.october,
        expected: const Money.paisa(1),
      );
      expect(denied.failureOrNull, isA<PermissionDenied>());
      final negative = await t.setPlan(
        actorUid: 'alice',
        familyId: _f,
        memberId: 'cara',
        month: ContributionFixture.october,
        expected: const Money.paisa(-1),
      );
      expect(negative.failureOrNull, const Validation('expected', 'negative'));
    });
  });

  group('RecordOpeningBalance', () {
    test('writes the open_ row and the start month once', () async {
      final r = await t.opening(
        actorUid: 'alice',
        familyId: _f,
        startMonth: ContributionFixture.october,
        amount: const Money.paisa(250000),
      );
      expect(r.isSuccess, isTrue);
      expect(t.balance.paisa, 250000);
      expect(t.settings.stored.fundStartMonth, ContributionFixture.october);
      expect(
        t.fx.backend.fundTransactions[_f]!.keys,
        contains('open_2026-10'),
      );
      final again = await t.opening(
        actorUid: 'alice',
        familyId: _f,
        startMonth: ContributionFixture.october,
        amount: const Money.paisa(1),
      );
      expect(again.failureOrNull, const Conflict(code: 'fund_already_started'));
    });

    test('a zero amount only sets the month; admin only; no future month', () async {
      final zero = await t.opening(
        actorUid: 'alice',
        familyId: _f,
        startMonth: ContributionFixture.october,
        amount: Money.zero,
      );
      expect(zero.isSuccess, isTrue);
      expect(t.fx.backend.fundTransactionsOf(_f), isEmpty);

      final t2 = ContributionFixture();
      final moderator = await t2.opening(
        actorUid: 'bob',
        familyId: _f,
        startMonth: ContributionFixture.october,
        amount: const Money.paisa(1),
      );
      expect(moderator.failureOrNull, isA<PermissionDenied>());
      final future = await t2.opening(
        actorUid: 'alice',
        familyId: _f,
        startMonth: MonthKey(2026, 11),
        amount: const Money.paisa(1),
      );
      expect(future.failureOrNull, const Validation('startMonth', 'future_date'));
    });
  });

  group('a scripted month', () {
    test('expected, received and remaining match the hand-computed values', () async {
      t.settings.stored = const BazarSettings(
        defaultMonthlyContribution: Money.paisa(300000),
      );
      await t.generate(
        actorUid: 'alice',
        familyId: _f,
        month: ContributionFixture.october,
      );
      await recorded('alice', 100000);
      final cara = await requested('cara', 60000);
      await t.approve(actorUid: 'bob', familyId: _f, contributionId: cara.id);
      await requested('cara', 40000); // still pending
      final bob = await recorded('bob', 130000);
      await t.voidIt(actorUid: 'alice', familyId: _f, contributionId: bob.id);

      final rows = ContributionStatusCalculator.compute(
        plans: t.repo.plans.values.toList(),
        contributions: t.repo.contributions.values.toList(),
        activeMemberIds: <String>['alice', 'bob', 'cara'],
      );
      final byId = {for (final r in rows) r.memberId: r};
      expect(byId['alice']!.remaining, Money.zero);
      expect(byId['bob']!.received, Money.zero);
      expect(byId['bob']!.remaining.paisa, 100000);
      expect(byId['cara']!.received.paisa, 60000);
      expect(byId['cara']!.remaining.paisa, 40000);
      expect(byId['cara']!.pendingTotal.paisa, 40000);
      // 100,000 + 60,000 recorded/approved; bob's 130,000 was voided.
      expect(t.balance.paisa, 160000);
      expect(ContributionStatusCalculator.totalReceived(rows).paisa, 160000);
    });
  });
}
