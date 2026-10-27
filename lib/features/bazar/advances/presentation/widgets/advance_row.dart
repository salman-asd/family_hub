import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/features/bazar/advances/domain/member_advance.dart';
import 'package:family_hub/features/bazar/advances/presentation/advance_providers.dart';
import 'package:family_hub/features/family/presentation/family_providers.dart';
import 'package:family_hub/shared/widgets/money_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// One open advance: expense name + date, amount, settled, remaining, and a
/// status chip (icon + word, never colour alone).
///
/// Tapping the row opens the expense; the settle action is shown only to
/// someone who may record contributions.
class AdvanceRow extends ConsumerWidget {
  const AdvanceRow({
    required this.advance,
    required this.canSettle,
    required this.onSettle,
    super.key,
  });

  final MemberAdvance advance;
  final bool canSettle;
  final VoidCallback onSettle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final t = context.tokens;
    final style = Theme.of(context).textTheme;
    final familyId = ref.watch(currentFamilyIdProvider);
    final name = familyId == null
        ? null
        : ref
              .watch(advanceExpenseNameProvider((
                familyId: familyId,
                expenseId: advance.expenseId,
              )))
              .value;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: () => context.push('/bazar/expenses/${advance.expenseId}'),
      title: Text(
        name == null || name.isEmpty ? advance.expenseId : name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(advance.dateKey.toString(), style: style.bodySmall),
          const SizedBox(height: 2),
          Wrap(
            spacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _statusChip(context, advance),
              Text('${l10n.advanceSettledOf}: ', style: style.bodySmall),
              MoneyText(
                value: advance.settled,
                hideZeroFraction: true,
                style: style.bodySmall,
              ),
              Text('· ${l10n.advanceRemaining}: ', style: style.bodySmall),
              MoneyText(
                key: ValueKey('advance-remaining-${advance.expenseId}'),
                value: advance.remaining,
                hideZeroFraction: true,
                style: style.bodySmall?.copyWith(color: t.danger),
              ),
            ],
          ),
        ],
      ),
      trailing: canSettle && advance.status != AdvanceStatus.settled
          ? IconButton(
              key: ValueKey('advance-settle-${advance.expenseId}'),
              tooltip: l10n.advanceSettleAction,
              icon: const Icon(Icons.price_check_outlined),
              onPressed: onSettle,
            )
          : null,
    );
  }

  static Widget _statusChip(BuildContext context, MemberAdvance advance) {
    final l10n = context.l10n;
    final t = context.tokens;
    final (icon, label, color) = switch (advance.status) {
      AdvanceStatus.pending => (
        Icons.schedule_rounded,
        l10n.bazarAdvancePending,
        t.statusScheduledContainer,
      ),
      AdvanceStatus.partial => (
        Icons.timelapse_rounded,
        l10n.bazarAdvancePartial,
        t.statusInProgressContainer,
      ),
      AdvanceStatus.settled => (
        Icons.check_circle_outline_rounded,
        l10n.bazarAdvanceSettled,
        t.statusCompletedContainer,
      ),
      AdvanceStatus.voided => (
        Icons.block_outlined,
        l10n.bazarAdvanceVoided,
        t.statusOverdueContainer,
      ),
    };
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: context.tokens.textSecondary),
          const SizedBox(width: 4),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}


