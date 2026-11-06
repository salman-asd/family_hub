import 'package:family_hub/core/firebase/base_mapper.dart';
import 'package:family_hub/core/permissions/role.dart';
import 'package:family_hub/features/dashboard/domain/card_access.dart';
import 'package:family_hub/features/dashboard/domain/card_catalog.dart';
import 'package:family_hub/features/dashboard/domain/dashboard_defaults.dart';
import 'package:family_hub/features/dashboard/domain/dashboard_policy.dart';
import 'package:family_hub/features/dashboard/domain/dashboard_prefs.dart';

abstract final class DashboardPolicyMappers {
  static Map<String, dynamic> policyToMap(
    DashboardPolicy policy,
    BaseDocumentMetadata metadata,
  ) => <String, dynamic>{
    'roles': <String, dynamic>{
      for (final entry in policy.roles.entries)
        if (entry.key != Role.admin)
          entry.key.name: <String, String>{
            for (final cell in entry.value.entries)
              if (CardCatalog.find(cell.key) != null) cell.key: cell.value.name,
          },
    },
    'version': policy.version,
    ...BaseMapper.metadataToMap(metadata),
  };

  static DashboardPolicy policyFromMap(Map<String, dynamic>? data) {
    if (data == null) return DashboardPolicy.defaults;
    final rawRoles = data['roles'];
    final roles = <Role, Map<String, CardAccess>>{};
    if (rawRoles is Map) {
      for (final entry in rawRoles.entries) {
        final role = Role.values.where(
          (candidate) => candidate != Role.admin && candidate.name == entry.key,
        );
        if (role.isEmpty || entry.value is! Map) continue;

        final cells = <String, CardAccess>{};
        for (final cell in (entry.value as Map).entries) {
          final cardId = cell.key;
          if (cardId is! String || CardCatalog.find(cardId) == null) continue;
          cells[cardId] = CardAccess.parse(
            cell.value is String ? cell.value as String : null,
            fallback: DashboardDefaults.accessFor(role.single, cardId),
          );
        }
        roles[role.single] = cells;
      }
    }

    final version = data['version'];
    return DashboardPolicy(
      roles: roles,
      version: version is int && version > 0 ? version : 1,
    );
  }

  static Map<String, dynamic> dashboardPrefsToMap(DashboardPrefs prefs) =>
      <String, dynamic>{
        'order': _knownIds(prefs.order),
        'hidden': _knownIds(prefs.hidden),
        'shown': _knownIds(prefs.shown),
      };

  static DashboardPrefs dashboardPrefsFromMap(Map<String, dynamic>? data) {
    if (data == null) return DashboardPrefs.defaults;
    return DashboardPrefs(
      order: _readList(data['order']),
      hidden: _readList(data['hidden']).toSet(),
      shown: _readList(data['shown']).toSet(),
    );
  }

  static List<String> _readList(Object? value) {
    if (value is! List) return const <String>[];
    final output = <String>[];
    final seen = <String>{};
    for (final entry in value) {
      if (entry is! String ||
          entry.length > DashboardPrefs.maxIdLength ||
          CardCatalog.find(entry) == null ||
          !seen.add(entry)) {
        continue;
      }
      output.add(entry);
      if (output.length == DashboardPrefs.maxPreferenceIds) break;
    }
    return output;
  }

  static List<String> _knownIds(Iterable<String> ids) {
    final output = <String>[];
    for (final id in ids) {
      if (id.length > DashboardPrefs.maxIdLength ||
          CardCatalog.find(id) == null) {
        continue;
      }
      output.add(id);
      if (output.length == DashboardPrefs.maxPreferenceIds) break;
    }
    return output;
  }
}
