import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/core/permissions/permissions.dart';
import 'package:family_hub/features/bazar/advances/domain/advance_grouping.dart';
import 'package:family_hub/features/bazar/advances/domain/advance_summary.dart';
import 'package:family_hub/features/bazar/advances/domain/member_advance.dart';
import 'package:family_hub/features/bazar/advances/presentation/advance_providers.dart';
import 'package:family_hub/features/bazar/advances/presentation/widgets/advance_group_list.dart';
import 'package:family_hub/features/bazar/advances/presentation/widgets/settle_advance_sheet.dart';
import 'package:family_hub/features/family/domain/member.dart';
import 'package:family_hub/features/family/presentation/family_providers.dart';
import 'package:family_hub/features/family/presentation/permission_providers.dart';
import 'package:family_hub/shared/widgets/app_card.dart';
import 'package:family_hub/shared/widgets/empty_state.dart';
import 'package:family_hub/shared/widgets/loading_view.dart';
import 'package:family_hub/shared/widgets/money_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Open member advances grouped by member (`/bazar/advances`).
///
/// A manager sees everyone and may settle; a plain member sees only their own
/// rows (the provider narrows to their uid, because the rules only allow their
/// own).  Settling a row updates the fund balance and the expense detail at
/// once, because all three read the same ledger.
class AdvancesScreen extends ConsumerStatefulWidget {
  const AdvancesScreen({super.key});

  @override
  ConsumerState<AdvancesScreen> createState() => _AdvancesScreenState();
}

class _AdvancesScreenState extends ConsumerState<AdvancesScreen> {
  bool _showSettled = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final advances = ref.watch(openAdvancesProvider);
    final canSettle = ref.can(Permission.recordContribution);
    final members = ref.watch(membersProvider).value ?? const <Member>[];
    final summary = ref.watch(advanceSummaryProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.advanceTitle)),
      body: advances.when(
        loading: () => const LoadingView(lines: 5),
        error: (_, _) => EmptyState(
          icon: Icons.cloud_off_outlined,
          title: l10n.errorNetwork,
          actionLabel: l10n.actionRetry,
          onAction: () => ref.invalidate(openAdvancesProvider),
        ),
        data: (rows) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(openAdvancesProvider),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _Total(summary: summary, showSettled: _showSettled),
              const SizedBox(height: 8),
              FilterChip(
                key: const ValueKey('advances-settled-filter'),
                label: Text(l10n.advanceShowSettled),
                selected: _showSettled,
                onSelected: (value) => setState(() => _showSettled = value),
              ),
              if (rows.isEmpty)
                EmptyState(
                  icon: Icons.account_balance_wallet_outlined,
                  title: l10n.advanceEmptyTitle,
                  message: l10n.advanceEmptyMessage,
                )
              else
                for (final group in groupAdvances(
                  rows,
                  includeSettled: _showSettled,
                ))
                  AdvanceGroupList(
                    key: ValueKey('advance-group-${group.memberId}'),
                    group: group,
                    name: _nameOf(members, group.memberId),
                    canSettle: canSettle,
                    showSettled: _showSettled,
                    onSettle: (advance) => _settle(advance),
                  ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _settle(MemberAdvance advance) async {
    final saved = await showSettleAdvanceSheet(context, advance);
    if (saved && mounted) ref.invalidate(openAdvancesProvider);
  }

  static String _nameOf(List<Member> members, String uid) {
    for (final member in members) {
      if (member.uid == uid) return member.displayName;
    }
    return uid;
  }
}

class _Total extends StatelessWidget {
  const _Total({required this.summary, required this.showSettled});

  final AdvanceSummary summary;
  final bool showSettled;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final style = Theme.of(context).textTheme;
    return AppCard(
      child: Row(
        children: [
          Expanded(
            child: Text(
              showSettled ? l10n.advanceTotalOwed : l10n.advanceOpenCount(
                summary.openCount,
              ),
              style: style.titleSmall,
            ),
          ),
          if (!showSettled)
            MoneyText(
              key: const ValueKey('advances-total'),
              value: summary.totalOwed,
              style: style.titleMedium,
            ),
        ],
      ),
    );
  }
}


