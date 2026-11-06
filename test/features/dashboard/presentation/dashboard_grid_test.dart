import 'package:family_hub/features/dashboard/domain/card_access.dart';
import 'package:family_hub/features/dashboard/domain/card_catalog.dart';
import 'package:family_hub/features/dashboard/domain/dashboard_card_spec.dart';
import 'package:family_hub/features/dashboard/domain/dashboard_resolver.dart';
import 'package:family_hub/features/dashboard/presentation/dashboard_grid.dart';
import 'package:family_hub/features/dashboard/presentation/resolved_dashboard_card.dart';
import 'package:family_hub/modules/family_module.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('dashboard grid lazily builds off-screen cards', (tester) async {
    var builtCards = 0;
    final catalogCard = CardCatalog.find('chores_today')!;
    final cards = <ResolvedDashboardCard>[
      for (var index = 0; index < 20; index++)
        ResolvedDashboardCard(
          resolved: ResolvedCard(
            definition: catalogCard,
            access: CardAccess.on,
            canHide: true,
          ),
          spec: DashboardCardSpec<DashboardCardBuilder>(
            id: catalogCard.id,
            builder: (_, _) {
              builtCards++;
              return const SizedBox(height: 100);
            },
          ),
        ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: CustomScrollView(
              slivers: [DashboardGrid(cards: cards, twoColumns: false)],
            ),
          ),
        ),
      ),
    );

    expect(builtCards, lessThan(cards.length));
    expect(tester.takeException(), isNull);
  });
}
