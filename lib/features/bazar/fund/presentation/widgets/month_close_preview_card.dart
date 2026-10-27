import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/features/bazar/fund/presentation/fund_providers.dart';
import 'package:family_hub/features/bazar/fund/presentation/widgets/fund_balance_card.dart';
import 'package:family_hub/shared/widgets/app_card.dart';
import 'package:family_hub/shared/widgets/money_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The month-close preview: what the closing will record, plus the facts a
/// manager should see first (open advances, expected vs received).
///
/// Everything is derived (`monthClosePreviewProvider`), so it cannot disagree
/// with what `CloseMonth` will write.
class MonthClosePreviewCard extends ConsumerWidget {
  const MonthClosePreviewCard({required this.month, super.key});

  final MonthKey month;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final style = Theme.of(context).textTheme;
    final preview = ref.watch(monthClosePreviewProvider(month));

    return Column(
      children: [
        FundBalanceCard(
          summary: preview.summary,
          closedLabel: l10n.monthCloseWillRecord,
        ),
        const SizedBox(height: 8),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Line(
                label: l10n.monthCloseAdvances,
                value: Text(
                  '${preview.openAdvances}',
                  key: const ValueKey('close-open-advances'),
                  style: style.bodyMedium,
                ),
              ),
              _Line(
                label: l10n.monthCloseExpected,
                value: MoneyText(value: preview.expected, hideZeroFraction: true),
              ),
              _Line(
                label: l10n.monthCloseReceived,
                value: MoneyText(value: preview.received, hideZeroFraction: true),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.label, required this.value});

  final String label;
  final Widget value;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style.bodyMedium)),
          value,
        ],
      ),
    );
  }
}


