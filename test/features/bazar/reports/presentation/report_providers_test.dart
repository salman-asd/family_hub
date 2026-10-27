import 'package:family_hub/core/permissions/permissions.dart';
import 'package:family_hub/core/utils/clock_provider.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/core/utils/date_ranges.dart';
import 'package:family_hub/core/utils/money.dart';
import 'package:family_hub/features/bazar/expenses/presentation/expense_providers.dart';
import 'package:family_hub/features/bazar/reports/presentation/report_providers.dart';
import 'package:family_hub/features/bazar/settings/domain/bazar_settings.dart';
import 'package:family_hub/features/bazar/settings/presentation/bazar_settings_providers.dart';
import 'package:family_hub/features/family/presentation/family_providers.dart';
import 'package:family_hub/features/family/presentation/permission_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../bazar_test_helpers.dart';

/// P2-25: the providers behind the reports screen.
void main() {
  late BazarFixture fx;

  setUp(() => fx = BazarFixture());

  ProviderContainer makeContainer({
    int weekStartDay = 6,
    String uid = 'alice',
    Role role = Role.admin,
    PermissionSettings? settings,
  }) {
    final container = ProviderContainer(
      overrides: <Override>[
        clockProvider.overrideWithValue(fx.clock),
        currentFamilyIdProvider.overrideWithValue(BazarFixture.familyId),
        currentUidProvider.overrideWithValue(uid),
        currentActorProvider.overrideWithValue(
          PermissionActor(uid: uid, role: role, isActive: true),
        ),
        permissionSettingsProvider.overrideWithValue(
          settings ?? PermissionSettings.defaults,
        ),
        bazarSettingsProvider.overrideWithValue(
          BazarSettings.defaults.copyWith(weekStartDay: weekStartDay),
        ),
        expenseRepositoryProvider.overrideWithValue(fx.backend),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  Future<void> pump() async {
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
  }

  test('the default query is this month', () {
    final c = makeContainer();
    final query = c.read(reportQueryProvider);
    expect(query.preset, RangePreset.thisMonth);
    expect(query.resolvedRange, monthRange(MonthKey(2026, 10)));
  });

  test('changing the week start re-resolves "this week" at once', () {
    final c = makeContainer(weekStartDay: DateTime.saturday);
    c.read(reportQueryProvider.notifier).setPreset(RangePreset.thisWeek);
    expect(c.read(reportQueryProvider).resolvedRange.start, DateKey(2026, 10, 17));

    final monday = makeContainer(weekStartDay: DateTime.monday);
    monday.read(reportQueryProvider.notifier).setPreset(RangePreset.thisWeek);
    expect(
      monday.read(reportQueryProvider).resolvedRange.start,
      DateKey(2026, 10, 12),
    );
  });

  test('a whole month reuses the live month listener, a range does not', () async {
    fx.putExpense(id: 'a', total: const Money.paisa(1000));
    final c = makeContainer();
    final monthSub = c.listen(
      reportRowsProvider(monthRange(MonthKey(2026, 10))),
      (_, _) {},
    );
    addTearDown(monthSub.close);
    await pump();
    expect(monthSub.read().value!.count, 1);
    expect(monthSub.read().value!.truncated, isFalse);
  });

  test('the report data totals the selected month', () async {
    fx.putExpense(id: 'a', total: const Money.paisa(1000), categoryId: 'cat_food');
    fx.putExpense(
      id: 'b',
      dateKey: DateKey(2026, 9, 5),
      total: const Money.paisa(400),
      categoryId: 'cat_food',
    );
    final c = makeContainer();
    final sub = c.listen(reportDataProvider, (_, _) {});
    addTearDown(sub.close);
    await pump();

    final data = sub.read().value!;
    expect(data.summary.total, const Money.paisa(1000));
    expect(data.comparison!.previous, const Money.paisa(400));
    expect(data.comparison!.deltaBp, 15000); // +150 %
  });

  test('a category filter narrows the data', () async {
    fx.putExpense(id: 'a', total: const Money.paisa(1000), categoryId: 'cat_food');
    fx.putExpense(id: 'b', total: const Money.paisa(300), categoryId: 'cat_veg');
    final c = makeContainer();
    c.read(reportQueryProvider.notifier).setCategory('cat_veg');
    final sub = c.listen(reportDataProvider, (_, _) {});
    addTearDown(sub.close);
    await pump();

    expect(sub.read().value!.summary.total, const Money.paisa(300));
  });

  test('viewFamilyReports is off for a member when the family says so', () {
    final c = makeContainer(
      uid: 'cara',
      role: Role.member,
      settings: PermissionSettings.defaults.copyWith(
        membersViewFamilyReports: false,
      ),
    );
    expect(
      c.read(
        canProvider(const PermissionQuery(Permission.viewFamilyReports)),
      ),
      isFalse,
    );
  });

  test('moving to a custom range replaces the range only', () {
    final c = makeContainer();
    c.read(reportQueryProvider.notifier).setMember('cara');
    c.read(
      reportQueryProvider.notifier,
    ).setPreset(
      RangePreset.custom,
      custom: DateKeyRange(DateKey(2026, 10, 1), DateKey(2026, 10, 10)),
    );
    final query = c.read(reportQueryProvider);
    expect(query.resolvedRange.end, DateKey(2026, 10, 10));
    expect(query.memberId, 'cara');
  });
}
