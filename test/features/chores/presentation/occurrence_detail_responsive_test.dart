import 'package:family_hub/app/theme/theme_builder.dart';
import 'package:family_hub/app/theme/theme_registry.dart';
import 'package:family_hub/core/localization/app_formatters.dart';
import 'package:family_hub/core/localization/generated/app_localizations.dart';
import 'package:family_hub/features/chores/occurrences/domain/chore_item.dart';
import 'package:family_hub/features/chores/presentation/widgets/occurrence_detail_body.dart';
import 'package:family_hub/features/family/presentation/family_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../achievements/presentation/engagement_ui_test_support.dart';
import '../calendar/calendar_test_support.dart';
import '../chores_test_helpers.dart';

/// P4-24: on a wide window the thread (comments + history) gets its own pane
/// beside the chore itself.
void main() {
  const formatters = AppFormatters(languageCode: 'en', useBanglaDigits: false);

  Future<void> pumpDetail(WidgetTester tester, Size size) async {
    tester.view
      ..physicalSize = size
      ..devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final occurrence = anOccurrence(instructions: 'Rinse the cups too');
    final item = ChoreItem.fromOccurrence(occurrence);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          membersProvider.overrideWith(
            (ref) => Stream.value(engagementTestMembers()),
          ),
        ],
        child: MaterialApp(
          theme: buildThemeData(appThemes.first),
          locale: const Locale('en'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: OccurrenceDetailBody(
              item: item,
              occurrence: occurrence,
              events: const [],
              formatters: formatters,
              today: kToday,
              busy: false,
              onToggleParent: () {},
              onToggleSubtask: (_) {},
              comments: const Text('Comment thread'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final (size, expanded) in const <(Size, bool)>[
    (Size(360, 780), false),
    (Size(600, 900), false),
    (Size(840, 1024), true),
    (Size(1024, 768), true),
  ]) {
    testWidgets('layout at ${size.width} dp', (tester) async {
      await pumpDetail(tester, size);
      expect(tester.takeException(), isNull);
      expect(find.text('Comment thread'), findsOneWidget);
      final threadX = tester.getTopLeft(find.text('Comment thread')).dx;
      if (expanded) {
        expect(threadX, greaterThan(size.width / 2));
      } else {
        expect(threadX, lessThan(60));
      }
    });
  }
}
