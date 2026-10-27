import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/core/utils/money.dart';
import 'package:family_hub/features/bazar/fund/domain/fund_transaction.dart';
import 'package:family_hub/features/bazar/fund/domain/month_closing.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../bazar_test_helpers.dart';

const String _f = BazarFixture.familyId;
final MonthKey _october = MonthKey(2026, 10);
final MonthKey _november = MonthKey(2026, 11);

/// P2-21: closing carries the balance forward, reopening only flips the lock.
void main() {
  late BazarFixture fx;

  setUp(() => fx = BazarFixture());

  FundTransaction contribution(String id, int paisa, {MonthKey? month}) {
    final m = month ?? _october;
    return FundTransaction.forContribution(
      contributionId: id,
      amount: Money.paisa(paisa),
      dateKey: DateKey(m.year, m.month, 5),
      createdBy: 'alice',
      createdAt: fx.clock.nowUtc(),
    );
  }

  FundTransaction spend(String id, int paisa, {MonthKey? month}) {
    final m = month ?? _october;
    return FundTransaction.forExpense(
      expenseId: id,
      total: Money.paisa(paisa),
      dateKey: DateKey(m.year, m.month, 9),
      createdBy: 'cara',
      createdAt: fx.clock.nowUtc(),
    );
  }

  Future<AppFailure?> close({
    MonthKey? month,
    String actor = 'alice',
    String? eventId,
  }) async {
    final result = await fx.closeMonth(
      actorUid: actor,
      familyId: _f,
      month: month ?? _october,
      eventId: eventId,
    );
    return result.failureOrNull;
  }

  Money balanceOf(MonthKey from, MonthKey to) =>
      Money.sum(
        fx.backend
            .fundTransactionsBetween(_f, from, to)
            .map((row) => row.amount),
      );

  group('CloseMonth', () {
    test('closes an empty next month with one carry-forward row', () async {
      fx.putFundTransaction(contribution('c1', 100000));
      fx.putFundTransaction(spend('e1', 30000));

      expect(await close(), isNull);

      final closing = fx.backend.closings[_f]![_october]!;
      expect(closing.status, MonthStatus.closed);
      expect(closing.closingBalance, const Money.paisa(70000));
      expect(closing.closedBy, 'alice');

      final opening = fx.backend.fundTransactions[_f]!['open_2026-11']!;
      expect(opening.amount, const Money.paisa(70000));
      expect(opening.type, FundTxType.opening);

      // The closing itself never moves the balance (no double count).
      expect(balanceOf(_october, _november), const Money.paisa(70000));
      // The window now starts in November, and still holds the whole balance.
      expect(balanceOf(_november, _november), const Money.paisa(70000));
    });

    test('a re-close after a reopen writes only the delta row', () async {
      fx.putFundTransaction(contribution('c1', 100000));
      expect(await close(), isNull);
      expect(balanceOf(_november, _november), const Money.paisa(100000));

      expect(
        (
          await fx.reopenMonth(
            actorUid: 'alice',
            familyId: _f,
            month: _october,
            note: 'missed a bill',
          )
        ).failureOrNull,
        isNull,
      );
      // The correction lands in October, the month that was wrong.
      fx.putFundTransaction(spend('late', 4000));

      expect(await close(eventId: 'ev2'), isNull);

      final carry = fx.backend.fundTransactions[_f]!['adj_ev2_carry']!;
      expect(carry.amount, const Money.paisa(-4000));
      expect(carry.monthKey, _november);
      // The original opening row is untouched and the window still balances.
      expect(
        fx.backend.fundTransactions[_f]!['open_2026-11']!.amount,
        const Money.paisa(100000),
      );
      expect(balanceOf(_november, _november), const Money.paisa(96000));
      expect(fx.backend.closings[_f]![_october]!.reopenCount, 1);
    });

    test('refuses a future month, a closed month and a later closed month', () async {
      expect(
        await close(month: MonthKey(2027, 1)),
        const Validation('month', 'invalid_month'),
      );

      fx.putClosing(monthKey: _october);
      expect(await close(), const Conflict(code: 'already_closed'));

      fx = BazarFixture();
      fx.putClosing(monthKey: _november);
      expect(await close(), const Conflict(code: 'month_locked'));
      expect(fx.backend.writes, 0);
    });

    test('permission: a plain member may not close, a manager may', () async {
      expect(await close(actor: 'cara'), isA<PermissionDenied>());
      expect(await close(actor: 'bob'), isNull);
    });

    test('one log entry, with machine params only', () async {
      fx.putFundTransaction(contribution('c1', 5000));
      await close(eventId: 'ev9');

      final event = fx.backend.events.single;
      expect(event.id, 'ev9');
      expect(event.type, 'bazar.month_closed');
      expect(event.params['closingBalance'], '5000');
      expect(event.params['nextOpening'], '5000');
    });

    test('a server read failure writes nothing', () async {
      fx.backend.failNextWrite = const Network();
      expect(await close(), isA<Network>());
      expect(fx.backend.closingsOf(_f), isEmpty);
    });
  });

  group('ReopenMonth', () {
    Future<AppFailure?> reopen({
      String note = 'wrong month',
      MonthKey? month,
      String actor = 'alice',
    }) async {
      final result = await fx.reopenMonth(
        actorUid: actor,
        familyId: _f,
        month: month ?? _october,
        note: note,
      );
      return result.failureOrNull;
    }

    test('reopens a closed month with its note and a higher count', () async {
      fx.putClosing(monthKey: _october);
      expect(await reopen(), isNull);

      final reopened = fx.backend.closings[_f]![_october]!;
      expect(reopened.status, MonthStatus.open);
      expect(reopened.reopenNote, 'wrong month');
      expect(reopened.reopenedBy, 'alice');
      expect(reopened.reopenCount, 1);
      // A reopened month no longer moves the window.
      expect(
        MonthLocks.fundWindowStart(
          <MonthKey, MonthClosing>{_october: reopened},
          MonthKey(2026, 1),
        ),
        MonthKey(2026, 1),
      );
    });

    test('requires a real note', () async {
      fx.putClosing(monthKey: _october);
      expect(
        await reopen(note: ' x '),
        const Conflict(code: 'reopen_note_required'),
      );
    });

    test('refuses an open month, a later closed month and a plain member', () async {
      expect(await reopen(), const Conflict(code: 'not_closed'));

      fx.putClosing(monthKey: _october);
      fx.putClosing(monthKey: _november);
      expect(
        await reopen(),
        const Conflict(code: 'later_month_closed'),
      );

      fx = BazarFixture();
      fx.putClosing(monthKey: _october);
      expect(await reopen(actor: 'cara'), isA<PermissionDenied>());
    });

    test('a long note is kept in the document and clipped in the log', () async {
      fx.putClosing(monthKey: _october);
      final note = 'a' * 400;
      expect(await reopen(note: note), isNull);

      expect(fx.backend.closings[_f]![_october]!.reopenNote, note);
      final event = fx.backend.events.single;
      expect(event.params['note'], hasLength(100));
      expect(event.params['reopenCount'], '2');
    });
  });
}
