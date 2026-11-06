import 'package:family_hub/core/localization/generated/app_localizations.dart';
import 'package:family_hub/core/notifications/domain/notification_type.dart';
import 'package:family_hub/features/notifications/domain/notification_delivery_settings.dart';
import 'package:family_hub/features/notifications/presentation/widgets/delivery_type_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('scheduled notification types are locked to Normal', (
    tester,
  ) async {
    final settings = NotificationDeliverySettings.defaults();
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: DeliveryTypeList(settings: settings, onChanged: (_) {}),
          ),
        ),
      ),
    );

    final type = find.text('Chore due');
    final card = find.ancestor(of: type, matching: find.byType(Card));
    final segmented = tester.widget<SegmentedButton<DeliveryMode>>(
      find.descendant(
        of: card,
        matching: find.byType(SegmentedButton<DeliveryMode>),
      ),
    );
    expect(segmented.selected, {DeliveryMode.normal});
    expect(segmented.segments.last.value, DeliveryMode.push);
    expect(segmented.segments.last.enabled, isFalse);
    expect(
      find.descendant(
        of: card,
        matching: find.text('Computed on each phone; no server event.'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('push-capable types keep an editable saved choice', (
    tester,
  ) async {
    final settings = NotificationDeliverySettings.defaults().copyWith(
      pushEnabled: true,
      modes: const {'comment_attention': DeliveryMode.push},
    );
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: DeliveryTypeList(
              settings: settings,
              pushMasterEnabled: true,
              onChanged: (_) {},
            ),
          ),
        ),
      ),
    );

    final card = find.ancestor(
      of: find.text('Comment needs attention'),
      matching: find.byType(Card),
    );
    final segmented = tester.widget<SegmentedButton<DeliveryMode>>(
      find.descendant(
        of: card,
        matching: find.byType(SegmentedButton<DeliveryMode>),
      ),
    );
    expect(segmented.selected, {DeliveryMode.push});
    expect(segmented.segments.last.enabled, isTrue);
  });

  testWidgets('push choice is marked inactive while the family master is off', (
    tester,
  ) async {
    final settings = NotificationDeliverySettings.defaults().copyWith(
      modes: const {'comment_attention': DeliveryMode.push},
    );
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: DeliveryTypeList(
              settings: settings,
              pushMasterEnabled: false,
              onChanged: (_) {},
            ),
          ),
        ),
      ),
    );

    final card = find.ancestor(
      of: find.text('Comment needs attention'),
      matching: find.byType(Card),
    );
    expect(
      find.descendant(
        of: card,
        matching: find.text(
          'Push is saved but will not be used until push delivery is enabled.',
        ),
      ),
      findsOneWidget,
    );
  });
}
