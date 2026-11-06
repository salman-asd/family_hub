import 'package:family_hub/app/theme/theme_registry.dart';
import 'package:family_hub/core/permissions/permission_settings.dart';
import 'package:family_hub/features/dashboard/domain/dashboard_policy.dart';
import 'package:family_hub/features/dashboard/presentation/dashboard_policy_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../shared/widgets/shared_widgets_test_support.dart';

void main() {
  setUpAll(loadBundledFonts);

  testWidgets('permission-missing role is locked, and policy card fits', (
    tester,
  ) async {
    final settings = PermissionSettings.defaults.copyWith(
      choreVerificationEnabled: true,
    );
    for (final theme in appThemes) {
      for (final locale in sharedWidgetLocales) {
        await pumpSharedWidget(
          tester,
          child: DashboardPolicyCard(
            cardId: 'chores_verify',
            policy: DashboardPolicy.defaults,
            settings: settings,
            busy: false,
            onAccessChanged: (_, _, _) {},
          ),
          spec: theme,
          locale: locale,
          textScale: 2,
        );

        final chips = tester.widgetList<ChoiceChip>(find.byType(ChoiceChip));
        expect(chips.length, 8);
        expect(chips.where((chip) => chip.onSelected == null).length, 4);
        expect(tester.takeException(), isNull);
      }
    }
  });
}
