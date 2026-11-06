import 'package:family_hub/app/theme/theme_registry.dart';
import 'package:family_hub/shared/widgets/amount_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'shared_widgets_test_support.dart';

/// Behaviour of [AmountField]: both digit scripts, the scale limit and the
/// money prefix. Parsing itself is tested where it lives (`Money` / `Quantity`).
void main() {
  setUpAll(loadBundledFonts);

  Future<void> pumpField(WidgetTester tester, AmountField field) =>
      pumpSharedWidget(
        tester,
        child: field,
        spec: defaultLightSpec,
        locale: const Locale('bn'),
      );

  testWidgets('accepts Bangla digits and one decimal separator', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    final changes = <String>[];

    await pumpField(
      tester,
      AmountField(
        controller: controller,
        label: 'Amount',
        onChanged: changes.add,
      ),
    );
    await tester.enterText(find.byType(TextField), '১২৩.৫০');
    await tester.pump();

    expect(controller.text, '১২৩.৫০');
    expect(changes, ['১২৩.৫০']);
  });

  testWidgets('rejects invalid edits without changing the prior value', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await pumpField(
      tester,
      AmountField(controller: controller, label: 'Amount'),
    );

    await tester.enterText(find.byType(TextField), '12');
    await tester.pump();
    expect(controller.text, '12');

    await tester.enterText(find.byType(TextField), '12a');
    await tester.pump();
    expect(controller.text, '12');

    await tester.enterText(find.byType(TextField), '12.3');
    await tester.pump();
    expect(controller.text, '12.3');
    await tester.enterText(find.byType(TextField), '12.3.4');
    await tester.pump();
    expect(controller.text, '12.3');
    await tester.enterText(find.byType(TextField), '12.345');
    await tester.pump();
    expect(controller.text, '12.3');
  });

  testWidgets('scale 3 keeps three decimals and shows no money prefix', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await pumpField(
      tester,
      AmountField(controller: controller, label: 'Quantity', scale: 3),
    );
    await tester.enterText(find.byType(TextField), '1.234');
    await tester.pump();
    expect(controller.text, '1.234');
    await tester.enterText(find.byType(TextField), '1.2345');
    await tester.pump();
    expect(controller.text, '1.234');
    expect(find.textContaining('৳'), findsNothing);
  });

  testWidgets('a money field shows the taka prefix', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await pumpField(
      tester,
      AmountField(controller: controller, label: 'Amount'),
    );

    expect(find.textContaining('৳'), findsOneWidget);
  });

  testWidgets('renders an error and a disabled state', (tester) async {
    final controller = TextEditingController(text: '0');
    addTearDown(controller.dispose);

    await pumpField(
      tester,
      AmountField(
        controller: controller,
        label: 'Amount',
        errorText: 'The amount must be greater than zero',
      ),
    );
    expect(find.text('The amount must be greater than zero'), findsOneWidget);

    await pumpField(
      tester,
      AmountField(controller: controller, label: 'Amount', enabled: false),
    );
    expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);
  });

  test('the formatter rejects edits with too many decimals', () {
    const two = AmountInputFormatter(2);
    final value = two.formatEditUpdate(
      TextEditingValue.empty,
      const TextEditingValue(text: '১০.৫০০'),
    );
    expect(value, TextEditingValue.empty);

    const three = AmountInputFormatter(3);
    expect(
      three.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(text: '2.5000'),
      ),
      TextEditingValue.empty,
    );
  });
}
