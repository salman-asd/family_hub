import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/core/utils/money.dart';
import 'package:family_hub/shared/widgets/money_text.dart';
import 'package:flutter/material.dart';

/// "Looks like a duplicate": a non-blocking confirmation.  Resolves to `true`
/// for "Save anyway" and `false` for cancel or a dismissed sheet.
Future<bool> showDuplicateWarningSheet(
  BuildContext context, {
  required String itemName,
  required Money amount,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) =>
        _DuplicateSheet(itemName: itemName, amount: amount),
  );
  return result ?? false;
}

class _DuplicateSheet extends StatelessWidget {
  const _DuplicateSheet({required this.itemName, required this.amount});

  final String itemName;
  final Money amount;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final t = context.tokens;
    final theme = Theme.of(context).textTheme;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.copy_all_outlined, color: t.warning),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.expenseDuplicateTitle,
                    style: theme.titleMedium?.copyWith(color: t.textPrimary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              l10n.expenseDuplicateMessage(itemName),
              style: theme.bodyMedium?.copyWith(color: t.textSecondary),
            ),
            const SizedBox(height: 8),
            MoneyText(
              value: amount,
              style: theme.titleLarge?.copyWith(color: t.textPrimary),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                key: const ValueKey('duplicate-save-anyway'),
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(l10n.expenseDuplicateSaveAnyway),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton(
                key: const ValueKey('duplicate-cancel'),
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(l10n.actionCancel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
