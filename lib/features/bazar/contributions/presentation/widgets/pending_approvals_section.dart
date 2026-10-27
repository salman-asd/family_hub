import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:family_hub/core/localization/generated/app_localizations.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/core/permissions/permissions.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/features/bazar/contributions/domain/contribution.dart';
import 'package:family_hub/features/bazar/contributions/presentation/contribution_providers.dart';
import 'package:family_hub/features/bazar/contributions/presentation/widgets/reject_reason_sheet.dart';
import 'package:family_hub/features/bazar/presentation/bazar_failure_messages.dart';
import 'package:family_hub/features/family/domain/member.dart';
import 'package:family_hub/features/family/presentation/family_providers.dart';
import 'package:family_hub/features/family/presentation/permission_providers.dart';
import 'package:family_hub/shared/widgets/money_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Requests a manager has to decide: new contributions and change requests.
///
/// `PermissionGate` owns the visibility (a plain member never sees it).  Each
/// row: member, amount (old -> new for a change), date and method, plus
/// Approve and Reject.  Reject always asks for a reason.  A decision needs the
/// server; offline it fails with the localized network message.
class PendingApprovalsSection extends ConsumerWidget {
  const PendingApprovalsSection({required this.month, super.key});

  final MonthKey month;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canRecord = ref.can(Permission.recordContribution);
    if (!canRecord) return const SizedBox.shrink();

    final l10n = context.l10n;
    final pending = ref.watch(pendingContributionsProvider(month));
    final members = ref.watch(membersProvider).value ?? const <Member>[];

    return Column(
      key: const ValueKey('pending-approvals'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.fundPendingTitle,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 4),
        if (pending.isEmpty)
          Text(
            l10n.fundPendingEmpty,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: context.tokens.textSecondary,
            ),
          ),
        for (final row in pending)
          _PendingRow(
            contribution: row,
            name: _nameOf(members, row.memberId),
            month: month,
          ),
      ],
    );
  }

  static String _nameOf(List<Member> members, String uid) {
    for (final member in members) {
      if (member.uid == uid) return member.displayName;
    }
    return uid;
  }
}

class _PendingRow extends ConsumerWidget {
  const _PendingRow({
    required this.contribution,
    required this.name,
    required this.month,
  });

  final Contribution contribution;
  final String name;
  final MonthKey month;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final t = context.tokens;
    final style = Theme.of(context).textTheme;
    final change = contribution.pendingChange;
    final familyId = ref.read(currentFamilyIdProvider) ?? '';
    final actor = ref.read(currentUidProvider) ?? '';

    final subtitle = contributionMethodLabel(
      l10n,
      change?.method ?? contribution.method,
    );

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: style.bodyLarge),
          const SizedBox(height: 2),
          Wrap(
            spacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (change == null)
                MoneyText(value: contribution.amount, hideZeroFraction: true)
              else ...[
                MoneyText(
                  value: contribution.amount,
                  hideZeroFraction: true,
                  style: style.bodySmall?.copyWith(color: t.textSecondary),
                ),
                const Icon(Icons.arrow_forward, size: 14),
                MoneyText(value: change.amount, hideZeroFraction: true),
              ],
              Text(
                '· ${contribution.dateKey} · $subtitle',
                style: style.bodySmall?.copyWith(color: t.textSecondary),
              ),
            ],
          ),
          Row(
            children: [
              TextButton.icon(
                key: const ValueKey('pending-approve'),
                icon: const Icon(Icons.check_rounded),
                label: Text(l10n.fundApprove),
                onPressed: () => _decide(context, ref, true, familyId, actor),
              ),
              TextButton.icon(
                key: const ValueKey('pending-reject'),
                icon: const Icon(Icons.close_rounded),
                label: Text(l10n.fundReject),
                onPressed: () => _decide(context, ref, false, familyId, actor),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _decide(
    BuildContext context,
    WidgetRef ref,
    bool approve,
    String familyId,
    String actor,
  ) async {
    final l10n = context.l10n;
    final change = contribution.pendingChange;
    final messenger = ScaffoldMessenger.of(context);

    if (approve) {
      await (change == null
          ? ref.read(approveContributionProvider)(
              actorUid: actor,
              familyId: familyId,
              contributionId: contribution.id,
            )
          : ref.read(approveContributionChangeProvider)(
              actorUid: actor,
              familyId: familyId,
              contributionId: contribution.id,
            ));
      return;
    }

    final reason = await showRejectReasonSheet(context);
    if (reason == null || !context.mounted) return;
    final result = change == null
        ? await ref.read(rejectContributionProvider)(
            actorUid: actor,
            familyId: familyId,
            contributionId: contribution.id,
            reason: reason,
          )
        : await ref.read(rejectContributionChangeProvider)(
            actorUid: actor,
            familyId: familyId,
            contributionId: contribution.id,
            reason: reason,
          );
    final failure = result.failureOrNull;
    if (failure != null) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.bazarFailureMessage(failure))),
      );
    }
  }
}

/// Localized name of a payment method; empty when none was given.
String contributionMethodLabel(
  AppLocalizations l10n,
  ContributionMethod? method,
) => switch (method) {
  null => '',
  ContributionMethod.cash => l10n.fundMethodCash,
  ContributionMethod.bkash => l10n.fundMethodBkash,
  ContributionMethod.nagad => l10n.fundMethodNagad,
  ContributionMethod.bank => l10n.fundMethodBank,
  ContributionMethod.other => l10n.fundMethodOther,
};
