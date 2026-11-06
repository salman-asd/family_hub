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

  // P4-24: `home_screen.dart` turns this on for an expanded window.
  testWidgets('two columns place the cards side by side', (tester) async {
    // The grid only pairs cards the catalog marks as half-width.
    final halves = [
      CardCatalog.find('chores_overdue')!,
      CardCatalog.find('chores_verify')!,
    ];
    final cards = <ResolvedDashboardCard>[
      for (var index = 0; index < 4; index++)
        ResolvedDashboardCard(
          resolved: ResolvedCard(
            definition: halves[index % 2],
            access: CardAccess.on,
            canHide: true,
          ),
          spec: DashboardCardSpec<DashboardCardBuilder>(
            id: halves[index % 2].id,
            builder: (_, _) =>
                SizedBox(key: ValueKey('card_$index'), height: 100),
          ),
        ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 600,
              child: CustomScrollView(
                slivers: [DashboardGrid(cards: cards, twoColumns: true)],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    Offset top(int index) =>
        tester.getTopLeft(find.byKey(ValueKey('card_$index')));
    // Cards 0 and 1 share a row, card 2 starts the next one.
    expect(top(0).dy, top(1).dy);
    expect(top(0).dx, lessThan(top(1).dx));
    expect(top(2).dy, greaterThan(top(1).dy));
  });
}
