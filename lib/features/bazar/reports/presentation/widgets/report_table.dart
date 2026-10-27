import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:family_hub/core/utils/money.dart';
import 'package:family_hub/shared/widgets/app_card.dart';
import 'package:family_hub/shared/widgets/money_text.dart';
import 'package:flutter/material.dart';

/// One row of a [ReportTable]: a label, an amount and an optional note.
final class ReportRow {
  const ReportRow({
    required this.key,
    required this.label,
    required this.amount,
    this.trailing,
  });

  /// Stable key (`ValueKey` for tests and list identity).
  final String key;
  final String label;
  final Money amount;

  /// Extra text after the amount (a share, a count, "12 %" ...).
  final String? trailing;
}

/// A two-column table of report rows, scrollable HORIZONTALLY.
///
/// Tables are the accessible content (the charts are decoration), and a wide
/// Bangla row at 2.0 text scale scrolls instead of overflowing (rule 13).
class ReportTable extends StatelessWidget {
  const ReportTable({
    required this.rows,
    required this.emptyLabel,
    required this.nameHeader,
    required this.amountHeader,
    this.totalLabel,
    super.key,
  });

  final List<ReportRow> rows;

  /// Shown instead of the rows when there is nothing to list.
  final String emptyLabel;

  /// Localized header of the label column ("Category", "Item", "Day" ...).
  final String nameHeader;

  /// Localized header of the amount column ("Amount", "Spent" ...).
  final String amountHeader;

  /// When set, a final, emphasised row with the sum of [rows].
  final String? totalLabel;

  @override
  Widget build(BuildContext context) {
    final l10nTheme = Theme.of(context);
    final t = context.tokens;
    if (rows.isEmpty) {
      return AppCard(
        child: Text(
          emptyLabel,
          style: l10nTheme.textTheme.bodyMedium?.copyWith(
            color: t.textSecondary,
          ),
        ),
      );
    }

    final total = Money.sum(rows.map((r) => r.amount));
    return AppCard(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: MediaQuery.sizeOf(context).width - 64,
          ),
          child: DataTable(
            key: const ValueKey('report-table'),
            columnSpacing: 24,
            headingRowHeight: 36,
            showCheckboxColumn: false,
            columns: <DataColumn>[
              DataColumn(label: Text(nameHeader)),
              DataColumn(label: Text(amountHeader), numeric: true),
            ],
            rows: <DataRow>[
              for (final row in rows)
                DataRow(
                  key: ValueKey('report-row-${row.key}'),
                  cells: <DataCell>[
                    DataCell(
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 180),
                        child: Text(
                          row.label,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: MoneyText(
                              value: row.amount,
                              hideZeroFraction: true,
                              style: l10nTheme.textTheme.bodyMedium,
                            ),
                          ),
                          if (row.trailing case final trailing?)
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Text(
                                trailing,
                                style: l10nTheme.textTheme.bodySmall?.copyWith(
                                  color: t.textSecondary,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              if (totalLabel != null)
                DataRow(
                  key: const ValueKey('report-row-total'),
                  cells: <DataCell>[
                    DataCell(
                      Text(
                        totalLabel!,
                        style: l10nTheme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    DataCell(
                      MoneyText(
                        value: total,
                        hideZeroFraction: true,
                        style: l10nTheme.textTheme.titleSmall,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
