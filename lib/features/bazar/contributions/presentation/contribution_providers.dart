import 'package:family_hub/core/utils/clock_provider.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/features/bazar/contributions/domain/contribution.dart';
import 'package:family_hub/features/bazar/contributions/domain/contribution_repository.dart';
import 'package:family_hub/features/bazar/contributions/domain/contribution_status.dart';
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
import 'package:family_hub/features/bazar/fund/presentation/fund_providers.dart';
import 'package:family_hub/features/bazar/settings/presentation/bazar_settings_providers.dart';
import 'package:family_hub/features/family/domain/member.dart';
import 'package:family_hub/features/family/presentation/family_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Overridden in `bootstrap.dart` and in tests.
final contributionRepositoryProvider = Provider<ContributionRepository>(
  (ref) => throw UnimplementedError(
    'contributionRepositoryProvider must be overridden '
    '(bootstrap.dart / tests).',
  ),
);

/// Plans of [month]: ONE listener.  Everyone reads everything (D-P2-5), so
/// there is no role-based filter.
final contributionPlansProvider = StreamProvider.autoDispose
    .family<List<ContributionPlan>, MonthKey>((ref, month) {
      final familyId = ref.watch(currentFamilyIdProvider);
      if (familyId == null) return Stream.value(const <ContributionPlan>[]);
      return ref
          .watch(contributionRepositoryProvider)
          .watchPlans(familyId, month);
    });

/// Contributions of [month] (every status): ONE listener.
final contributionsProvider = StreamProvider.autoDispose
    .family<List<Contribution>, MonthKey>((ref, month) {
      final familyId = ref.watch(currentFamilyIdProvider);
      if (familyId == null) return Stream.value(const <Contribution>[]);
      return ref
          .watch(contributionRepositoryProvider)
          .watchContributions(familyId, month);
    });

/// The active members' uids in roster order.
final activeMemberIdsProvider = Provider<List<String>>((ref) {
  final members = ref.watch(membersProvider).value ?? const <Member>[];
  return <String>[
    for (final m in members)
      if (m.isActive) m.uid,
  ];
});

/// Expected / received / remaining / credit / awaiting approval per member.
final contributionStatusProvider = Provider.autoDispose
    .family<List<MemberContributionStatus>, MonthKey>(
      (ref, month) => ContributionStatusCalculator.compute(
        plans: ref.watch(contributionPlansProvider(month)).value ??
            const <ContributionPlan>[],
        contributions: ref.watch(contributionsProvider(month)).value ??
            const <Contribution>[],
        activeMemberIds: ref.watch(activeMemberIdsProvider),
      ),
    );

/// Requests and change requests that wait for a manager (feeds the approval
/// list and the dashboard badge).  Voided rows are never listed.
final pendingContributionsProvider = Provider.autoDispose
    .family<List<Contribution>, MonthKey>((ref, month) {
      final all = ref.watch(contributionsProvider(month)).value ??
          const <Contribution>[];
      return <Contribution>[
        for (final c in all)
          if (c.isPending || (c.isApproved && c.pendingChange != null)) c,
      ];
    });

/// The signed-in member's own contributions of [month].
final myContributionsProvider = Provider.autoDispose
    .family<List<Contribution>, MonthKey>((ref, month) {
      final uid = ref.watch(currentUidProvider);
      final all = ref.watch(contributionsProvider(month)).value ??
          const <Contribution>[];
      return <Contribution>[
        for (final c in all)
          if (c.memberId == uid) c,
      ];
    });

final recordContributionProvider = Provider<RecordContribution>(
  (ref) => RecordContribution(
    contributions: ref.watch(contributionRepositoryProvider),
    funds: ref.watch(fundRepositoryProvider),
    families: ref.watch(familyRepositoryProvider),
    clock: ref.watch(clockProvider),
    newId: ref.watch(idGeneratorProvider),
    dateKeys: ref.watch(familyDateKeysProvider),
  ),
);

final requestContributionProvider = Provider<RequestContribution>(
  (ref) => RequestContribution(
    contributions: ref.watch(contributionRepositoryProvider),
    funds: ref.watch(fundRepositoryProvider),
    families: ref.watch(familyRepositoryProvider),
    clock: ref.watch(clockProvider),
    newId: ref.watch(idGeneratorProvider),
    dateKeys: ref.watch(familyDateKeysProvider),
  ),
);

final editPendingContributionProvider = Provider<EditPendingContribution>(
  (ref) => EditPendingContribution(
    contributions: ref.watch(contributionRepositoryProvider),
    funds: ref.watch(fundRepositoryProvider),
    families: ref.watch(familyRepositoryProvider),
    clock: ref.watch(clockProvider),
    newId: ref.watch(idGeneratorProvider),
    dateKeys: ref.watch(familyDateKeysProvider),
  ),
);

final cancelContributionRequestProvider = Provider<CancelContributionRequest>(
  (ref) => CancelContributionRequest(
    contributions: ref.watch(contributionRepositoryProvider),
    funds: ref.watch(fundRepositoryProvider),
    families: ref.watch(familyRepositoryProvider),
    clock: ref.watch(clockProvider),
    newId: ref.watch(idGeneratorProvider),
  ),
);

final approveContributionProvider = Provider<ApproveContribution>(
  (ref) => ApproveContribution(
    contributions: ref.watch(contributionRepositoryProvider),
    funds: ref.watch(fundRepositoryProvider),
    families: ref.watch(familyRepositoryProvider),
    clock: ref.watch(clockProvider),
    newId: ref.watch(idGeneratorProvider),
  ),
);

final rejectContributionProvider = Provider<RejectContribution>(
  (ref) => RejectContribution(
    contributions: ref.watch(contributionRepositoryProvider),
    funds: ref.watch(fundRepositoryProvider),
    families: ref.watch(familyRepositoryProvider),
    clock: ref.watch(clockProvider),
    newId: ref.watch(idGeneratorProvider),
  ),
);

final requestContributionChangeProvider = Provider<RequestContributionChange>(
  (ref) => RequestContributionChange(
    contributions: ref.watch(contributionRepositoryProvider),
    funds: ref.watch(fundRepositoryProvider),
    families: ref.watch(familyRepositoryProvider),
    clock: ref.watch(clockProvider),
    newId: ref.watch(idGeneratorProvider),
    dateKeys: ref.watch(familyDateKeysProvider),
  ),
);

final approveContributionChangeProvider = Provider<ApproveContributionChange>(
  (ref) => ApproveContributionChange(
    contributions: ref.watch(contributionRepositoryProvider),
    funds: ref.watch(fundRepositoryProvider),
    families: ref.watch(familyRepositoryProvider),
    clock: ref.watch(clockProvider),
    newId: ref.watch(idGeneratorProvider),
  ),
);

final rejectContributionChangeProvider = Provider<RejectContributionChange>(
  (ref) => RejectContributionChange(
    contributions: ref.watch(contributionRepositoryProvider),
    funds: ref.watch(fundRepositoryProvider),
    families: ref.watch(familyRepositoryProvider),
    clock: ref.watch(clockProvider),
    newId: ref.watch(idGeneratorProvider),
  ),
);

final voidContributionProvider = Provider<VoidContribution>(
  (ref) => VoidContribution(
    contributions: ref.watch(contributionRepositoryProvider),
    funds: ref.watch(fundRepositoryProvider),
    families: ref.watch(familyRepositoryProvider),
    clock: ref.watch(clockProvider),
    newId: ref.watch(idGeneratorProvider),
  ),
);

final setContributionPlanProvider = Provider<SetContributionPlan>(
  (ref) => SetContributionPlan(
    contributions: ref.watch(contributionRepositoryProvider),
    families: ref.watch(familyRepositoryProvider),
    clock: ref.watch(clockProvider),
    newId: ref.watch(idGeneratorProvider),
  ),
);

final generateMonthPlansProvider = Provider<GenerateMonthPlans>(
  (ref) => GenerateMonthPlans(
    contributions: ref.watch(contributionRepositoryProvider),
    settings: ref.watch(bazarSettingsRepositoryProvider),
    families: ref.watch(familyRepositoryProvider),
    clock: ref.watch(clockProvider),
    newId: ref.watch(idGeneratorProvider),
  ),
);

final recordOpeningBalanceProvider = Provider<RecordOpeningBalance>(
  (ref) => RecordOpeningBalance(
    contributions: ref.watch(contributionRepositoryProvider),
    settings: ref.watch(bazarSettingsRepositoryProvider),
    funds: ref.watch(fundRepositoryProvider),
    families: ref.watch(familyRepositoryProvider),
    clock: ref.watch(clockProvider),
    newId: ref.watch(idGeneratorProvider),
    dateKeys: ref.watch(familyDateKeysProvider),
  ),
);
