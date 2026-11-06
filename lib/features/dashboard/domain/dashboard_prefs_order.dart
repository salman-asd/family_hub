import 'package:family_hub/features/dashboard/domain/dashboard_prefs.dart';

abstract final class DashboardPrefsOrder {
  static DashboardPrefs reorder(
    DashboardPrefs prefs,
    List<String> visibleIds,
    int oldIndex,
    int newIndex,
  ) {
    if (oldIndex < 0 ||
        oldIndex >= visibleIds.length ||
        newIndex < 0 ||
        newIndex >= visibleIds.length) {
      return prefs;
    }
    final order = List<String>.of(visibleIds);
    final id = order.removeAt(oldIndex);
    order.insert(newIndex, id);
    final visible = order.toSet();
    return DashboardPrefs(
      order: <String>[
        ...order,
        ...prefs.order.where((cardId) => !visible.contains(cardId)),
      ],
      hidden: prefs.hidden,
      shown: prefs.shown,
    );
  }

  static DashboardPrefs move(
    DashboardPrefs prefs,
    List<String> visibleIds,
    int index,
    int offset,
  ) {
    final target = index + offset;
    if (index < 0 ||
        index >= visibleIds.length ||
        target < 0 ||
        target >= visibleIds.length) {
      return prefs;
    }
    return reorder(prefs, visibleIds, index, target);
  }
}
