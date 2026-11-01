import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/features/chores/occurrences/domain/occurrence_status.dart';
import 'package:family_hub/features/chores/presentation/widgets/chore_tile.dart'
    show statusLabelOf, widgetStatusOf;
import 'package:family_hub/shared/widgets/status_glyph.dart';
import 'package:flutter/material.dart';

/// "What the symbols mean": every status shape with its name (B.7).
Future<void> showLegendSheet(BuildContext context) => showModalBottomSheet<void>(
  context: context,
  showDragHandle: true,
  builder: (context) => const LegendSheet(),
);

class LegendSheet extends StatelessWidget {
  const LegendSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              header: true,
              child: Text(
                l10n.calendarLegend,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 8),
            for (final status in ChoreStatus.values)
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: Row(
                  children: [
                    StatusGlyph(status: widgetStatusOf(status), size: 18),
                    const SizedBox(width: 12),
                    Expanded(child: Text(statusLabelOf(status, l10n))),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
