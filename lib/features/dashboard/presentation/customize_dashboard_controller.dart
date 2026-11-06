import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/features/dashboard/domain/card_access.dart';
import 'package:family_hub/features/dashboard/domain/dashboard_prefs.dart';
import 'package:family_hub/features/dashboard/domain/dashboard_prefs_order.dart';
import 'package:family_hub/features/dashboard/presentation/dashboard_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final customizeDashboardControllerProvider =
    Provider<CustomizeDashboardController>(
      (ref) => CustomizeDashboardController(ref),
    );

final class CustomizeDashboardController {
  const CustomizeDashboardController(this._ref);

  final Ref _ref;

  DashboardPrefs reorder(
    DashboardPrefs prefs,
    List<String> visibleIds,
    int oldIndex,
    int newIndex,
  ) => DashboardPrefsOrder.reorder(prefs, visibleIds, oldIndex, newIndex);

  DashboardPrefs move(
    DashboardPrefs prefs,
    List<String> visibleIds,
    int index,
    int offset,
  ) => DashboardPrefsOrder.move(prefs, visibleIds, index, offset);

  DashboardPrefs setVisibility(
    DashboardPrefs prefs,
    String cardId,
    bool visible,
    CardAccess access,
  ) => prefs.setVisible(cardId, visible, access: access);

  Future<Result<void>> save(DashboardPrefs prefs) {
    return _ref.read(dashboardPrefsProvider.notifier).save(prefs);
  }
}
