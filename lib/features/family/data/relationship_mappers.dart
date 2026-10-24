import 'package:family_hub/core/firebase/base_mapper.dart';
import 'package:family_hub/features/family/domain/relationship_catalog.dart';

/// `settings/relationships` <-> [RelationshipCatalog] (H10).  Pure functions, no
/// Firestore instance, so they are unit-testable.
abstract final class RelationshipMappers {
  /// `settings/relationships` (H10): the family's editable relationship list.
  static Map<String, dynamic> relationshipsMap(
    RelationshipCatalog catalog,
    BaseDocumentMetadata m,
  ) => <String, dynamic>{
    'items': _relationshipItems(catalog),
    ...BaseMapper.metadataToMap(m),
  };

  /// Fields changed when an admin edits the relationship list.
  static Map<String, dynamic> relationshipsChangeMap(
    RelationshipCatalog catalog, {
    required String actorUid,
    required DateTime now,
  }) => <String, dynamic>{
    'items': _relationshipItems(catalog),
    BaseMapper.keyUpdatedAt: BaseMapper.dateTimeToTimestamp(now),
    BaseMapper.keyUpdatedBy: actorUid,
  };

  static List<Map<String, dynamic>> _relationshipItems(
    RelationshipCatalog catalog,
  ) => <Map<String, dynamic>>[
    for (final e in catalog.entries)
      <String, dynamic>{
        'id': e.id.value,
        'labelBn': e.labelBn,
        'labelEn': e.labelEn,
        'spouseRelevant': e.spouseRelevant,
        'builtIn': e.builtIn,
        'active': e.active,
      },
  ];

  /// A missing document or list means the built-in defaults.  Ill-formed items
  /// are skipped, duplicate ids keep the first one, and the ten built-ins are
  /// always restored with their own labels, so a damaged document can never
  /// remove "Other" or rename a built-in.
  static RelationshipCatalog relationshipsFromMap(Map<String, dynamic>? d) {
    final raw = d?['items'];
    if (raw is! List) return RelationshipCatalog.defaults;
    final builtIns = <RelationshipId, RelationshipEntry>{
      for (final b in RelationshipCatalog.defaults.entries) b.id: b,
    };
    final seen = <RelationshipId>{};
    final entries = <RelationshipEntry>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final idText = item['id'];
      if (idText is! String || !RelationshipId.isValid(idText)) continue;
      final id = RelationshipId(idText);
      if (!seen.add(id)) continue;
      final builtIn = builtIns[id];
      if (builtIn != null) {
        entries.add(builtIn);
        continue;
      }
      final bn = item['labelBn'];
      final en = item['labelEn'];
      entries.add(
        RelationshipEntry(
          id: id,
          labelBn: bn is String ? bn : '',
          labelEn: en is String ? en : '',
          spouseRelevant: item['spouseRelevant'] == true,
          active: item['active'] != false,
        ),
      );
    }
    return RelationshipCatalog(entries).withBuiltIns();
  }
}
