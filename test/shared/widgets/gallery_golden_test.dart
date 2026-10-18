import 'dart:io';

import 'package:family_hub/app/gallery/gallery_sections.dart';
import 'package:family_hub/app/theme/theme_registry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'shared_widgets_test_support.dart';

/// Golden tests for every shared widget, in every state, in both registered
/// themes and both shipped languages (roadmap Step 11).
///
/// The sections come from [gallerySections] — the same list `/dev/gallery`
/// renders — so the images cover exactly what the screen shows, and a widget
/// added there is golden-tested with no change here.
///
/// Regenerate deliberately, on the platform CI uses, with:
///
///   flutter test --update-goldens test/shared/widgets
///
/// and review the image diff before committing.  (Goldens rendered on Windows
/// can differ from Linux by a pixel and fail in CI.)
void main() {
  setUpAll(loadBundledFonts);

  // Until the images exist the tests are *skipped* with a reason rather than
  // failed, so a fresh clone has a green suite; `--update-goldens` still writes
  // them, because the check passes while that flag is set.
  final generated = autoUpdateGoldenFiles || _goldenDirectory.existsSync();

  group(
    'every widget, in every theme and language',
    () {
      for (final section in gallerySections()) {
        for (final spec in appThemes) {
          for (final locale in sharedWidgetLocales) {
            testWidgets(
              '${section.id} golden — ${spec.id} / ${locale.languageCode}',
              (tester) async {
                await pumpSharedWidget(
                  tester,
                  child: Builder(builder: section.build),
                  spec: spec,
                  locale: locale,
                );

                await expectLater(
                  find.byKey(sharedWidgetGoldenKey),
                  matchesGoldenFile(
                    'goldens/${section.id}_${spec.id}'
                    '_${locale.languageCode}.png',
                  ),
                );
              },
            );
          }
        }
      }
    },
    skip: generated
        ? null
        : 'goldens not generated yet — run '
            '`flutter test --update-goldens test/shared/widgets`',
  );
}

/// Where [matchesGoldenFile] looks, relative to this file.
final Directory _goldenDirectory = Directory('test/shared/widgets/goldens');
