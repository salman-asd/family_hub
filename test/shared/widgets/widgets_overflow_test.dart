import 'package:family_hub/app/gallery/gallery_sections.dart';
import 'package:family_hub/app/theme/theme_registry.dart';
import 'package:family_hub/core/localization/generated/app_localizations.dart';
import 'package:family_hub/core/utils/money.dart';
import 'package:family_hub/shared/widgets/error_view.dart';
import 'package:family_hub/shared/widgets/money_text.dart';
import 'package:family_hub/shared/widgets/section_header.dart';
import 'package:family_hub/shared/widgets/status_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'shared_widgets_test_support.dart';

/// The Step 11 promise: at 200% text scale — the setting an older reader uses —
/// nothing in the shared widgets overflows, in either language, in either theme.
///
/// Every state of every widget is rendered at a 320dp width.  A `RenderFlex`
/// overflow is reported as an exception, so `takeException()` is the assertion.
void main() {
  setUpAll(loadBundledFonts);

  for (final section in gallerySections()) {
    for (final spec in appThemes) {
      for (final locale in sharedWidgetLocales) {
        testWidgets(
          '${section.id} fits at 200% — ${spec.id} / ${locale.languageCode}',
          (tester) async {
            await pumpSharedWidget(
              tester,
              child: Builder(builder: section.build),
              spec: spec,
              locale: locale,
              textScale: 2,
            );

            expect(
              tester.takeException(),
              isNull,
              reason: '${section.id} overflowed at 200% text scale',
            );
          },
        );
      }
    }
  }

  group('long copy at 200% text scale', () {
    // Realistic worst case: a long Bangla sentence where a short label normally
    // goes, in a widget that lays text out in a Row.
    const longBangla =
        'পরিবারের সব সদস্যের জন্য এই মাসের বাজারের সম্পূর্ণ তালিকা';

    testWidgets('status chip wraps, section header and error message fit', (
      tester,
    ) async {
      final l10n = await AppLocalizations.delegate.load(const Locale('bn'));

      await pumpSharedWidget(
        tester,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const StatusChip(status: WidgetStatus.scheduled, label: longBangla),
            SectionHeader(
              title: longBangla,
              seeAllLabel: l10n.commonSeeAll,
              onSeeAll: () {},
            ),
            ErrorView(message: longBangla, onRetry: () {}),
            const MoneyText(value: Money.paisa(123456789)),
          ],
        ),
        spec: defaultLightSpec,
        locale: const Locale('bn'),
        textScale: 2,
      );

      expect(tester.takeException(), isNull);
    });
  });
}
