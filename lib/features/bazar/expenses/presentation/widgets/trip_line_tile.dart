import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/core/localization/unit_labels.dart';
import 'package:family_hub/features/bazar/expenses/presentation/controllers/trip_form_controller.dart';
import 'package:family_hub/shared/widgets/money_text.dart';
import 'package:flutter/material.dart';

/// One line of a trip: swipe to remove, or use the remove button (a swipe is
/// not reachable with a screen reader).  Tap to edit.
class TripLineTile extends StatelessWidget {
  const TripLineTile({
    required this.line,
    required this.onTap,
    required this.onRemove,
    super.key,
  });

  final TripLineDraft line;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final t = context.tokens;
    final qty = line.qty;
    final unit = line.unit;
    final detail = qty == null || unit == null
        ? null
        : '${qty.toDecimalString()} ${l10n.unitLabel(unit)}';
    return Dismissible(
      key: ValueKey('dismiss-${line.id}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onRemove(),
      background: Container(
        color: t.danger,
        alignment: AlignmentDirectional.centerEnd,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Icon(Icons.delete_outline, color: t.textOnAccent),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        minTileHeight: 56,
        onTap: onTap,
        title: Text(line.itemName, maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: detail == null ? null : Text(detail),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            MoneyText(value: line.total, style: Theme.of(context).textTheme.titleSmall),
            IconButton(
              key: ValueKey('remove-${line.id}'),
              tooltip: l10n.actionDelete,
              icon: const Icon(Icons.close),
              onPressed: onRemove,
            ),
          ],
        ),
      ),
    );
  }
}
