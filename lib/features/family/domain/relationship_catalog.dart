import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/features/family/domain/relationship_defaults.dart';
import 'package:family_hub/features/family/domain/relationship_entry.dart';
import 'package:family_hub/features/family/domain/relationship_id.dart';

export 'package:family_hub/features/family/domain/relationship_entry.dart';
export 'package:family_hub/features/family/domain/relationship_id.dart';

/// The family's editable list of relationships (`settings/relationships`).
///
/// Pure Dart.  The ten built-in entries are always present; an admin adds,
/// renames and disables CUSTOM entries only.  Every operation returns a new
/// catalog or a `Validation` failure; nothing throws.
class RelationshipCatalog {
  const RelationshipCatalog(this.entries);

  /// Upper bound, mirrored by the rules (`items.size() <= 40`).
  static const int maxEntries = 40;
  static const int maxLabelLength = 40;

  /// The ten built-ins, in display order.
  static const RelationshipCatalog defaults = RelationshipCatalog(
    relationshipDefaults,
  );

  final List<RelationshipEntry> entries;

  /// Entries a member may pick today, in order.  A disabled entry stays in
  /// [entries] so existing members keep their label.
  List<RelationshipEntry> get selectable => <RelationshipEntry>[
    for (final e in entries)
      if (e.active) e,
  ];

  /// The entry for [id], or `null` when it is not in the catalog.
  RelationshipEntry? find(RelationshipId id) {
    for (final e in entries) {
      if (e.id == id) return e;
    }
    return null;
  }

  /// Label for [id] in [languageCode]; an unknown id renders as "Other".
  String labelOf(RelationshipId id, String languageCode) =>
      (find(id) ??
              find(RelationshipId.other) ??
              defaults.find(id) ??
              defaults.entries.last)
          .label(languageCode);

  /// Whether the spouse picker applies to [id].
  bool canHaveSpouse(RelationshipId id) => find(id)?.spouseRelevant ?? false;

  /// The built-ins always present: a stored list that lost one gets it back, so
  /// a damaged document can never remove "Other".
  RelationshipCatalog withBuiltIns() {
    final present = <RelationshipId>{for (final e in entries) e.id};
    return RelationshipCatalog(<RelationshipEntry>[
      for (final b in defaults.entries)
        if (!present.contains(b.id)) b,
      ...entries,
    ]);
  }

  /// Adds a custom entry.  [id] must be well formed and unused.
  Result<RelationshipCatalog> add({
    required String id,
    required String labelBn,
    required String labelEn,
    bool spouseRelevant = false,
  }) {
    if (!RelationshipId.isValid(id)) {
      return const Failure<RelationshipCatalog>(Validation('id', 'invalid'));
    }
    final bn = labelBn.trim();
    final en = labelEn.trim();
    final labelFailure = _checkLabels(bn, en);
    if (labelFailure != null) {
      return Failure<RelationshipCatalog>(labelFailure);
    }
    if (find(RelationshipId(id)) != null) {
      return const Failure<RelationshipCatalog>(Conflict(code: 'id_taken'));
    }
    if (entries.length >= maxEntries) {
      return const Failure<RelationshipCatalog>(
        Validation('entries', 'too_many'),
      );
    }
    return Success<RelationshipCatalog>(
      RelationshipCatalog(<RelationshipEntry>[
        ...entries,
        RelationshipEntry(
          id: RelationshipId(id),
          labelBn: bn,
          labelEn: en,
          spouseRelevant: spouseRelevant,
        ),
      ]),
    );
  }

  /// Renames a custom entry.  Built-ins cannot be renamed.
  Result<RelationshipCatalog> rename(
    RelationshipId id, {
    required String labelBn,
    required String labelEn,
    bool? spouseRelevant,
  }) {
    final current = find(id);
    if (current == null) {
      return const Failure<RelationshipCatalog>(
        NotFound(entity: 'relationship'),
      );
    }
    if (current.builtIn) {
      return const Failure<RelationshipCatalog>(Conflict(code: 'built_in'));
    }
    final bn = labelBn.trim();
    final en = labelEn.trim();
    final labelFailure = _checkLabels(bn, en);
    if (labelFailure != null) {
      return Failure<RelationshipCatalog>(labelFailure);
    }
    return Success<RelationshipCatalog>(
      _replace(
        current.copyWith(
          labelBn: bn,
          labelEn: en,
          spouseRelevant: spouseRelevant,
        ),
      ),
    );
  }

  /// Enables or disables a custom entry.  Built-ins stay enabled.
  Result<RelationshipCatalog> setActive(
    RelationshipId id, {
    required bool active,
  }) {
    final current = find(id);
    if (current == null) {
      return const Failure<RelationshipCatalog>(
        NotFound(entity: 'relationship'),
      );
    }
    if (current.builtIn) {
      return const Failure<RelationshipCatalog>(Conflict(code: 'built_in'));
    }
    return Success<RelationshipCatalog>(
      _replace(current.copyWith(active: active)),
    );
  }

  RelationshipCatalog _replace(RelationshipEntry next) => RelationshipCatalog(
    <RelationshipEntry>[for (final e in entries) e.id == next.id ? next : e],
  );

  static AppFailure? _checkLabels(String bn, String en) {
    if (bn.isEmpty && en.isEmpty) {
      return const Validation('label', 'required');
    }
    if (bn.length > maxLabelLength || en.length > maxLabelLength) {
      return const Validation('label', 'too_long');
    }
    return null;
  }

  @override
  bool operator ==(Object other) =>
      other is RelationshipCatalog && _listEquals(other.entries, entries);

  @override
  int get hashCode => Object.hashAll(entries);

  static bool _listEquals(
    List<RelationshipEntry> a,
    List<RelationshipEntry> b,
  ) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
