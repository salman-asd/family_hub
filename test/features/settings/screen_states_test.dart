import 'dart:async';

import 'package:family_hub/features/family/domain/relationship_catalog.dart';
import 'package:family_hub/features/family/presentation/family_providers.dart';
import 'package:family_hub/features/family/presentation/screens/relationships_screen.dart';
import 'package:family_hub/features/settings/presentation/language_settings_screen.dart';
import 'package:family_hub/features/settings/presentation/security_screen.dart';
import 'package:family_hub/features/settings/presentation/theme_settings_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_states.dart';

/// H11: state + accessibility harness applied to the screens that need no
/// Firebase.  Add a screen here as soon as it reads a stream.
void main() {
  screenStateTests('ThemeSettingsScreen', () => const ThemeSettingsScreen());
  screenStateTests('LanguageSettingsScreen', () => const LanguageSettingsScreen());
  screenStateTests('SecurityScreen', () => const SecurityScreen());

  screenStateTests(
    'RelationshipsScreen',
    () => const RelationshipsScreen(),
    states: {
      ScreenState.loading,
      ScreenState.data,
      ScreenState.empty,
      ScreenState.error,
    },
    overrides: (state) => [
      relationshipCatalogProvider.overrideWith(
        (ref) => switch (state) {
          ScreenState.loading => StreamController<RelationshipCatalog>().stream,
          ScreenState.error => Stream<RelationshipCatalog>.error('boom'),
          ScreenState.empty => Stream.value(RelationshipCatalog.defaults),
          ScreenState.data => Stream.value(
              RelationshipCatalog.defaults
                  .add(id: 'uncle', labelBn: 'চাচা', labelEn: 'Uncle')
                  .valueOrNull!,
            ),
        },
      ),
    ],
  );
}
