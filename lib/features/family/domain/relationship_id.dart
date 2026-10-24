/// The id of a relationship (H10): a lowercase-initial identifier such as
/// `father` or `uncleMaternal`.  It is what is stored in Firestore; labels come
/// from the family's [RelationshipCatalog].
///
/// Ids match `^[a-z][a-zA-Z0-9_]{1,30}$` (the same pattern the rules check).  An
/// unknown or malformed id reads as [other], so a record never fails to load.
class RelationshipId {
  const RelationshipId(this.value);

  static const RelationshipId father = RelationshipId('father');
  static const RelationshipId mother = RelationshipId('mother');
  static const RelationshipId son = RelationshipId('son');
  static const RelationshipId daughter = RelationshipId('daughter');
  static const RelationshipId husband = RelationshipId('husband');
  static const RelationshipId wife = RelationshipId('wife');
  static const RelationshipId housewife = RelationshipId('housewife');
  static const RelationshipId daughterInLaw = RelationshipId('daughterInLaw');
  static const RelationshipId sonInLaw = RelationshipId('sonInLaw');
  static const RelationshipId other = RelationshipId('other');

  static final RegExp _pattern = RegExp(r'^[a-z][a-zA-Z0-9_]{1,30}$');

  final String value;

  /// True when [candidate] is a well-formed id.
  static bool isValid(String? candidate) =>
      candidate != null && _pattern.hasMatch(candidate);

  /// A stored value to an id; anything malformed becomes [other].
  static RelationshipId parse(String? stored) =>
      isValid(stored) ? RelationshipId(stored!) : other;

  @override
  bool operator ==(Object other) =>
      other is RelationshipId && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'RelationshipId($value)';
}
