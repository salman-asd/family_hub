import 'package:family_hub/core/audit/audit_event.dart';
import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/core/utils/money.dart';
import 'package:family_hub/features/bazar/contributions/domain/contribution.dart';
import 'package:family_hub/features/bazar/contributions/domain/contribution_repository.dart';
import 'package:family_hub/features/bazar/contributions/domain/contribution_write_plans.dart';
import 'package:family_hub/features/bazar/contributions/domain/usecases/approve_contribution.dart';
import 'package:family_hub/features/bazar/contributions/domain/usecases/approve_contribution_change.dart';
import 'package:family_hub/features/bazar/contributions/domain/usecases/cancel_contribution_request.dart';
import 'package:family_hub/features/bazar/contributions/domain/usecases/edit_pending_contribution.dart';
import 'package:family_hub/features/bazar/contributions/domain/usecases/generate_month_plans.dart';
import 'package:family_hub/features/bazar/contributions/domain/usecases/record_contribution.dart';
import 'package:family_hub/features/bazar/contributions/domain/usecases/record_opening_balance.dart';
import 'package:family_hub/features/bazar/contributions/domain/usecases/reject_contribution.dart';
import 'package:family_hub/features/bazar/contributions/domain/usecases/reject_contribution_change.dart';
import 'package:family_hub/features/bazar/contributions/domain/usecases/request_contribution.dart';
import 'package:family_hub/features/bazar/contributions/domain/usecases/request_contribution_change.dart';
import 'package:family_hub/features/bazar/contributions/domain/usecases/set_contribution_plan.dart';
import 'package:family_hub/features/bazar/contributions/domain/usecases/void_contribution.dart';
import 'package:family_hub/features/bazar/fund/domain/fund_balance_calculator.dart';
import 'package:family_hub/features/bazar/fund/domain/fund_transaction.dart';
import 'package:family_hub/features/bazar/fund/domain/month_closing.dart';

import '../../../support/in_memory_bazar_backend.dart';
import '../bazar_test_helpers.dart';
import '../settings/bazar_settings_test_helpers.dart';

/// In-memory [ContributionRepository] that writes its ledger rows into the
/// shared [InMemoryBazarBackend], so a test can read the real fund balance.
class FakeContributionRepository implements ContributionRepository {
  FakeContributionRepository(this.backend, this.settings);

  final InMemoryBazarBackend backend;
  final FakeBazarSettingsRepository settings;
  final Map<String, Contribution> contributions = <String, Contribution>{};
  final Map<String, ContributionPlan> plans = <String, ContributionPlan>{};
  final List<AuditEvent> events = <AuditEvent>[];
  AppFailure? nextFailure;
  int writes = 0;
  final List<bool> freshReads = <bool>[];

  Result<void>? _fail() {
    final failure = nextFailure;
    if (failure == null) return null;
    nextFailure = null;
    return Failure<void>(failure);
  }

  void _ledger(String familyId, Iterable<FundTransaction?> rows) {
    final map = backend.fundTransactions[familyId] ??=
        <String, FundTransaction>{};
    for (final row in rows) {
      if (row == null) continue;
      // A ledger row is append-only: the same id twice is a bug.
      if (map.containsKey(row.id)) {
        throw StateError('ledger row ${row.id} written twice');
      }
      map[row.id] = row;
    }
  }

  @override
  Stream<List<ContributionPlan>> watchPlans(
    String familyId,
    MonthKey month, {
    String? memberId,
  }) => Stream.value(<ContributionPlan>[
    for (final p in plans.values)
      if (p.month == month && (memberId == null || p.memberId == memberId)) p,
  ]);

  @override
  Stream<List<Contribution>> watchContributions(
    String familyId,
    MonthKey month, {
    String? memberId,
  }) => Stream.value(<Contribution>[
    for (final c in contributions.values)
      if (c.monthKey == month && (memberId == null || c.memberId == memberId))
        c,
  ]);

  @override
  Future<Result<List<ContributionPlan>>> getPlans(
    String familyId,
    MonthKey month,
  ) async => Success<List<ContributionPlan>>(<ContributionPlan>[
    for (final p in plans.values)
      if (p.month == month) p,
  ]);

  @override
  Future<Result<Contribution?>> getContribution(
    String familyId,
    String id, {
    bool fresh = false,
  }) async {
    freshReads.add(fresh);
    return Success<Contribution?>(contributions[id]);
  }

  @override
  Future<Result<void>> savePlans(
    String familyId,
    List<ContributionPlan> list,
    AuditEvent event,
  ) async {
    final failed = _fail();
    if (failed != null) return failed;
    for (final p in list) {
      plans[p.id] = p;
    }
    events.add(event);
    writes++;
    return const Success<void>(null);
  }

  @override
  Future<Result<void>> commitContribution(
    String familyId,
    ContributionWritePlan plan,
    AuditEvent event,
  ) async {
    final failed = _fail();
    if (failed != null) return failed;
    contributions[plan.contribution.id] = plan.contribution;
    _ledger(familyId, <FundTransaction?>[plan.fundTx]);
    events.add(event);
    writes++;
    return const Success<void>(null);
  }

  @override
  Future<Result<void>> saveContribution(
    String familyId,
    Contribution contribution,
    AuditEvent event,
  ) async {
    final failed = _fail();
    if (failed != null) return failed;
    contributions[contribution.id] = contribution;
    events.add(event);
    writes++;
    return const Success<void>(null);
  }

  @override
  Future<Result<void>> commitDecision(
    String familyId,
    ContributionDecisionPlan plan,
    AuditEvent event,
  ) async {
    final failed = _fail();
    if (failed != null) return failed;
    contributions[plan.updated.id] = plan.updated;
    _ledger(familyId, <FundTransaction?>[plan.fundTx, ...plan.adjustments]);
    events.add(event);
    writes++;
    return const Success<void>(null);
  }

  @override
  Future<Result<void>> commitVoid(
    String familyId,
    ContributionVoidPlan plan,
    AuditEvent event,
  ) async {
    final failed = _fail();
    if (failed != null) return failed;
    contributions[plan.voided.id] = plan.voided;
    _ledger(familyId, <FundTransaction?>[plan.adjustment]);
    events.add(event);
    writes++;
    return const Success<void>(null);
  }

  @override
  Future<Result<void>> commitOpeningBalance(
    String familyId,
    OpeningBalancePlan plan,
    AuditEvent event,
  ) async {
    final failed = _fail();
    if (failed != null) return failed;
    _ledger(familyId, <FundTransaction?>[plan.opening]);
    settings.stored = settings.stored.copyWith(
      fundStartMonth: plan.startMonth,
    );
    events.add(event);
    writes++;
    return const Success<void>(null);
  }
}

/// Fixture: the standard Bazar family (alice admin, bob moderator, cara member,
/// dave pending), a fake contribution repository and every use case.
class ContributionFixture {
  ContributionFixture()
    : fx = BazarFixture(),
      settings = FakeBazarSettingsRepository() {
    repo = FakeContributionRepository(fx.backend, settings);
  }

  static const String familyId = BazarFixture.familyId;
  static final MonthKey october = MonthKey(2026, 10);

  final BazarFixture fx;
  final FakeBazarSettingsRepository settings;
  late final FakeContributionRepository repo;

  /// 2026-10-18 in the family zone.
  DateKey get today => fx.dateKeys.today();

  Money get balance =>
      FundBalanceCalculator.balance(fx.backend.fundTransactionsOf(familyId));

  void close(MonthKey month) {
    (fx.backend.closings[familyId] ??= <MonthKey, MonthClosing>{})[month] =
        MonthClosing(monthKey: month, status: MonthStatus.closed);
  }

  RecordContribution get record => RecordContribution(
    contributions: repo,
    funds: fx.backend,
    families: fx.backend,
    clock: fx.clock,
    newId: fx.ids.call,
    dateKeys: fx.dateKeys,
  );

  RequestContribution get request => RequestContribution(
    contributions: repo,
    funds: fx.backend,
    families: fx.backend,
    clock: fx.clock,
    newId: fx.ids.call,
    dateKeys: fx.dateKeys,
  );

  EditPendingContribution get edit => EditPendingContribution(
    contributions: repo,
    funds: fx.backend,
    families: fx.backend,
    clock: fx.clock,
    newId: fx.ids.call,
    dateKeys: fx.dateKeys,
  );

  CancelContributionRequest get cancel => CancelContributionRequest(
    contributions: repo,
    funds: fx.backend,
    families: fx.backend,
    clock: fx.clock,
    newId: fx.ids.call,
  );

  ApproveContribution get approve => ApproveContribution(
    contributions: repo,
    funds: fx.backend,
    families: fx.backend,
    clock: fx.clock,
    newId: fx.ids.call,
  );

  RejectContribution get reject => RejectContribution(
    contributions: repo,
    funds: fx.backend,
    families: fx.backend,
    clock: fx.clock,
    newId: fx.ids.call,
  );

  RequestContributionChange get requestChange => RequestContributionChange(
    contributions: repo,
    funds: fx.backend,
    families: fx.backend,
    clock: fx.clock,
    newId: fx.ids.call,
    dateKeys: fx.dateKeys,
  );

  ApproveContributionChange get approveChange => ApproveContributionChange(
    contributions: repo,
    funds: fx.backend,
    families: fx.backend,
    clock: fx.clock,
    newId: fx.ids.call,
  );

  RejectContributionChange get rejectChange => RejectContributionChange(
    contributions: repo,
    funds: fx.backend,
    families: fx.backend,
    clock: fx.clock,
    newId: fx.ids.call,
  );

  VoidContribution get voidIt => VoidContribution(
    contributions: repo,
    funds: fx.backend,
    families: fx.backend,
    clock: fx.clock,
    newId: fx.ids.call,
  );

  SetContributionPlan get setPlan => SetContributionPlan(
    contributions: repo,
    families: fx.backend,
    clock: fx.clock,
    newId: fx.ids.call,
  );

  GenerateMonthPlans get generate => GenerateMonthPlans(
    contributions: repo,
    settings: settings,
    families: fx.backend,
    clock: fx.clock,
    newId: fx.ids.call,
  );

  RecordOpeningBalance get opening => RecordOpeningBalance(
    contributions: repo,
    settings: settings,
    funds: fx.backend,
    families: fx.backend,
    clock: fx.clock,
    newId: fx.ids.call,
    dateKeys: fx.dateKeys,
  );
}
