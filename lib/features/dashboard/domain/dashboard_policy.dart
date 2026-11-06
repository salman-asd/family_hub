import 'package:family_hub/core/permissions/role.dart';
import 'package:family_hub/features/dashboard/domain/card_access.dart';
import 'package:family_hub/features/dashboard/domain/card_catalog.dart';
import 'package:family_hub/features/dashboard/domain/dashboard_defaults.dart';

final class DashboardPolicy {
  DashboardPolicy({
    Map<Role, Map<String, CardAccess>> roles =
        const <Role, Map<String, CardAccess>>{},
    this.version = 1,
  }) : roles = Map<Role, Map<String, CardAccess>>.unmodifiable(
         <Role, Map<String, CardAccess>>{
           for (final entry in roles.entries)
             if (entry.key != Role.admin)
               entry.key: Map<String, CardAccess>.unmodifiable(entry.value),
         },
       );

  static final DashboardPolicy defaults = DashboardPolicy();

  final Map<Role, Map<String, CardAccess>> roles;
  final int version;

  DashboardPolicy copyWith({
    Map<Role, Map<String, CardAccess>>? roles,
    int? version,
  }) => DashboardPolicy(
    roles: roles ?? this.roles,
    version: version ?? this.version,
  );

  CardAccess accessFor(Role role, String cardId) {
    if (role == Role.admin) return CardAccess.on;
    if (CardCatalog.find(cardId) == null) return CardAccess.hidden;
    return roles[role]?[cardId] ?? DashboardDefaults.accessFor(role, cardId);
  }

  @override
  bool operator ==(Object other) {
    if (other is! DashboardPolicy ||
        other.version != version ||
        other.roles.length != roles.length) {
      return false;
    }
    for (final entry in roles.entries) {
      final otherRole = other.roles[entry.key];
      if (otherRole == null || otherRole.length != entry.value.length) {
        return false;
      }
      for (final cell in entry.value.entries) {
        if (otherRole[cell.key] != cell.value) return false;
      }
    }
    return true;
  }

  @override
  int get hashCode {
    final sortedRoles = roles.keys.toList()
      ..sort((first, second) => first.index.compareTo(second.index));
    return Object.hash(
      version,
      Object.hashAll(
        sortedRoles.map((role) {
          final cells = roles[role]!;
          final sortedIds = cells.keys.toList()..sort();
          return Object.hash(
            role,
            Object.hashAll(sortedIds.map((id) => Object.hash(id, cells[id]))),
          );
        }),
      ),
    );
  }
}
