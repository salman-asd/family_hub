/// Relationship of a member to the family (roadmap 2.3).
///
/// The list is a constant for now; making it admin-editable is a later change.
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

  static Relationship parse(String? value) => Relationship.values.firstWhere(
        (r) => r.name == value,
        orElse: () => Relationship.other,
      );
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
