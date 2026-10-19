import 'package:family_hub/app/theme/theme_registry.dart';
import 'package:family_hub/shared/widgets/sync_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'shared_widgets_test_support.dart';

void main() {
  for (final locale in sharedWidgetLocales) {
    testWidgets('syncing state shows count and icon (${locale.languageCode})',
        (tester) async {
      await pumpSharedWidget(
        tester,
        child: const SyncBanner(pendingWrites: 3),
        spec: appThemes.first,
        locale: locale,
      );
      expect(find.byKey(const Key('sync_banner')), findsOneWidget);
      expect(find.byIcon(Icons.sync_rounded), findsOneWidget);
      expect(find.textContaining('3'), findsOneWidget);
    });

    testWidgets('offline state uses a different icon (${locale.languageCode})',
        (tester) async {
      await pumpSharedWidget(
        tester,
        child: const SyncBanner(pendingWrites: 5, offline: true),
        spec: appThemes.first,
        locale: locale,
      );
      expect(find.byIcon(Icons.cloud_off_rounded), findsOneWidget);
      expect(find.byIcon(Icons.sync_rounded), findsNothing);
    });
  }

  testWidgets('renders nothing when there is nothing pending', (tester) async {
    await pumpSharedWidget(
      tester,
      child: const SyncBanner(pendingWrites: 0),
      spec: appThemes.first,
      locale: const Locale('en'),
    );
    expect(find.byKey(const Key('sync_banner')), findsNothing);
  });
}
