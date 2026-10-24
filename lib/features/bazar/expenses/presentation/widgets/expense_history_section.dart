import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:family_hub/core/localization/generated/app_localizations.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/core/utils/money.dart';
import 'package:family_hub/features/bazar/expenses/domain/expense_repository.dart';
import 'package:family_hub/features/bazar/expenses/presentation/expense_providers.dart';
import 'package:family_hub/features/bazar/presentation/bazar_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Who changed an expense and what each changed field used to be.
/// Shown only to people who may edit it (the rules match).
class ExpenseHistorySection extends ConsumerWidget {
  const ExpenseHistorySection({required this.expenseId, super.key});

  final String expenseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final t = context.tokens;
    final revisions = ref.watch(expenseRevisionsProvider(expenseId));
    final members = ref.watch(bazarMemberOptionsProvider);
    final formatters = ref.watch(appFormattersProvider);

    String who(String uid) {
      for (final m in members) {
        if (m.id == uid) return m.name;
      }
      return l10n.expenseUnknownMember;
    }

    String value(String field, Object? raw) {
      if (raw == null) return '—'; // i18n-exempt
      if (field == 'totalPaisa' || field == 'unitPricePaisa') {
        return raw is int ? formatters.money(Money.paisa(raw)) : '$raw';
      }
      if (field == 'fundingSource') {
        return raw == 'fund' ? l10n.expenseFundingFund : l10n.bazarFundingMember;
      }
      return '$raw';
    }

    final rows = revisions.value ?? const <ExpenseRevision>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.expenseHistoryTitle,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(color: t.textPrimary),
        ),
        const SizedBox(height: 8),
        if (revisions.hasError)
          Text(l10n.bazarErrNotAllowed)
        else if (rows.isEmpty)
          Text(
            l10n.expenseHistoryEmpty,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: t.textSecondary),
          ),
        for (final revision in rows)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.expenseHistoryEntry(
                    who(revision.by),
                    formatters.fullDate(revision.at.toLocal()),
                  ),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                for (final field in revision.changedFields)
                  if (field != 'monthKey')
                    Text(
                      l10n.expenseHistoryWas(
                        fieldLabel(l10n, field),
                        value(field, revision.before[field]),
                      ),
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: t.textSecondary),
                    ),
              ],
            ),
          ),
      ],
    );
  }
}

/// The localized name of an editable expense field.
String fieldLabel(AppLocalizations l10n, String field) => switch (field) {
  'dateKey' => l10n.expenseDateLabel,
  'itemId' || 'itemName' => l10n.expenseItemLabel,
  'categoryId' => l10n.expenseCategoryLabel,
  'qtyMilli' => l10n.expenseQtyField,
  'unit' => l10n.expenseUnitLabel,
  'unitPricePaisa' => l10n.expenseUnitPriceField,
  'totalPaisa' => l10n.expenseTotalLabel,
  'fundingSource' || 'paidByMemberId' || 'reimbursable' =>
    l10n.expenseFundingLabel,
  'purchaserId' => l10n.expensePurchaserLabel,
  'shop' => l10n.expenseShopField,
  'note' => l10n.expenseNoteField,
  _ => field,
};
