import 'package:family_hub/core/audit/audit_event_type.dart';
import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/firebase/tx_runner.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/core/utils/money.dart';
import 'package:family_hub/core/utils/quantity.dart';
import 'package:family_hub/features/bazar/advances/domain/member_advance.dart';
import 'package:family_hub/features/bazar/expenses/domain/expense_draft.dart';
import 'package:family_hub/features/bazar/expenses/domain/funding.dart';
import 'package:family_hub/features/bazar/expenses/domain/trip.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../bazar_test_helpers.dart';

void main() {
  late BazarFixture f;

  setUp(() => f = BazarFixture());

  test('writes the trip, its lines and one aggregated usage bump', () async {
    f.putItem(id: 'item_rice');
    final lines = <ExpenseDraft>[
      _line(itemId: 'item_rice', total: 10000),
      _line(itemId: 'item_rice', total: 2500),
    ];

    final result = await f.addBazarTrip(
      actorUid: 'alice',
      familyId: BazarFixture.familyId,
      header: TripDraft(
        dateKey: f.dateKeys.today(),
        shop: 'Karwan Bazar',
        note: 'weekly',
      ),
      lines: lines,
      tripId: 'trip-1',
      lineIds: <String>['e1', 'e2'],
      eventId: 'ev1',
    );

    final trip = result.valueOrNull!;
    expect(trip.id, 'trip-1');
    expect(trip.lineCount, 2);
    expect(trip.total, const Money.paisa(12500));
    expect(f.backend.tripsOf(BazarFixture.familyId).single, trip);
    expect(f.backend.expensesOf(BazarFixture.familyId).length, 2);
    expect(
      f.backend
          .expensesOf(BazarFixture.familyId)
          .every((expense) => expense.tripId == 'trip-1'),
      isTrue,
    );
    expect(f.backend.fundTransactionsOf(BazarFixture.familyId).length, 2);
    expect(f.backend.itemsOf(BazarFixture.familyId).single.useCount, 2);
    expect(
      f.backend.events
          .where((event) => event.type == AuditEventType.bazarTripCreated)
          .length,
      1,
    );
  });

  test('forty lines are accepted as one trip', () async {
    final forty = List<ExpenseDraft>.generate(40, (index) => _line(total: 100));
    final result = await f.addBazarTrip(
      actorUid: 'alice',
      familyId: BazarFixture.familyId,
      header: TripDraft(dateKey: f.dateKeys.today()),
      lines: forty,
    );

    expect(result.valueOrNull?.lineCount, 40);
    expect(f.backend.expensesOf(BazarFixture.familyId).length, 40);
    expect(f.backend.fundTransactionsOf(BazarFixture.familyId).length, 40);
    expect(f.backend.tripsOf(BazarFixture.familyId).single.lineCount, 40);
    // 40 lines x (expense + fund row), the trip header and the audit event.
    expect(40 * 2 + 2, lessThanOrEqualTo(kMaxBatchWrites));
  });

  test('one to forty lines are accepted, zero and forty-one are not', () async {
    final many = List<ExpenseDraft>.generate(41, (index) => _line(total: 100));

    final tooMany = await f.addBazarTrip(
      actorUid: 'alice',
      familyId: BazarFixture.familyId,
      header: TripDraft(dateKey: f.dateKeys.today()),
      lines: many,
    );
    expect(tooMany.failureOrNull, const Validation('lines', 'too_many_lines'));

    final empty = await f.addBazarTrip(
      actorUid: 'alice',
      familyId: BazarFixture.familyId,
      header: TripDraft(dateKey: f.dateKeys.today()),
      lines: const <ExpenseDraft>[],
    );
    expect(empty.failureOrNull, const Validation('lines', 'too_many_lines'));
  });

  test('a member trip creates one pending advance per line', () async {
    final result = await f.addBazarTrip(
      actorUid: 'alice',
      familyId: BazarFixture.familyId,
      header: TripDraft(
        dateKey: f.dateKeys.today(),
        funding: FundingSource.member,
        paidByMemberId: 'bob',
        reimbursable: true,
      ),
      lines: <ExpenseDraft>[_line(total: 1000), _line(total: 2000)],
      lineIds: <String>['e1', 'e2'],
    );

    expect(result.isSuccess, isTrue);
    expect(f.backend.fundTransactionsOf(BazarFixture.familyId), isEmpty);
    final advances = f.backend.advancesOf(BazarFixture.familyId);
    expect(advances.length, 2);
    expect(advances.every((advance) => advance.memberId == 'bob'), isTrue);
    expect(
      advances.every((advance) => advance.status == AdvanceStatus.pending),
      isTrue,
    );
  });

  test('a remembered line item gets a deterministic id', () async {
    final result = await f.addBazarTrip(
      actorUid: 'alice',
      familyId: BazarFixture.familyId,
      header: TripDraft(dateKey: f.dateKeys.today()),
      lines: <ExpenseDraft>[
        _line(total: 5000, name: 'New trip item', remember: true),
      ],
      lineIds: <String>['e1'],
    );

    expect(result.isSuccess, isTrue);
    expect(f.backend.itemsOf(BazarFixture.familyId).single.id, 'item_e1');
  });
}

ExpenseDraft _line({
  String? itemId,
  int total = 10000,
  String name = 'চাল',
  bool remember = false,
}) {
  return ExpenseDraft(
    dateKey: DateKey(2026, 10, 18),
    itemId: itemId,
    itemName: name,
    categoryId: 'cat_food',
    qty: const Quantity.milli(1000),
    unit: Unit.kg,
    unitPrice: Money.paisa(total),
    funding: FundingSource.fund,
    rememberItem: remember,
  );
}
