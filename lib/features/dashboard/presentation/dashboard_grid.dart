import 'package:family_hub/features/dashboard/domain/card_catalog.dart';
import 'package:family_hub/features/dashboard/presentation/resolved_dashboard_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DashboardGrid extends ConsumerWidget {
  const DashboardGrid({
    required this.cards,
    required this.twoColumns,
    super.key,
  });

  final List<ResolvedDashboardCard> cards;
  final bool twoColumns;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rows = _dashboardRows(cards, twoColumns);
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final row = rows[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var cardIndex = 0; cardIndex < row.length; cardIndex++) ...[
                if (cardIndex > 0) const SizedBox(width: 12),
                Expanded(child: row[cardIndex].spec.builder(context, ref)),
              ],
              if (twoColumns && row.length == 1 && _isHalf(row.single))
                const Expanded(child: SizedBox.shrink()),
            ],
          ),
        );
      }, childCount: rows.length),
    );
  }

  static List<List<ResolvedDashboardCard>> _dashboardRows(
    List<ResolvedDashboardCard> cards,
    bool twoColumns,
  ) {
    if (!twoColumns) {
      return <List<ResolvedDashboardCard>>[
        for (final card in cards) <ResolvedDashboardCard>[card],
      ];
    }

    final rows = <List<ResolvedDashboardCard>>[];
    var index = 0;
    while (index < cards.length) {
      final current = cards[index];
      if (_isHalf(current) &&
          index + 1 < cards.length &&
          _isHalf(cards[index + 1])) {
        rows.add(<ResolvedDashboardCard>[current, cards[index + 1]]);
        index += 2;
      } else {
        rows.add(<ResolvedDashboardCard>[current]);
        index++;
      }
    }
    return rows;
  }

  static bool _isHalf(ResolvedDashboardCard card) =>
      card.resolved.definition.size == DashboardCardSize.half;
}
