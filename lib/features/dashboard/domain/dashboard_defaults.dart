import 'package:family_hub/core/permissions/role.dart';
import 'package:family_hub/features/dashboard/domain/card_access.dart';
import 'package:family_hub/features/dashboard/domain/card_catalog.dart';

abstract final class DashboardDefaults {
  static CardAccess accessFor(Role role, String cardId) {
    if (role == Role.admin) return CardAccess.on;
    if (CardCatalog.find(cardId) == null) return CardAccess.hidden;
    if (role == Role.moderator) return CardAccess.on;

    return switch (cardId) {
      'budget_alert' || 'chores_week' || 'recent_activity' => CardAccess.off,
      'approvals' || 'chores_verify' => CardAccess.hidden,
      'chores_today' => CardAccess.required,
      _ => CardAccess.on,
    };
  }
}
