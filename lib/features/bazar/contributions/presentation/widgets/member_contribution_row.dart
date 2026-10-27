import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/features/bazar/contributions/domain/contribution_status.dart';
import 'package:family_hub/shared/widgets/app_avatar.dart';
import 'package:family_hub/shared/widgets/money_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One member's line on the Fund screen: received / expected, what is left (or
/// the credit), and "৳X awaiting approval" while a request waits.
///
/// Every member sees every member's row (D-P2-5).  The actions are the
/// caller's business and arrive as [trailing], so this widget stays plain.
class MemberContributionRow extends ConsumerWidget {
  const MemberContributionRow({
    required this.id,
    required this.name,
    required this.status,
    this.avatarKey,
    this.trailing,
    super.key,
  });

  /// The member's uid (also seeds the avatar colour).
  final String id;
  final String name;
  final MemberContributionStatus status;
  final String? avatarKey;
  final Widget? trailing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final t = context.tokens;
    final style = Theme.of(context).textTheme;
    final muted = style.bodySmall?.copyWith(color: t.textSecondary);
    final formatters = ref.watch(appFormattersProvider);
    String money(Money value) => formatters.money(value, hideZeroFraction: true);

    final String detail;
    if (status.expected.isZero && status.received.isZero) {
      detail = l10n.fundNoPlan;
    } else if (!status.credit.isZero) {
      detail = l10n.fundCredit(money(status.credit));
    } else if (status.remaining.isZero) {
      detail = l10n.fundPaidUp;
    } else {
      detail = l10n.fundRemainingAmount(money(status.remaining));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          AppAvatar(id: id, name: name, avatarKey: avatarKey, size: 34),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: style.bodyLarge),
                const SizedBox(height: 2),
                Wrap(
                  spacing: 4,
                  runSpacing: 2,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    MoneyText(
                      value: status.received,
                      hideZeroFraction: true,
                      style: muted,
                    ),
                    Text('/ ${money(status.expected)}', style: muted),
                    Text('· $detail', style: muted),
                  ],
                ),
                if (!status.pendingTotal.isZero)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 14,
                          color: t.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            l10n.fundAwaitingApproval(
                              money(status.pendingTotal),
                            ),
                            style: muted,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
