/// One document a [FamilySeeder] wants written with a new family (H12).
class SeedWrite {
  const SeedWrite(this.path, this.data);

  /// Full document path, e.g. `families/{id}/bazarCategories/cat_vegetables`.
  final String path;
  final Map<String, dynamic> data;
}

/// What a seeder may know about the family being created.
class SeedContext {
  const SeedContext({
    required this.familyId,
    required this.actorUid,
    required this.now,
  });

  final String familyId;
  final String actorUid;
  final DateTime now;
}

/// Adds starter data to a new family in the SAME batch as the family itself
/// (H12).  Phase 2's `SeedDefaultCatalog` and the chore templates plug in here,
/// so `CreateFamily` never changes again.
///
/// Pure Dart on purpose: a seeder returns plain [SeedWrite]s and the repository
/// stages them, so the domain stays free of Firebase.  Use deterministic ids so a
/// retried create is idempotent.  One Firestore batch holds at most 500 writes
/// (`kMaxBatchWrites`), including the family's own documents.
abstract interface class FamilySeeder {
  List<SeedWrite> seed(SeedContext context);
}
