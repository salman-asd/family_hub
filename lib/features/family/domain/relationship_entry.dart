import 'package:family_hub/features/family/domain/relationship_id.dart';

/// One selectable relationship.
class RelationshipEntry {
  const RelationshipEntry({
    required this.id,
    required this.labelBn,
    required this.labelEn,
    this.spouseRelevant = false,
    this.builtIn = false,
    this.active = true,
  });

  final RelationshipId id;
  final String labelBn;
  final String labelEn;

  /// Whether the spouse picker makes sense for this relationship.
  final bool spouseRelevant;

  /// Built-in entries can be neither renamed nor disabled nor removed.
  final bool builtIn;
  final bool active;

  RelationshipEntry copyWith({
    String? labelBn,
    String? labelEn,
    bool? spouseRelevant,
    bool? active,
  }) => RelationshipEntry(
    id: id,
    labelBn: labelBn ?? this.labelBn,
    labelEn: labelEn ?? this.labelEn,
    spouseRelevant: spouseRelevant ?? this.spouseRelevant,
    builtIn: builtIn,
    active: active ?? this.active,
  );

  /// Label in [languageCode] (`bn` or `en`), falling back to the other one.
  String label(String languageCode) {
    final preferred = languageCode == 'bn' ? labelBn : labelEn;
    final fallback = languageCode == 'bn' ? labelEn : labelBn;
    return preferred.trim().isNotEmpty ? preferred : fallback;
  }

  @override
  bool operator ==(Object other) =>
      other is RelationshipEntry &&
      other.id == id &&
      other.labelBn == labelBn &&
      other.labelEn == labelEn &&
      other.spouseRelevant == spouseRelevant &&
      other.builtIn == builtIn &&
      other.active == active;

  @override
  int get hashCode =>
      Object.hash(id, labelBn, labelEn, spouseRelevant, builtIn, active);
}
