import 'package:family_hub/app/app.dart';
import 'package:family_hub/app/flavor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final flavor in Flavor.values) {
    testWidgets('shows ${flavor.name} flavor name', (tester) async {
      await tester.pumpWidget(FamilyHubApp(flavor: flavor));
      expect(find.text(flavor.name), findsOneWidget);
      expect(find.text(flavor.label), findsOneWidget);
    });
  }

  test('dev label differs from prod label', () {
    expect(Flavor.dev.label, 'Family Hub (dev)');
    expect(Flavor.prod.label, 'Family Hub');
  });
}
