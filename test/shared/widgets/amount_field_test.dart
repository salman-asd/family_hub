import 'package:family_hub/app/theme/theme_registry.dart';
import 'package:family_hub/shared/widgets/amount_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'shared_widgets_test_support.dart';

/// Behaviour of the P2-12 [AmountField]: both digit scripts, one decimal
/// separator, the scale limit and the money prefix.  Parsing itself is tested
/// where it lives (`Money` / `Quantity`).
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

  testWidgets('drops letters, a second separator and extra decimals', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await pumpField(
      tester,
      AmountField(controller: controller, label: 'Amount'),
    );

    await tester.enterText(find.byType(TextField), '12a3.456');
    await tester.pump();
    expect(controller.text, '123.45');

    await tester.enterText(find.byType(TextField), '1.2.3');
    await tester.pump();
    expect(controller.text, '1.23');

    await tester.enterText(find.byType(TextField), '৳১২');
    await tester.pump();
    expect(controller.text, '১২');
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
    await tester.enterText(find.byType(TextField), '1.2345');
    await tester.pump();

    expect(controller.text, '1.234');
    expect(find.text(AmountField.moneyPrefix), findsNothing);
  });

  testWidgets('a money field shows the taka prefix', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await pumpField(
      tester,
      AmountField(controller: controller, label: 'Amount'),
    );

    expect(find.text(AmountField.moneyPrefix), findsOneWidget);
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

  test('the formatter clamps decimals to its scale', () {
    const two = AmountInputFormatter(scale: 2);
    final value = two.formatEditUpdate(
      TextEditingValue.empty,
      const TextEditingValue(text: '১০.৫০০'),
    );
    expect(value.text, '১০.৫০');

    const three = AmountInputFormatter(scale: 3);
    expect(
      three
          .formatEditUpdate(
            TextEditingValue.empty,
            const TextEditingValue(text: '2.5000'),
          )
          .text,
      '2.500',
    );
  });
}
