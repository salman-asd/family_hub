import 'package:family_hub/app/theme/theme_registry.dart';
import 'package:family_hub/shared/widgets/reason_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'shared_widgets_test_support.dart';

/// P3-04: every Phase 3 flow (reassign, swap, reopen, skip, exception,
/// absence) collects its reason here, so the validation must be identical
/// everywhere (D-P3-17, CLAUDE.md rule 40).
void main() {
  /// Opens the sheet from a button and records the returned value.
  Future<List<String?>> open(
    WidgetTester tester, {
    bool required = true,
    String? initialText,
  }) async {
    final results = <String?>[];
    await pumpSharedWidget(
      tester,
      spec: appThemes.first,
      locale: const Locale('en'),
      child: Builder(
        builder: (context) => Center(
          child: ElevatedButton(
            onPressed: () async => results.add(
              await showReasonSheet(
                context,
                title: 'Why?',
                required: required,
                initialText: initialText,
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return results;
  }

  Finder saveButton() => find.widgetWithText(FilledButton, 'Save');

  bool saveEnabled(WidgetTester tester) =>
      tester.widget<FilledButton>(saveButton()).onPressed != null;

  testWidgets('2 characters are rejected, 3 are accepted', (tester) async {
    final results = await open(tester);

    await tester.enterText(find.byType(TextField), 'ab');
    await tester.pump();
    expect(saveEnabled(tester), isFalse, reason: '2 chars must not save');

    await tester.enterText(find.byType(TextField), 'abc');
    await tester.pump();
    expect(saveEnabled(tester), isTrue);

    await tester.tap(saveButton());
    await tester.pumpAndSettle();
    expect(results, ['abc']);
  });

  testWidgets('301 characters are capped at 300', (tester) async {
    final results = await open(tester);

    await tester.enterText(find.byType(TextField), 'x' * 301);
    await tester.pump();
    // maxLength truncates rather than rejecting: the user cannot paste past it.
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text.length, 300);

    await tester.tap(saveButton());
    await tester.pumpAndSettle();
    expect(results.single, hasLength(300));
  });

  testWidgets('the text is trimmed before it is returned', (tester) async {
    final results = await open(tester);
    await tester.enterText(find.byType(TextField), '   spilled tea   ');
    await tester.pump();
    await tester.tap(saveButton());
    await tester.pumpAndSettle();
    expect(results, ['spilled tea']);
  });

  testWidgets('whitespace only is not a reason', (tester) async {
    await open(tester);
    await tester.enterText(find.byType(TextField), '        ');
    await tester.pump();
    expect(saveEnabled(tester), isFalse);
  });

  testWidgets('cancel returns null', (tester) async {
    final results = await open(tester);
    await tester.enterText(find.byType(TextField), 'a valid reason');
    await tester.pump();
    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pumpAndSettle();
    expect(results, [null]);
  });

  testWidgets('an optional reason accepts an empty field', (tester) async {
    final results = await open(tester, required: false);
    expect(saveEnabled(tester), isTrue);
    await tester.tap(saveButton());
    await tester.pumpAndSettle();
    expect(results, ['']);
  });

  testWidgets('the too-short hint appears once the user types', (tester) async {
    await open(tester);
    expect(find.text('Write at least 3 characters.'), findsNothing);
    await tester.enterText(find.byType(TextField), 'ab');
    await tester.pump();
    expect(find.text('Write at least 3 characters.'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'abc');
    await tester.pump();
    expect(find.text('Write at least 3 characters.'), findsNothing);
  });

  testWidgets('the sheet fits a narrow screen at 200 % text', (tester) async {
    await pumpSharedWidget(
      tester,
      spec: appThemes.first,
      locale: const Locale('bn'),
      textScale: 2.0,
      child: Builder(
        builder: (context) => Center(
          child: ElevatedButton(
            onPressed: () => showReasonSheet(context, title: 'কেন?'),
            child: const Text('খুলুন'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('খুলুন'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(TextField), findsOneWidget);
  });
}
