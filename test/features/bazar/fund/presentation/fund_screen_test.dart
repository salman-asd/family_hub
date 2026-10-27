import 'package:family_hub/app/theme/theme_builder.dart';
import 'package:family_hub/app/theme/theme_registry.dart';
import 'package:family_hub/core/localization/generated/app_localizations.dart';
import 'package:family_hub/core/permissions/permissions.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/core/utils/money.dart';
import 'package:family_hub/features/bazar/contributions/domain/contribution.dart';
import 'package:family_hub/features/bazar/contributions/presentation/contribution_providers.dart';
import 'package:family_hub/features/bazar/contributions/presentation/widgets/contribution_history_list.dart';
import 'package:family_hub/features/bazar/contributions/presentation/widgets/pending_approvals_section.dart';
import 'package:family_hub/features/bazar/contributions/presentation/widgets/record_contribution_sheet.dart';
import 'package:family_hub/features/bazar/fund/domain/fund_transaction.dart';
import 'package:family_hub/features/bazar/fund/presentation/screens/fund_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../bazar_test_helpers.dart';
import '../../contributions/contribution_test_helpers.dart';
import '../../expenses/presentation/expense_test_container.dart';

/// P2-22: the Fund screen reads the real providers through the in-memory ports.
void main() {
  late BazarFixture fx;
  late ContributionFixture contributions;

  setUp(() {
    contributions = ContributionFixture();
    fx = contributions.fx;
  });

  FundTransaction contribution(String id, int paisa) =>
      FundTransaction.forContribution(
        contributionId: id,
        amount: Money.paisa(paisa),
        dateKey: DateKey(2026, 10, 5),
        createdBy: 'alice',
        createdAt: fx.clock.nowUtc(),
      );

  Future<void> pump(
    WidgetTester tester, {
    String uid = 'alice',
    Role role = Role.admin,
    Locale locale = const Locale('en'),
    double textScale = 1,
    double height = 1600,
    bool focusPendingApprovals = false,
  }) async {
    tester.view
      ..physicalSize = Size(420, height)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          ...bazarOverrides(fx, uid: uid, role: role),
          contributionRepositoryProvider.overrideWithValue(contributions.repo),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: buildThemeData(modernLightSpec),
          locale: locale,
          localizationsDelegates: const <LocalizationsDelegate<Object>>[
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
          home: FundScreen(focusPendingApprovals: focusPendingApprovals),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('shows the ledger balance and every member row to everyone', (
    tester,
  ) async {
    fx.putFundTransaction(contribution('c1', 100000));
    await pump(tester, uid: 'cara', role: Role.member);

    expect(find.byKey(const ValueKey('fund-balance')), findsOneWidget);
    // D-P2-5: a plain member sees all three active members' rows.
    expect(find.byKey(const ValueKey('fund-member-alice')), findsOneWidget);
    expect(find.byKey(const ValueKey('fund-member-bob')), findsOneWidget);
    expect(find.byKey(const ValueKey('fund-member-cara')), findsOneWidget);
    // ... but no approval tools.
    expect(find.byKey(const ValueKey('pending-approvals')), findsNothing);
  });

  testWidgets('a member gets "Request contribution"; a manager gets "Add"', (
    tester,
  ) async {
    await pump(tester, uid: 'cara', role: Role.member);
    expect(find.text('Request contribution'), findsOneWidget);

    await pump(tester, uid: 'alice', role: Role.admin);
    expect(find.text('Add contribution'), findsOneWidget);
  });

  testWidgets('a pending request shows awaiting approval and no balance move', (
    tester,
  ) async {
    await contributions.request(
      actorUid: 'cara',
      familyId: ContributionFixture.familyId,
      memberId: 'cara',
      amount: const Money.paisa(50000),
      date: contributions.today,
    );
    await pump(tester, uid: 'alice', role: Role.admin);

    expect(find.textContaining('awaiting approval'), findsWidgets);
    expect(contributions.balance, Money.zero);
    expect(find.byKey(const ValueKey('pending-approvals')), findsOneWidget);
  });

  testWidgets('approving moves the received amount and the balance once', (
    tester,
  ) async {
    final pending = await contributions.request(
      actorUid: 'cara',
      familyId: ContributionFixture.familyId,
      memberId: 'cara',
      amount: const Money.paisa(50000),
      date: contributions.today,
    );
    await pump(tester, uid: 'alice', role: Role.admin);

    await tester.tap(find.byKey(const ValueKey('pending-approve')).first);
    await tester.pump(const Duration(milliseconds: 400));

    expect(contributions.repo.contributions[pending.valueOrNull!.id]!.isApproved,
        isTrue);
    expect(contributions.balance, const Money.paisa(50000));
  });

  testWidgets('rejecting needs a reason', (tester) async {
    await contributions.request(
      actorUid: 'cara',
      familyId: ContributionFixture.familyId,
      memberId: 'cara',
      amount: const Money.paisa(50000),
      date: contributions.today,
    );
    await pump(tester, uid: 'alice', role: Role.admin);

    await tester.tap(find.byKey(const ValueKey('pending-reject')).first);
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byKey(const ValueKey('reject-reason')), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('reject-reason')),
      'wrong amount',
    );
    await tester.tap(find.byKey(const ValueKey('reject-reason-send')));
    await tester.pump(const Duration(milliseconds: 400));

    final rejected = contributions.repo.contributions.values.single;
    expect(rejected.status, ContributionApproval.rejected);
    expect(rejected.rejectReason, 'wrong amount');
    expect(contributions.balance, Money.zero);
  });

  testWidgets('the sheet records a manager contribution as approved', (
    tester,
  ) async {
    await pump(tester, uid: 'alice', role: Role.admin);
    await tester.tap(find.byKey(const ValueKey('fund-add-contribution')));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(ContributionSheet), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('contribution-amount')),
      '1250',
    );
    await tester.tap(find.byKey(const ValueKey('contribution-save')));
    await tester.pump(const Duration(milliseconds: 400));

    expect(contributions.repo.contributions.values.single.isApproved, isTrue);
    expect(contributions.balance, const Money.paisa(125000));
  });

  testWidgets('a member request from the sheet stays pending', (tester) async {
    await pump(tester, uid: 'cara', role: Role.member);
    await tester.tap(find.byKey(const ValueKey('fund-add-contribution')));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(ContributionSheet), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('contribution-amount')),
      '500',
    );
    await tester.tap(find.byKey(const ValueKey('contribution-save')));
    await tester.pump(const Duration(milliseconds: 400));

    expect(contributions.repo.contributions.values.single.isPending, isTrue);
    expect(contributions.balance, Money.zero);
  });

  testWidgets('history lists the ledger rows with a sign', (tester) async {
    fx.putFundTransaction(contribution('c1', 100000));
    await pump(tester);

    expect(find.byKey(const ValueKey('fund-row-con_c1')), findsOneWidget);
  });

  testWidgets('a Bangla locale at 2x text does not overflow', (tester) async {
    fx.putFundTransaction(contribution('c1', 100000));
    await pump(tester, locale: const Locale('bn'), textScale: 2);

    expect(tester.takeException(), isNull);
    expect(find.byKey(const ValueKey('fund-body')), findsOneWidget);
  });

  testWidgets('the manager sections are absent for a member', (tester) async {
    await pump(tester, uid: 'cara', role: Role.member);
    expect(find.byType(PendingApprovalsSection), findsOneWidget);
    // The widget hides itself by permission, so nothing is drawn for Cara.
    expect(find.byKey(const ValueKey('pending-approvals')), findsNothing);
    expect(find.byType(ContributionHistoryList), findsNothing);
  });

  testWidgets('pending approval deep link scrolls to the manager section', (
    tester,
  ) async {
    await contributions.request(
      actorUid: 'cara',
      familyId: ContributionFixture.familyId,
      memberId: 'cara',
      amount: const Money.paisa(50000),
      date: contributions.today,
    );
    await pump(tester, height: 520, focusPendingApprovals: true);

    final section = tester.getRect(find.byKey(const ValueKey('pending-approvals')));
    expect(section.top, lessThan(520));
    expect(tester.takeException(), isNull);
  });
}
