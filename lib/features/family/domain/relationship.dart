import 'package:family_hub/features/family/domain/relationship_catalog.dart';

export 'package:family_hub/features/family/domain/relationship_catalog.dart';

/// The ten built-in relationships of roadmap 2.3.
///
/// Since H10 the family's list is editable (`RelationshipCatalog`), and a
/// profile stores a [RelationshipId], not this enum.  The enum remains the typed
/// view of the built-ins (labels, defaults).
enum Relationship {
  father(canHaveSpouse: true),
  mother(canHaveSpouse: true),
  son(canHaveSpouse: true),
  daughter(canHaveSpouse: true),
  husband(canHaveSpouse: true),
  wife(canHaveSpouse: true),
  housewife(canHaveSpouse: true),
  daughterInLaw(canHaveSpouse: true),
  sonInLaw(canHaveSpouse: true),
  other(canHaveSpouse: false);

  const Relationship({required this.canHaveSpouse});

  /// Whether the spouse picker makes sense for this relationship.
  final bool canHaveSpouse;

  /// The stored id of this built-in.
  RelationshipId get id => RelationshipId(name);

  static Relationship parse(String? value) => Relationship.values.firstWhere(
        (r) => r.name == value,
        orElse: () => Relationship.other,
      );

  /// The built-in with [id], or `null` for a custom id.
  static Relationship? tryFromId(RelationshipId id) {
    for (final r in Relationship.values) {
      if (r.name == id.value) return r;
    }
    return null;
  }
}

/// Optional gender (never required).
enum Gender {
  male,
  female,
  other;

  static Gender? tryParse(String? value) {
    for (final g in Gender.values) {
      if (g.name == value) return g;
    }
    return null;
  }
}
