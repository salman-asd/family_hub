import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/core/permissions/permissions.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/features/bazar/contributions/presentation/controllers/contribution_form_state.dart';
import 'package:family_hub/features/bazar/contributions/presentation/widgets/record_contribution_sheet.dart';
import 'package:family_hub/features/bazar/fund/presentation/widgets/contribute_button.dart';
import 'package:family_hub/features/bazar/fund/presentation/widgets/fund_body.dart';
import 'package:family_hub/features/bazar/presentation/bazar_providers.dart';
import 'package:family_hub/features/bazar/settings/presentation/bazar_settings_providers.dart';
import 'package:family_hub/features/family/presentation/permission_providers.dart';
import 'package:family_hub/shared/widgets/empty_state.dart';
import 'package:family_hub/shared/widgets/month_switcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The family fund (`/bazar/fund`): the balance, who has paid what, and the
/// month's ledger.
///
/// Everyone sees every member's row (D-P2-5) and may ask to contribute; only
/// people with `recordContribution` record money directly, approve requests and
/// see the integrity banners.  The balance is the ledger sum (ADR 0007), so a
/// new expense, a settlement or a month close moves it without a refresh.
class FundScreen extends ConsumerWidget {
  const FundScreen({super.key, this.focusPendingApprovals = false});

  final bool focusPendingApprovals;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final month = ref.watch(selectedMonthProvider);
    final configured = ref.watch(
      bazarSettingsProvider.select((s) => s.fundStartMonth),
    );
    final canRecord = ref.can(Permission.recordContribution);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.fundTitle)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: MonthSwitcher(
              month: month,
              onChanged: ref.read(selectedMonthProvider.notifier).set,
            ),
          ),
          Expanded(
            child: configured == null && canRecord
                ? _SetupFund(month: month)
                : FundBody(
                    month: month,
                    canRecord: canRecord,
                    focusPendingApprovals: focusPendingApprovals,
                  ),
          ),
        ],
      ),
      floatingActionButton: ContributeButton(month: month),
    );
  }
}

/// "Set up the fund" until `settings/bazar.fundStartMonth` exists.
class _SetupFund extends StatelessWidget {
  const _SetupFund({required this.month});

  final MonthKey month;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        EmptyState(
          icon: Icons.account_balance_wallet_outlined,
          title: l10n.fundSetupTitle,
          message: l10n.fundSetupMessage,
          actionLabel: l10n.fundOpeningBalance,
          onAction: () => showContributionSheet(
            context,
            ContributionFormMode.record,
            month: month,
            openingBalance: true,
          ),
        ),
      ],
    );
  }
}
